import '../../core/exceptions/api_exception.dart';
import 'vendas_repository.dart';
import '../crediario/crediario_service.dart';

class VendasService {
  final VendasRepository _repository;
  final CrediarioService? _crediarioService;

  VendasService(this._repository, {CrediarioService? crediarioService})
      : _crediarioService = crediarioService;

  Future<Map<String, dynamic>> listar(Map<String, dynamic> params) async {
    final tipo = params['tipo'] as String?;
    final status = params['status'] as String?;
    final clienteId = params['cliente_id'] as int?;
    final usuarioId = params['usuario_id'] as int?;
    final dataInicio = params['data_inicio'] as String?;
    final dataFim = params['data_fim'] as String?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final vendas = await _repository.findAll(
      tipo: tipo,
      status: status,
      clienteId: clienteId,
      usuarioId: usuarioId,
      dataInicio: dataInicio,
      dataFim: dataFim,
      limit: limit,
      offset: offset,
    );

    final total = await _repository.count(
      tipo: tipo,
      status: status,
      clienteId: clienteId,
      usuarioId: usuarioId,
    );

    return {
      'items': vendas.map((v) => v.toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> obterPorId(int id) async {
    final venda = await _repository.findById(id);
    if (venda == null) {
      throw NotFoundException('Venda não encontrada');
    }

    final itens = await _repository.findItensByVendaId(id);
    final vendaJson = venda.toJson();
    vendaJson['itens'] = itens.map((i) => i.toJson()).toList();

    // Incluir pagamentos da tabela venda_pagamentos
    final pagamentosRows = await _repository.findPagamentosByVendaId(id);
    vendaJson['pagamentos'] = pagamentosRows
        .map((r) => {
              'id': int.tryParse(r['id'] ?? ''),
              'forma_pagamento': r['forma_pagamento'],
              'valor': double.tryParse(r['valor'] ?? '0') ?? 0,
            })
        .toList();

    return vendaJson;
  }

  Future<Map<String, dynamic>> criarVenda(
    Map<String, dynamic> data,
    int usuarioId,
  ) async {
    // Validações
    final itens = data['itens'] as List<dynamic>?;
    if (itens == null || itens.isEmpty) {
      throw ValidationException('A venda deve ter pelo menos um item');
    }

    final tipo = (data['tipo'] as String?) ?? 'Venda';
    if (tipo != 'Venda' && tipo != 'Orcamento') {
      throw ValidationException('Tipo deve ser "Venda" ou "Orcamento"');
    }

    // Montar lista de pagamentos (suporte a split/combinado)
    var pagamentosList = <Map<String, dynamic>>[];
    final pagamentosRaw = data['pagamentos'] as List<dynamic>?;
    final formaPagamentoLegado = data['forma_pagamento'] as String?;

    if (pagamentosRaw != null && pagamentosRaw.isNotEmpty) {
      // Novo formato: lista de pagamentos
      for (final p in pagamentosRaw) {
        final pMap = p as Map<String, dynamic>;
        final forma = pMap['forma_pagamento'] as String?;
        final valor = _parseDouble(pMap['valor']);
        if (forma == null || forma.isEmpty) {
          throw ValidationException(
              'forma_pagamento é obrigatório em cada pagamento');
        }
        if (valor == null || valor <= 0) {
          throw ValidationException(
              'valor deve ser positivo em cada pagamento');
        }
        pagamentosList.add({'forma_pagamento': forma, 'valor': valor});
      }
    } else if (formaPagamentoLegado != null &&
        formaPagamentoLegado.isNotEmpty) {
      // Formato legado: forma_pagamento único
      pagamentosList.add({'forma_pagamento': formaPagamentoLegado});
    }

    if (tipo == 'Venda' && pagamentosList.isEmpty) {
      throw ValidationException(
          'Forma de pagamento é obrigatória para vendas');
    }

    // Verificar se crediário está combinado (não permitido)
    final formasPagamento =
        pagamentosList.map((p) => p['forma_pagamento'] as String).toList();
    final formaPagamentoResumo = formasPagamento.join('+');
    final temCrediario = formasPagamento.contains('crediario');

    if (temCrediario && pagamentosList.length > 1) {
      throw ValidationException(
          'Crediário não pode ser combinado com outras formas de pagamento');
    }

    // Validações específicas para crediário
    if (temCrediario) {
      if (data['cliente_id'] == null) {
        throw ValidationException(
            'Cliente é obrigatório para venda no crediário');
      }
      final numeroParcelas = _parseInt(data['crediario_parcelas']) ?? 0;
      if (numeroParcelas < 1 || numeroParcelas > 12) {
        throw ValidationException(
            'Número de parcelas deve ser entre 1 e 12');
      }
      if (_crediarioService == null) {
        throw ValidationException('Serviço de crediário não disponível');
      }
    }

    // Calcular totais
    double subtotal = 0;
    final itensProcessados = <Map<String, dynamic>>[];

    for (final item in itens) {
      final itemMap = item as Map<String, dynamic>;
      final produtoId = itemMap['produto_id'];
      final servicoId = itemMap['servico_id'];

      if (produtoId == null && servicoId == null) {
        throw ValidationException(
            'produto_id ou servico_id é obrigatório em cada item');
      }

      final quantidade = _parseDouble(itemMap['quantidade']) ?? 1;
      if (quantidade <= 0) {
        throw ValidationException('Quantidade deve ser positiva');
      }

      double precoUnitario;
      final descontoItem = _parseDouble(itemMap['desconto']) ?? 0;

      if (produtoId != null) {
        // Item de produto
        final produtoIdInt =
            produtoId is int ? produtoId : int.tryParse(produtoId.toString());
        if (produtoIdInt == null) {
          throw ValidationException('produto_id inválido');
        }

        final produto = await _repository.getProduto(produtoIdInt);
        if (produto == null) {
          throw NotFoundException('Produto $produtoIdInt não encontrado');
        }
        if (produto['ativo'] != '1') {
          throw ValidationException(
              'Produto "${produto['descricao']}" está inativo');
        }
        if (produto['bloqueado'] == '1') {
          throw ValidationException(
              'Produto "${produto['descricao']}" está bloqueado');
        }

        precoUnitario = _parseDouble(itemMap['preco_unitario']) ??
            double.parse(produto['preco_venda'] ?? '0');

        // Verificar estoque (para vendas, não para orçamentos)
        if (tipo == 'Venda') {
          final estoqueAtual = int.parse(produto['estoque_atual'] ?? '0');
          if (estoqueAtual < quantidade.toInt()) {
            throw ValidationException(
              'Estoque insuficiente para "${produto['descricao']}". '
              'Disponível: $estoqueAtual',
            );
          }
        }

        final totalItem = (quantidade * precoUnitario) - descontoItem;
        itensProcessados.add({
          'produto_id': produtoIdInt,
          'quantidade': quantidade,
          'preco_unitario': precoUnitario,
          'desconto': descontoItem,
          'total': totalItem,
        });
        subtotal += totalItem;
      } else {
        // Item de serviço
        final servicoIdInt =
            servicoId is int ? servicoId : int.tryParse(servicoId.toString());
        if (servicoIdInt == null) {
          throw ValidationException('servico_id inválido');
        }

        final servico = await _repository.getServico(servicoIdInt);
        if (servico == null) {
          throw NotFoundException('Serviço $servicoIdInt não encontrado');
        }
        if (servico['ativo'] != '1') {
          throw ValidationException(
              'Serviço "${servico['descricao']}" está inativo');
        }

        precoUnitario = _parseDouble(itemMap['preco_unitario']) ??
            double.parse(servico['preco'] ?? '0');

        final totalItem = (quantidade * precoUnitario) - descontoItem;
        itensProcessados.add({
          'servico_id': servicoIdInt,
          'quantidade': quantidade,
          'preco_unitario': precoUnitario,
          'desconto': descontoItem,
          'total': totalItem,
        });
        subtotal += totalItem;
      }
    }

    // Calcular descontos da venda
    final descontoPercentual = _parseDouble(data['desconto_percentual']) ?? 0;
    final descontoValor = _parseDouble(data['desconto_valor']) ?? 0;
    final descontoTotal =
        descontoValor + (subtotal * descontoPercentual / 100);
    final totalVenda = subtotal - descontoTotal;

    // Validar pagamento
    if (tipo == 'Venda' && pagamentosList.isNotEmpty) {
      // Se pagamentos têm valores definidos, validar soma
      final temValoresDefinidos =
          pagamentosList.every((p) => p['valor'] != null);
      if (temValoresDefinidos) {
        final somaPagamentos = pagamentosList.fold<double>(
            0.0, (sum, p) => sum + (p['valor'] as double));
        final diferenca = (somaPagamentos - totalVenda).abs();
        if (diferenca > 0.01) {
          throw ValidationException(
            'Soma dos pagamentos (R\$ ${somaPagamentos.toStringAsFixed(2)}) '
            'difere do total (R\$ ${totalVenda.toStringAsFixed(2)})',
          );
        }
      } else {
        // Formato legado sem valor definido - atribuir total ao único pagamento
        pagamentosList[0]['valor'] = totalVenda;
      }

      // Validar dinheiro: valor recebido >= parte em dinheiro
      final valorRecebido = _parseDouble(data['valor_recebido']);
      final parteDinheiro = pagamentosList
          .where((p) => p['forma_pagamento'] == 'dinheiro')
          .fold<double>(0.0, (sum, p) => sum + (p['valor'] as double));
      if (parteDinheiro > 0 &&
          valorRecebido != null &&
          valorRecebido < parteDinheiro) {
        throw ValidationException(
          'Valor recebido (R\$ ${valorRecebido.toStringAsFixed(2)}) '
          'é inferior à parte em dinheiro (R\$ ${parteDinheiro.toStringAsFixed(2)})',
        );
      }
    }

    // Gerar número da venda
    final numero = await _repository.gerarNumero();

    // Criar a venda
    final valorRecebido = _parseDouble(data['valor_recebido']) ?? totalVenda;
    final parteDinheiro = pagamentosList
        .where((p) => p['forma_pagamento'] == 'dinheiro')
        .fold<double>(0.0, (sum, p) => sum + ((p['valor'] as double?) ?? 0));
    final troco = parteDinheiro > 0 && valorRecebido > parteDinheiro
        ? valorRecebido - parteDinheiro
        : 0.0;

    final vendaData = <String, String>{
      'numero': numero,
      'tipo': tipo,
      'usuario_id': usuarioId.toString(),
      'total_itens': itensProcessados.length.toString(),
      'subtotal': subtotal.toStringAsFixed(2),
      'desconto_percentual': descontoPercentual.toStringAsFixed(2),
      'desconto_valor': descontoTotal.toStringAsFixed(2),
      'total': totalVenda.toStringAsFixed(2),
      'status': tipo == 'Venda' ? 'finalizada' : 'orcamento',
    };

    if (pagamentosList.isNotEmpty) {
      vendaData['forma_pagamento'] = formaPagamentoResumo;
    }
    vendaData['valor_recebido'] = valorRecebido.toStringAsFixed(2);
    vendaData['troco'] = troco.toStringAsFixed(2);

    if (data['cliente_id'] != null) {
      vendaData['cliente_id'] = data['cliente_id'].toString();
    }
    if (data['vendedor_id'] != null) {
      vendaData['vendedor_id'] = data['vendedor_id'].toString();
    }
    if (data['observacoes'] != null) {
      vendaData['observacoes'] = data['observacoes'].toString();
    }

    final vendaId = await _repository.create(vendaData);

    // Criar itens da venda
    for (final item in itensProcessados) {
      final itemData = <String, String>{
        'venda_id': vendaId.toString(),
        'quantidade': (item['quantidade'] as double).toString(),
        'preco_unitario': (item['preco_unitario'] as double).toStringAsFixed(2),
        'desconto': (item['desconto'] as double).toStringAsFixed(2),
        'total': (item['total'] as double).toStringAsFixed(2),
      };

      if (item['produto_id'] != null) {
        itemData['produto_id'] = item['produto_id'].toString();
      }
      if (item['servico_id'] != null) {
        itemData['servico_id'] = item['servico_id'].toString();
      }

      await _repository.createItem(itemData);

      // Baixar estoque (apenas para vendas de produtos)
      if (tipo == 'Venda' && item['produto_id'] != null) {
        final qtd = (item['quantidade'] as double).toInt();
        await _repository.atualizarEstoque(
          item['produto_id'] as int,
          qtd,
        );

        // Registrar histórico de estoque
        await _repository.registrarHistoricoEstoque({
          'produto_id': item['produto_id'].toString(),
          'tipo': 'saida',
          'ocorrencia': 'venda',
          'quantidade': qtd.toString(),
          'referencia_id': vendaId.toString(),
          'referencia_tipo': 'venda',
          'usuario_id': usuarioId.toString(),
        });
      }
    }

    // Registrar pagamentos na tabela venda_pagamentos
    if (tipo == 'Venda') {
      for (final pag in pagamentosList) {
        await _repository.createPagamento({
          'venda_id': vendaId.toString(),
          'forma_pagamento': pag['forma_pagamento'] as String,
          'valor': (pag['valor'] as double).toStringAsFixed(2),
        });
      }
    }

    // Registrar movimento no caixa (apenas para vendas)
    if (tipo == 'Venda') {
      await _repository.registrarMovimentoCaixa({
        'caixa_id': '1',
        'descricao': 'Venda #$numero',
        'valor': totalVenda.toStringAsFixed(2),
        'tipo': 'entrada',
        'categoria': 'venda',
        'referencia_id': vendaId.toString(),
        'referencia_tipo': 'venda',
        'usuario_id': usuarioId.toString(),
      });

      await _repository.atualizarSaldoCaixa(1, totalVenda);
    }

    // Gerar parcelas do crediário
    if (tipo == 'Venda' && temCrediario) {
      final clienteId = _parseInt(data['cliente_id'])!;
      final numeroParcelas = _parseInt(data['crediario_parcelas'])!;
      await _crediarioService!.gerarParcelas(
        vendaId: vendaId,
        clienteId: clienteId,
        totalVenda: totalVenda,
        numeroParcelas: numeroParcelas,
      );
    }

    return await obterPorId(vendaId);
  }

  Future<void> cancelar(int id, int usuarioId) async {
    final venda = await _repository.findById(id);
    if (venda == null) {
      throw NotFoundException('Venda não encontrada');
    }
    if (venda.status == 'cancelada') {
      throw ValidationException('Venda já está cancelada');
    }

    // Reverter estoque se era venda finalizada
    if (venda.status == 'finalizada') {
      final itens = await _repository.findItensByVendaId(id);
      for (final item in itens) {
        if (item.produtoId != null) {
          // Devolver ao estoque (negativo = soma)
          await _repository.atualizarEstoque(
            item.produtoId!,
            -(item.quantidade.toInt()),
          );

          await _repository.registrarHistoricoEstoque({
            'produto_id': item.produtoId.toString(),
            'tipo': 'entrada',
            'ocorrencia': 'cancelamento_venda',
            'quantidade': item.quantidade.toInt().toString(),
            'referencia_id': id.toString(),
            'referencia_tipo': 'cancelamento_venda',
            'usuario_id': usuarioId.toString(),
          });
        }
      }

      // Reverter movimento no caixa
      await _repository.registrarMovimentoCaixa({
        'caixa_id': '1',
        'descricao': 'Cancelamento Venda #${venda.numero}',
        'valor': venda.total.toStringAsFixed(2),
        'tipo': 'saida',
        'categoria': 'cancelamento_venda',
        'referencia_id': id.toString(),
        'referencia_tipo': 'cancelamento_venda',
        'usuario_id': usuarioId.toString(),
      });

      await _repository.atualizarSaldoCaixa(1, -venda.total);
    }

    await _repository.updateStatus(id, 'cancelada');

    // Cancelar parcelas do crediário se houver
    if (_crediarioService != null) {
      await _crediarioService?.cancelarParcelasVenda(id);
    }
  }

  Future<Map<String, dynamic>> converterOrcamento(
    int id,
    Map<String, dynamic> data,
    int usuarioId,
  ) async {
    final venda = await _repository.findById(id);
    if (venda == null) {
      throw NotFoundException('Orçamento não encontrado');
    }
    if (venda.tipo != 'Orcamento' || venda.status != 'orcamento') {
      throw ValidationException(
          'Apenas orçamentos pendentes podem ser convertidos');
    }

    // Buscar itens do orçamento para criar nova venda
    final itens = await _repository.findItensByVendaId(id);
    final itensData = itens
        .map((i) => {
              if (i.produtoId != null) 'produto_id': i.produtoId,
              if (i.servicoId != null) 'servico_id': i.servicoId,
              'quantidade': i.quantidade,
              'preco_unitario': i.precoUnitario,
              'desconto': i.desconto,
            })
        .toList();

    // Cancelar o orçamento
    await _repository.updateStatus(id, 'cancelada');

    // Criar a venda a partir dos itens do orçamento
    final vendaData = <String, dynamic>{
      'tipo': 'Venda',
      'forma_pagamento': data['forma_pagamento'] ?? 'dinheiro',
      'valor_recebido': data['valor_recebido'],
      'itens': itensData,
    };

    if (venda.clienteId != null) {
      vendaData['cliente_id'] = venda.clienteId;
    }
    if (data['vendedor_id'] != null) {
      vendaData['vendedor_id'] = data['vendedor_id'];
    }
    if (data['desconto_percentual'] != null) {
      vendaData['desconto_percentual'] = data['desconto_percentual'];
    }
    if (data['desconto_valor'] != null) {
      vendaData['desconto_valor'] = data['desconto_valor'];
    }

    return await criarVenda(vendaData, usuarioId);
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
