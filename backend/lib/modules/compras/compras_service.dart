import '../../core/exceptions/api_exception.dart';
import 'compras_repository.dart';

class ComprasService {
  final ComprasRepository _repository;

  ComprasService(this._repository);

  Future<Map<String, dynamic>> listar(Map<String, dynamic> params) async {
    final fornecedorId = params['fornecedor_id'] as int?;
    final dataInicio = params['data_inicio'] as String?;
    final dataFim = params['data_fim'] as String?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final compras = await _repository.findAll(
      fornecedorId: fornecedorId,
      dataInicio: dataInicio,
      dataFim: dataFim,
      limit: limit,
      offset: offset,
    );

    final total = await _repository.count(
      fornecedorId: fornecedorId,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );

    return {
      'items': compras.map((c) => c.toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> obterPorId(int id) async {
    final compra = await _repository.findById(id);
    if (compra == null) {
      throw NotFoundException('Compra não encontrada');
    }

    final itens = await _repository.findItensByCompraId(id);
    final compraJson = compra.toJson();
    compraJson['itens'] = itens.map((i) => i.toJson()).toList();
    return compraJson;
  }

  Future<Map<String, dynamic>> criar(
    Map<String, dynamic> data,
    int usuarioId,
  ) async {
    // Validações
    final fornecedorId = _parseInt(data['fornecedor_id']);
    if (fornecedorId == null || fornecedorId == 0) {
      throw ValidationException('Fornecedor é obrigatório');
    }

    final itens = data['itens'] as List<dynamic>?;
    if (itens == null || itens.isEmpty) {
      throw ValidationException('A compra deve ter pelo menos um item');
    }

    final dataCompra = data['data_compra']?.toString() ??
        DateTime.now().toIso8601String();

    final formaPagamento = data['forma_pagamento']?.toString();

    // Processar itens
    double valorBruto = 0;
    final itensProcessados = <Map<String, dynamic>>[];

    for (final item in itens) {
      final itemMap = item as Map<String, dynamic>;
      final produtoId = _parseInt(itemMap['produto_id']);

      if (produtoId == null || produtoId == 0) {
        throw ValidationException('produto_id é obrigatório em cada item');
      }

      final produto = await _repository.getProduto(produtoId);
      if (produto == null) {
        throw NotFoundException('Produto $produtoId não encontrado');
      }

      final quantidade = _parseDouble(itemMap['quantidade']) ?? 1;
      if (quantidade <= 0) {
        throw ValidationException('Quantidade deve ser positiva');
      }

      final precoUnitario = _parseDouble(itemMap['preco_unitario']) ?? 0;
      final totalItem = quantidade * precoUnitario;

      itensProcessados.add({
        'produto_id': produtoId,
        'quantidade': quantidade,
        'preco_unitario': precoUnitario,
        'total': totalItem,
      });

      valorBruto += totalItem;
    }

    final valorFinal = _parseDouble(data['valor_final']) ?? valorBruto;

    // Criar a compra
    final compraData = <String, String>{
      'fornecedor_id': fornecedorId.toString(),
      'data_compra': dataCompra,
      'valor_bruto': valorBruto.toStringAsFixed(2),
      'valor_final': valorFinal.toStringAsFixed(2),
    };

    if (formaPagamento != null && formaPagamento.isNotEmpty) {
      compraData['forma_pagamento'] = formaPagamento;
    }
    if (data['chave_nfe'] != null) {
      compraData['chave_nfe'] = data['chave_nfe'].toString();
    }
    if (data['xml_importado'] != null) {
      compraData['xml_importado'] = data['xml_importado'] == true ? '1' : '0';
    }
    if (data['observacoes'] != null) {
      compraData['observacoes'] = data['observacoes'].toString();
    }

    final compraId = await _repository.create(compraData);

    // Criar itens e dar entrada no estoque
    for (final item in itensProcessados) {
      await _repository.createItem({
        'compra_id': compraId.toString(),
        'produto_id': item['produto_id'].toString(),
        'quantidade': (item['quantidade'] as double).toString(),
        'preco_unitario':
            (item['preco_unitario'] as double).toStringAsFixed(2),
        'total': (item['total'] as double).toStringAsFixed(2),
      });

      // Dar entrada no estoque
      final qtd = item['quantidade'] as double;
      await _repository.atualizarEstoque(
        item['produto_id'] as int,
        qtd,
      );

      // Registrar histórico de estoque
      await _repository.registrarHistoricoEstoque({
        'produto_id': item['produto_id'].toString(),
        'tipo': 'entrada',
        'ocorrencia': 'compra',
        'quantidade': qtd.toString(),
        'referencia_id': compraId.toString(),
        'referencia_tipo': 'compra',
        'usuario_id': usuarioId.toString(),
      });
    }

    return await obterPorId(compraId);
  }

  Future<Map<String, dynamic>> atualizar(
    int id,
    Map<String, dynamic> data,
    int usuarioId,
  ) async {
    final compra = await _repository.findById(id);
    if (compra == null) {
      throw NotFoundException('Compra não encontrada');
    }

    // Reverter estoque dos itens antigos
    final itensAntigos = await _repository.findItensByCompraId(id);
    for (final item in itensAntigos) {
      await _repository.atualizarEstoque(
        item.produtoId,
        -item.quantidade,
      );
      await _repository.registrarHistoricoEstoque({
        'produto_id': item.produtoId.toString(),
        'tipo': 'saida',
        'ocorrencia': 'ajuste_compra',
        'quantidade': item.quantidade.toString(),
        'referencia_id': id.toString(),
        'referencia_tipo': 'ajuste_compra',
        'usuario_id': usuarioId.toString(),
      });
    }

    // Deletar itens antigos
    await _repository.deleteItensByCompraId(id);

    // Processar novos itens
    final itens = data['itens'] as List<dynamic>?;
    if (itens == null || itens.isEmpty) {
      throw ValidationException('A compra deve ter pelo menos um item');
    }

    double valorBruto = 0;
    final itensProcessados = <Map<String, dynamic>>[];

    for (final item in itens) {
      final itemMap = item as Map<String, dynamic>;
      final produtoId = _parseInt(itemMap['produto_id']);

      if (produtoId == null || produtoId == 0) {
        throw ValidationException('produto_id é obrigatório em cada item');
      }

      final quantidade = _parseDouble(itemMap['quantidade']) ?? 1;
      final precoUnitario = _parseDouble(itemMap['preco_unitario']) ?? 0;
      final totalItem = quantidade * precoUnitario;

      itensProcessados.add({
        'produto_id': produtoId,
        'quantidade': quantidade,
        'preco_unitario': precoUnitario,
        'total': totalItem,
      });

      valorBruto += totalItem;
    }

    final valorFinal = _parseDouble(data['valor_final']) ?? valorBruto;

    // Atualizar compra
    final compraUpdate = <String, String>{
      'fornecedor_id': (data['fornecedor_id'] ?? compra.fornecedorId).toString(),
      'data_compra': data['data_compra']?.toString() ??
          compra.dataCompra.toIso8601String(),
      'valor_bruto': valorBruto.toStringAsFixed(2),
      'valor_final': valorFinal.toStringAsFixed(2),
    };

    if (data.containsKey('forma_pagamento')) {
      compraUpdate['forma_pagamento'] =
          data['forma_pagamento']?.toString() ?? '';
    }
    if (data.containsKey('chave_nfe')) {
      compraUpdate['chave_nfe'] = data['chave_nfe']?.toString() ?? '';
    }
    if (data.containsKey('observacoes')) {
      compraUpdate['observacoes'] = data['observacoes']?.toString() ?? '';
    }

    await _repository.update(id, compraUpdate);

    // Criar novos itens e dar entrada no estoque
    for (final item in itensProcessados) {
      await _repository.createItem({
        'compra_id': id.toString(),
        'produto_id': item['produto_id'].toString(),
        'quantidade': (item['quantidade'] as double).toString(),
        'preco_unitario':
            (item['preco_unitario'] as double).toStringAsFixed(2),
        'total': (item['total'] as double).toStringAsFixed(2),
      });

      final qtd = item['quantidade'] as double;
      await _repository.atualizarEstoque(item['produto_id'] as int, qtd);

      await _repository.registrarHistoricoEstoque({
        'produto_id': item['produto_id'].toString(),
        'tipo': 'entrada',
        'ocorrencia': 'compra',
        'quantidade': qtd.toString(),
        'referencia_id': id.toString(),
        'referencia_tipo': 'compra',
        'usuario_id': usuarioId.toString(),
      });
    }

    return await obterPorId(id);
  }

  Future<void> excluir(int id, int usuarioId) async {
    final compra = await _repository.findById(id);
    if (compra == null) {
      throw NotFoundException('Compra não encontrada');
    }

    // Reverter estoque
    final itens = await _repository.findItensByCompraId(id);
    for (final item in itens) {
      await _repository.atualizarEstoque(
        item.produtoId,
        -item.quantidade,
      );
      await _repository.registrarHistoricoEstoque({
        'produto_id': item.produtoId.toString(),
        'tipo': 'saida',
        'ocorrencia': 'exclusao_compra',
        'quantidade': item.quantidade.toString(),
        'referencia_id': id.toString(),
        'referencia_tipo': 'exclusao_compra',
        'usuario_id': usuarioId.toString(),
      });
    }

    await _repository.delete(id);
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
