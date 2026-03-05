import 'devolucoes_repository.dart';
import 'devolucao_model.dart';
import '../../core/exceptions/api_exception.dart';

class DevolucoesService {
  final DevolucoesRepository _repository;

  DevolucoesService(this._repository);

  // ── Devoluções ──

  Future<Map<String, dynamic>> listar(Map<String, dynamic> params) async {
    final tipo = params['tipo'] as String?;
    final status = params['status'] as String?;
    final clienteId = params['cliente_id'] as int?;
    final vendaId = params['venda_id'] as int?;
    final dataInicio = params['data_inicio'] as String?;
    final dataFim = params['data_fim'] as String?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final rows = await _repository.findAll(
      tipo: tipo,
      status: status,
      clienteId: clienteId,
      vendaId: vendaId,
      dataInicio: dataInicio,
      dataFim: dataFim,
      limit: limit,
      offset: offset,
    );

    final total = await _repository.count(
      tipo: tipo,
      status: status,
      clienteId: clienteId,
      vendaId: vendaId,
    );

    return {
      'items': rows.map((r) => Devolucao.fromRow(r).toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> obterPorId(int id) async {
    final row = await _repository.findById(id);
    if (row == null) {
      throw NotFoundException('Devolucao nao encontrada');
    }

    final devolucao = Devolucao.fromRow(row);
    final itensRows = await _repository.findItensByDevolucaoId(id);
    final itens = itensRows.map((r) => DevolucaoItem.fromRow(r)).toList();

    final json = devolucao.toJson();
    json['itens'] = itens.map((i) => i.toJson()).toList();
    return json;
  }

  /// Busca dados da venda original para montar a tela de devolução
  Future<Map<String, dynamic>> buscarVenda(String numero) async {
    final venda = await _repository.getVendaByNumero(numero);
    if (venda == null) {
      throw NotFoundException('Venda nao encontrada');
    }

    if (venda['status'] != 'finalizada') {
      throw ValidationException('Apenas vendas finalizadas podem ser devolvidas');
    }

    // Verificar prazo de devolução
    final prazoDias = await _repository.getConfigValue('prazo_devolucao_dias');
    if (prazoDias != null) {
      final prazo = int.tryParse(prazoDias) ?? 30;
      final dataVenda = DateTime.parse(venda['criado_em']!);
      final limite = dataVenda.add(Duration(days: prazo));
      if (DateTime.now().isAfter(limite)) {
        throw ValidationException(
          'Prazo de devolucao expirado. Limite: $prazo dias',
        );
      }
    }

    final itens = await _repository.getItensVenda(
      int.parse(venda['id']!),
    );

    // Para cada item, verificar quantidade já devolvida
    final vendaId = int.parse(venda['id']!);
    final itensComDevolvido = <Map<String, dynamic>>[];

    for (final item in itens) {
      final produtoId = int.parse(item['produto_id'] ?? '0');
      final qtdDevolvida =
          await _repository.getQuantidadeDevolvida(vendaId, produtoId);
      final qtdOriginal = double.parse(item['quantidade'] ?? '0');

      itensComDevolvido.add({
        ...item,
        'quantidade_devolvida': qtdDevolvida,
        'quantidade_disponivel': qtdOriginal - qtdDevolvida,
      });
    }

    return {
      ...venda,
      'itens': itensComDevolvido,
    };
  }

  /// Busca vendas finalizadas por valor total
  Future<List<Map<String, dynamic>>> buscarVendasPorValor(double valor) async {
    final rows = await _repository.getVendasByValor(valor);
    return rows.map((r) => <String, dynamic>{...r}).toList();
  }

  /// Cria uma devolução/troca
  Future<Map<String, dynamic>> criar(
    Map<String, dynamic> data,
    int usuarioId,
  ) async {
    // Validar venda
    final vendaId = _parseInt(data['venda_id']);
    if (vendaId == null) {
      throw ValidationException('Venda e obrigatoria');
    }

    final venda = await _repository.getVenda(vendaId);
    if (venda == null) {
      throw NotFoundException('Venda nao encontrada');
    }
    if (venda['status'] != 'finalizada') {
      throw ValidationException('Apenas vendas finalizadas podem ser devolvidas');
    }

    // Validar tipo
    final tipo = data['tipo'] as String? ?? 'devolucao';
    if (tipo != 'devolucao' && tipo != 'troca') {
      throw ValidationException('Tipo deve ser "devolucao" ou "troca"');
    }

    // Validar motivo
    final motivo = data['motivo'] as String?;
    if (motivo == null || motivo.isEmpty) {
      throw ValidationException('Motivo e obrigatorio');
    }

    // Validar forma de restituição
    final formaRestituicao =
        data['forma_restituicao'] as String? ?? 'credito';
    if (!['dinheiro', 'credito', 'troca'].contains(formaRestituicao)) {
      throw ValidationException(
          'Forma de restituicao invalida');
    }

    // Validar itens
    final itens = data['itens'] as List<dynamic>?;
    if (itens == null || itens.isEmpty) {
      throw ValidationException('Informe pelo menos um item para devolver');
    }

    // Processar itens
    double valorTotal = 0;
    final itensProcessados = <Map<String, dynamic>>[];

    for (final item in itens) {
      final itemMap = item as Map<String, dynamic>;
      final produtoId = _parseInt(itemMap['produto_id']);
      if (produtoId == null) {
        throw ValidationException('produto_id e obrigatorio em cada item');
      }

      final quantidade = _parseDouble(itemMap['quantidade']) ?? 0;
      if (quantidade <= 0) {
        throw ValidationException('Quantidade deve ser positiva');
      }

      // Verificar quantidade disponível para devolução
      final qtdDevolvida =
          await _repository.getQuantidadeDevolvida(vendaId, produtoId);

      // Buscar quantidade original da venda
      final itensVenda = await _repository.getItensVenda(vendaId);
      final itemVenda = itensVenda.firstWhere(
        (iv) => iv['produto_id'] == produtoId.toString(),
        orElse: () => throw ValidationException(
            'Produto $produtoId nao encontrado nesta venda'),
      );

      final qtdOriginal = double.parse(itemVenda['quantidade'] ?? '0');
      final qtdDisponivel = qtdOriginal - qtdDevolvida;

      if (quantidade > qtdDisponivel) {
        throw ValidationException(
          'Quantidade de devolucao ($quantidade) excede o disponivel ($qtdDisponivel) '
          'para o produto ${itemVenda['produto_descricao'] ?? produtoId}',
        );
      }

      final precoUnitario =
          double.parse(itemVenda['preco_unitario'] ?? '0');
      final subtotal = quantidade * precoUnitario;

      itensProcessados.add({
        'produto_id': produtoId,
        'quantidade': quantidade,
        'preco_unitario': precoUnitario,
        'subtotal': subtotal,
        'motivo_item': itemMap['motivo_item'] as String?,
        'estado_produto': itemMap['estado_produto'] as String? ?? 'novo',
        'retorna_estoque': itemMap['retorna_estoque'] ?? true,
      });

      valorTotal += subtotal;
    }

    // Criar a devolução
    final clienteId = venda['cliente_id'];
    final devolucaoData = <String, String>{
      'venda_id': vendaId.toString(),
      'usuario_id': usuarioId.toString(),
      'motivo': motivo,
      'tipo': tipo,
      'status': 'finalizada',
      'valor_total': valorTotal.toStringAsFixed(2),
      'forma_restituicao': formaRestituicao,
    };

    if (clienteId != null) {
      devolucaoData['cliente_id'] = clienteId;
    }
    if (data['observacoes'] != null) {
      devolucaoData['observacoes'] = data['observacoes'].toString();
    }

    final devolucaoId = await _repository.create(devolucaoData);

    // Criar itens
    for (final item in itensProcessados) {
      await _repository.createItem({
        'devolucao_id': devolucaoId.toString(),
        'produto_id': item['produto_id'].toString(),
        'quantidade': (item['quantidade'] as double).toString(),
        'preco_unitario':
            (item['preco_unitario'] as double).toStringAsFixed(2),
        'subtotal': (item['subtotal'] as double).toStringAsFixed(2),
        'motivo_item': item['motivo_item'] ?? '',
        'estado_produto': item['estado_produto'] as String,
        'retorna_estoque': (item['retorna_estoque'] == true) ? '1' : '0',
      });

      // Retornar ao estoque se aplicável
      if (item['retorna_estoque'] == true) {
        final qtd = (item['quantidade'] as double).toInt();
        await _repository.adicionarEstoque(
          item['produto_id'] as int,
          qtd,
        );

        await _repository.registrarHistoricoEstoque({
          'produto_id': item['produto_id'].toString(),
          'tipo': 'entrada',
          'ocorrencia': 'devolucao',
          'quantidade': qtd.toString(),
          'referencia_id': devolucaoId.toString(),
          'referencia_tipo': 'devolucao',
          'usuario_id': usuarioId.toString(),
        });
      }
    }

    // Processar restituição
    if (formaRestituicao == 'dinheiro') {
      // Registrar saída no caixa
      await _repository.registrarMovimentoCaixa({
        'caixa_id': '1',
        'descricao': 'Devolucao #$devolucaoId - Venda ${venda['numero']}',
        'valor': valorTotal.toStringAsFixed(2),
        'tipo': 'saida',
        'categoria': 'devolucao',
        'referencia_id': devolucaoId.toString(),
        'referencia_tipo': 'devolucao',
        'usuario_id': usuarioId.toString(),
      });
      await _repository.atualizarSaldoCaixa(1, -valorTotal);
    } else if (formaRestituicao == 'credito' && clienteId != null) {
      // Gerar crédito para o cliente
      await _gerarCredito(
        clienteId: int.parse(clienteId),
        devolucaoId: devolucaoId,
        valor: valorTotal,
      );
      await _repository.updateCreditoGerado(devolucaoId, valorTotal);
    }

    return await obterPorId(devolucaoId);
  }

  // ── Customer Credits ──

  Future<Map<String, dynamic>> listarCreditos(
      Map<String, dynamic> params) async {
    final clienteId = params['cliente_id'] as int?;
    final status = params['status'] as String?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final rows = await _repository.findCredits(
      clienteId: clienteId,
      status: status,
      limit: limit,
      offset: offset,
    );

    final total = await _repository.countCredits(
      clienteId: clienteId,
      status: status,
    );

    return {
      'items':
          rows.map((r) => CustomerCredit.fromRow(r).toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> obterSaldoCliente(int clienteId) async {
    final saldo = await _repository.getSaldoCreditosCliente(clienteId);
    final creditos = await _repository.getCreditosAtivosCliente(clienteId);

    return {
      'cliente_id': clienteId,
      'saldo': saldo,
      'creditos':
          creditos.map((r) => CustomerCredit.fromRow(r).toJson()).toList(),
    };
  }

  Future<Map<String, dynamic>> utilizarCredito(
    int creditoId,
    Map<String, dynamic> data,
  ) async {
    final credit = await _repository.findCreditById(creditoId);
    if (credit == null) {
      throw NotFoundException('Credito nao encontrado');
    }

    if (credit['status'] != 'ativo') {
      throw ValidationException('Este credito nao esta ativo');
    }

    final saldoAtual = double.parse(credit['saldo'] ?? '0');
    final valorUso = _parseDouble(data['valor']) ?? 0;

    if (valorUso <= 0) {
      throw ValidationException('Valor deve ser positivo');
    }
    if (valorUso > saldoAtual) {
      throw ValidationException(
          'Valor excede o saldo disponivel (R\$ ${saldoAtual.toStringAsFixed(2)})');
    }

    final novoSaldo = saldoAtual - valorUso;
    final valorUtilizado =
        double.parse(credit['valor_utilizado'] ?? '0') + valorUso;

    final updates = <String, dynamic>{
      'saldo': novoSaldo.toStringAsFixed(2),
      'valor_utilizado': valorUtilizado.toStringAsFixed(2),
    };

    if (novoSaldo <= 0) {
      updates['status'] = 'utilizado';
    }

    await _repository.updateCredit(creditoId, updates);

    final updated = await _repository.findCreditById(creditoId);
    return CustomerCredit.fromRow(updated!).toJson();
  }

  Future<Map<String, dynamic>> totaisCreditos({int? clienteId}) async {
    final row = await _repository.getCreditTotais(clienteId: clienteId);
    return {
      'total_ativo': double.parse(row['total_ativo'] ?? '0'),
      'total_utilizado': double.parse(row['total_utilizado'] ?? '0'),
      'qtd_ativo': int.parse(row['qtd_ativo'] ?? '0'),
      'qtd_utilizado': int.parse(row['qtd_utilizado'] ?? '0'),
      'qtd_expirado': int.parse(row['qtd_expirado'] ?? '0'),
    };
  }

  // ── Helpers ──

  Future<void> _gerarCredito({
    required int clienteId,
    required int devolucaoId,
    required double valor,
  }) async {
    // Prazo de expiração configurável
    final prazoDias = await _repository.getConfigValue('prazo_devolucao_dias');
    final prazo = int.tryParse(prazoDias ?? '30') ?? 30;
    final dataExpiracao = DateTime.now().add(Duration(days: prazo * 6));

    await _repository.createCredit({
      'cliente_id': clienteId.toString(),
      'devolucao_id': devolucaoId.toString(),
      'valor': valor.toStringAsFixed(2),
      'saldo': valor.toStringAsFixed(2),
      'status': 'ativo',
      'data_expiracao':
          '${dataExpiracao.year}-${dataExpiracao.month.toString().padLeft(2, '0')}-${dataExpiracao.day.toString().padLeft(2, '0')}',
      'observacoes': 'Credito gerado pela devolucao #$devolucaoId',
    });
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
