import '../../config/database.dart';
import '../../core/exceptions/api_exception.dart';
import 'consignacoes_repository.dart';

class ConsignacoesService {
  final ConsignacoesRepository _repository;

  ConsignacoesService(this._repository);

  Future<Map<String, dynamic>> listar(Map<String, dynamic> params) async {
    final tipo = params['tipo'] as String?;
    final status = params['status'] as String?;
    final clienteId = params['cliente_id'] as int?;
    final fornecedorId = params['fornecedor_id'] as int?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final items = await _repository.findAll(
      tipo: tipo,
      status: status,
      clienteId: clienteId,
      fornecedorId: fornecedorId,
      limit: limit,
      offset: offset,
    );

    final total = await _repository.count(
      tipo: tipo,
      status: status,
      clienteId: clienteId,
      fornecedorId: fornecedorId,
    );

    return {
      'items': items.map((c) => c.toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> obterPorId(int id) async {
    final consignacao = await _repository.findById(id);
    if (consignacao == null) {
      throw NotFoundException('Consignação não encontrada');
    }

    final itens = await _repository.findItensByConsignacaoId(id);
    final acertos = await _repository.findAcertosByConsignacaoId(id);

    final acertosJson = <Map<String, dynamic>>[];
    for (final acerto in acertos) {
      final acertoItens =
          await _repository.findAcertoItensByAcertoId(acerto.id!);
      final json = acerto.toJson();
      json['itens'] = acertoItens.map((ai) => ai.toJson()).toList();
      acertosJson.add(json);
    }

    final json = consignacao.toJson();
    json['itens'] = itens.map((i) => i.toJson()).toList();
    json['acertos'] = acertosJson;
    return json;
  }

  Future<Map<String, dynamic>> criar(
      Map<String, dynamic> data, int usuarioId) async {
    final tipo = data['tipo'] as String?;
    if (tipo == null || (tipo != 'saida' && tipo != 'entrada')) {
      throw ValidationException('Tipo deve ser "saida" ou "entrada"');
    }

    final clienteId = data['cliente_id'];
    final fornecedorId = data['fornecedor_id'];

    if (tipo == 'saida' && clienteId == null) {
      throw ValidationException(
          'Cliente é obrigatório para consignação de saída');
    }
    if (tipo == 'entrada' && fornecedorId == null) {
      throw ValidationException(
          'Fornecedor é obrigatório para consignação de entrada');
    }

    final itens = data['itens'];
    if (itens == null || itens is! List || itens.isEmpty) {
      throw ValidationException('Pelo menos um item é obrigatório');
    }

    // Validate items and check stock for saida
    final itensList =
        itens.map((e) => e as Map<String, dynamic>).toList();
    for (final item in itensList) {
      final produtoId = item['produto_id'];
      if (produtoId == null) {
        throw ValidationException('produto_id é obrigatório em cada item');
      }
      final qtd = _toDouble(item['quantidade']);
      if (qtd <= 0) {
        throw ValidationException('Quantidade deve ser maior que zero');
      }

      final produto = await _repository
          .getProduto(produtoId is int ? produtoId : int.parse(produtoId.toString()));
      if (produto == null) {
        throw NotFoundException('Produto $produtoId não encontrado');
      }
      if (produto['ativo'] != '1') {
        throw ValidationException(
            'Produto "${produto['descricao']}" está inativo');
      }
      if (produto['bloqueado'] == '1') {
        throw ValidationException(
            'Produto "${produto['descricao']}" está bloqueado');
      }

      if (tipo == 'saida') {
        final estoque = int.parse(produto['estoque_atual'] ?? '0');
        if (estoque < qtd.ceil()) {
          throw ValidationException(
              'Estoque insuficiente para "${produto['descricao']}": '
              'disponível $estoque, solicitado ${qtd.ceil()}');
        }
      }
    }

    // Generate number
    final numero = await _repository.gerarNumero();

    // Calculate totals
    double valorTotal = 0;
    for (final item in itensList) {
      final qtd = _toDouble(item['quantidade']);
      final preco = _toDouble(item['preco_unitario']);
      valorTotal += qtd * preco;
    }

    // Create consignacao
    final consigData = <String, String>{
      'numero': numero,
      'tipo': tipo,
      'usuario_id': usuarioId.toString(),
      'total_itens': itensList.length.toString(),
      'valor_total': valorTotal.toStringAsFixed(2),
    };
    if (clienteId != null) {
      consigData['cliente_id'] = clienteId.toString();
    }
    if (fornecedorId != null) {
      consigData['fornecedor_id'] = fornecedorId.toString();
    }
    if (data['observacoes'] != null) {
      consigData['observacoes'] = data['observacoes'].toString();
    }

    // Wrap in transaction to ensure atomicity
    return await Database.instance.transaction(() async {
      final consigId = await _repository.create(consigData);

      // Create items and update stock
      for (final item in itensList) {
        final produtoId = item['produto_id'] is int
            ? item['produto_id']
            : int.parse(item['produto_id'].toString());
        final qtd = _toDouble(item['quantidade']);
        final preco = _toDouble(item['preco_unitario']);

        await _repository.createItem({
          'consignacao_id': consigId.toString(),
          'produto_id': produtoId.toString(),
          'quantidade': qtd.toString(),
          'preco_unitario': preco.toStringAsFixed(2),
        });

        // Update stock
        final stockDelta = tipo == 'saida' ? -qtd.ceil() : qtd.ceil();
        await _repository.atualizarEstoque(produtoId, stockDelta);

        final ocorrencia =
            tipo == 'saida' ? 'consignacao_saida' : 'consignacao_entrada';
        await _repository.registrarHistoricoEstoque({
          'produto_id': produtoId.toString(),
          'tipo': tipo == 'saida' ? 'saida' : 'entrada',
          'ocorrencia': ocorrencia,
          'quantidade': qtd.toString(),
          'referencia_id': consigId.toString(),
          'referencia_tipo': 'consignacao',
          'usuario_id': usuarioId.toString(),
        });
      }

      return await obterPorId(consigId);
    });
  }

  Future<Map<String, dynamic>> registrarAcerto(
      int consignacaoId, Map<String, dynamic> data, int usuarioId) async {
    final consignacao = await _repository.findById(consignacaoId);
    if (consignacao == null) {
      throw NotFoundException('Consignação não encontrada');
    }
    if (consignacao.status != 'aberta' && consignacao.status != 'parcial') {
      throw ValidationException(
          'Consignação com status "${consignacao.status}" não permite acerto');
    }

    final itensAcerto = data['itens'];
    if (itensAcerto == null || itensAcerto is! List || itensAcerto.isEmpty) {
      throw ValidationException('Itens do acerto são obrigatórios');
    }

    final formaPagamento = data['forma_pagamento'] as String?;

    final itensList =
        itensAcerto.map((e) => e as Map<String, dynamic>).toList();

    // Validate all items first
    for (final item in itensList) {
      final itemId = item['consignacao_item_id'];
      if (itemId == null) {
        throw ValidationException(
            'consignacao_item_id é obrigatório em cada item');
      }

      final consigItem = await _repository.findItemById(
          itemId is int ? itemId : int.parse(itemId.toString()));
      if (consigItem == null) {
        throw NotFoundException('Item de consignação $itemId não encontrado');
      }
      if (consigItem.consignacaoId != consignacaoId) {
        throw ValidationException(
            'Item $itemId não pertence a esta consignação');
      }

      final vendida = _toDouble(item['quantidade_vendida']);
      final devolvida = _toDouble(item['quantidade_devolvida']);

      if (vendida < 0 || devolvida < 0) {
        throw ValidationException('Quantidades não podem ser negativas');
      }
      if (vendida + devolvida > consigItem.quantidadePendente + 0.001) {
        throw ValidationException(
            'Quantidade (vendida + devolvida) excede o pendente '
            'para "${consigItem.produtoDescricao}": '
            'pendente ${consigItem.quantidadePendente}, '
            'informado ${vendida + devolvida}');
      }
    }

    // Wrap in transaction to ensure atomicity
    return await Database.instance.transaction(() async {
      // Create acerto header
      double totalVendido = 0;
      final acertoId = await _repository.createAcerto({
        'consignacao_id': consignacaoId.toString(),
        'usuario_id': usuarioId.toString(),
        'valor_vendido': '0',
        if (formaPagamento != null) 'forma_pagamento': formaPagamento,
        if (data['observacoes'] != null)
          'observacoes': data['observacoes'].toString(),
      });

      // Process each item (reuse validated data, single fetch)
      for (final item in itensList) {
        final itemId = item['consignacao_item_id'] is int
            ? item['consignacao_item_id']
            : int.parse(item['consignacao_item_id'].toString());
        final vendida = _toDouble(item['quantidade_vendida']);
        final devolvida = _toDouble(item['quantidade_devolvida']);

        if (vendida == 0 && devolvida == 0) continue;

        final consigItem = await _repository.findItemById(itemId);
        final valorItem = vendida * consigItem!.precoUnitario;
        totalVendido += valorItem;

        // Create acerto item
        await _repository.createAcertoItem({
          'acerto_id': acertoId.toString(),
          'consignacao_item_id': itemId.toString(),
          'quantidade_vendida': vendida.toString(),
          'quantidade_devolvida': devolvida.toString(),
          'valor': valorItem.toStringAsFixed(2),
        });

        // Update item quantities
        await _repository.updateItemQuantidades(itemId, vendida, devolvida);

        // Handle stock for devolutions
        if (devolvida > 0) {
          final stockDelta = consignacao.tipo == 'saida'
              ? devolvida.ceil()   // saida: devolvido volta ao estoque
              : -devolvida.ceil(); // entrada: devolvido ao fornecedor sai do estoque

          await _repository.atualizarEstoque(
              consigItem.produtoId, stockDelta);

          await _repository.registrarHistoricoEstoque({
            'produto_id': consigItem.produtoId.toString(),
            'tipo': consignacao.tipo == 'saida' ? 'entrada' : 'saida',
            'ocorrencia': 'devolucao_consignacao',
            'quantidade': devolvida.toString(),
            'referencia_id': consignacaoId.toString(),
            'referencia_tipo': 'consignacao',
            'usuario_id': usuarioId.toString(),
          });
        }
      }

      // Update acerto with actual value
      await _repository.updateAcertoValor(acertoId, totalVendido);

      // Update consignacao valor_acertado
      if (totalVendido > 0) {
        await _repository.updateValorAcertado(consignacaoId, totalVendido);
      }

      // Register cash movement
      if (totalVendido > 0) {
        // Find active cash register
        final caixaId = await _repository.buscarCaixaAberto();
        final tipoMov = consignacao.tipo == 'saida' ? 'entrada' : 'saida';
        final categoria = consignacao.tipo == 'saida'
            ? 'acerto_consignacao'
            : 'acerto_consignacao_fornecedor';
        final descricao = consignacao.tipo == 'saida'
            ? 'Acerto consignação #${consignacao.numero}'
            : 'Pgto fornecedor consignação #${consignacao.numero}';

        await _repository.registrarMovimentoCaixa({
          'caixa_id': caixaId.toString(),
          'descricao': descricao,
          'valor': totalVendido.toStringAsFixed(2),
          'tipo': tipoMov,
          'categoria': categoria,
          'referencia_id': consignacaoId.toString(),
          'referencia_tipo': 'consignacao',
          'usuario_id': usuarioId.toString(),
        });

        final saldoDelta =
            consignacao.tipo == 'saida' ? totalVendido : -totalVendido;
        await _repository.atualizarSaldoCaixa(caixaId, saldoDelta);
      }

      // Check if all items are fully settled
      final itensAtualizado =
          await _repository.findItensByConsignacaoId(consignacaoId);
      final todosAcertados =
          itensAtualizado.every((i) => i.quantidadePendente <= 0.001);
      final novoStatus = todosAcertados ? 'fechada' : 'parcial';
      await _repository.updateStatus(consignacaoId, novoStatus);

      return await obterPorId(consignacaoId);
    });
  }

  Future<void> cancelar(int id, int usuarioId) async {
    final consignacao = await _repository.findById(id);
    if (consignacao == null) {
      throw NotFoundException('Consignação não encontrada');
    }
    if (consignacao.status == 'fechada') {
      throw ValidationException('Consignação já fechada não pode ser cancelada');
    }
    if (consignacao.status == 'cancelada') {
      throw ValidationException('Consignação já está cancelada');
    }

    // Wrap in transaction to ensure atomicity
    await Database.instance.transaction(() async {
      final itens = await _repository.findItensByConsignacaoId(id);

      // Revert stock for ALL items (pending + sold)
      // For pending items: they were deducted at creation, revert them
      // For sold items: they are effectively "gone" but since we're
      // cancelling and also reverting cash, we must revert stock too
      for (final item in itens) {
        // Revert pending items stock
        final pendente = item.quantidadePendente;
        if (pendente > 0.001) {
          final stockDelta = consignacao.tipo == 'saida'
              ? pendente.ceil()   // saida: devolver ao estoque
              : -pendente.ceil(); // entrada: remover do estoque

          await _repository.atualizarEstoque(item.produtoId, stockDelta);

          await _repository.registrarHistoricoEstoque({
            'produto_id': item.produtoId.toString(),
            'tipo': consignacao.tipo == 'saida' ? 'entrada' : 'saida',
            'ocorrencia': 'cancelamento_consignacao',
            'quantidade': pendente.toString(),
            'referencia_id': id.toString(),
            'referencia_tipo': 'consignacao',
            'usuario_id': usuarioId.toString(),
          });
        }

        // For items already sold in acertos: the devolutions already
        // restored stock (handled during acerto). The sold items
        // were never returned to stock (correct). When we reverse
        // cash below, the sold items' stock stays consistent because
        // they were already "out" when originally consigned.
      }

      // Revert cash movements from previous acertos
      final totalAcertado = await _repository.somaAcertosValor(id);
      if (totalAcertado > 0) {
        final caixaId = await _repository.buscarCaixaAberto();
        final tipoMov = consignacao.tipo == 'saida' ? 'saida' : 'entrada';
        final descricao =
            'Cancelamento consignação #${consignacao.numero}';

        await _repository.registrarMovimentoCaixa({
          'caixa_id': caixaId.toString(),
          'descricao': descricao,
          'valor': totalAcertado.toStringAsFixed(2),
          'tipo': tipoMov,
          'categoria': 'cancelamento_consignacao',
          'referencia_id': id.toString(),
          'referencia_tipo': 'consignacao',
          'usuario_id': usuarioId.toString(),
        });

        final saldoDelta =
            consignacao.tipo == 'saida' ? -totalAcertado : totalAcertado;
        await _repository.atualizarSaldoCaixa(caixaId, saldoDelta);
      }

      await _repository.updateStatus(id, 'cancelada');
    });
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
