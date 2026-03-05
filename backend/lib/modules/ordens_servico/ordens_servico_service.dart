import 'ordens_servico_repository.dart';
import 'ordem_servico_model.dart';
import '../../core/exceptions/api_exception.dart';

class OrdensServicoService {
  final OrdensServicoRepository _repository;

  OrdensServicoService(this._repository);

  Future<Map<String, dynamic>> listar(Map<String, dynamic> params) async {
    final busca = params['busca'] as String?;
    final status = params['status'] as String?;
    final clienteId = params['cliente_id'] as int?;
    final prestadorId = params['prestador_id'] as int?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final rows = await _repository.findAll(
      busca: busca,
      status: status,
      clienteId: clienteId,
      prestadorId: prestadorId,
      limit: limit,
      offset: offset,
    );

    final total = await _repository.count(
      busca: busca,
      status: status,
      clienteId: clienteId,
      prestadorId: prestadorId,
    );

    return {
      'items': rows.map((row) => OrdemServico.fromRow(row).toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> obterPorId(int id) async {
    final row = await _repository.findById(id);
    if (row == null) {
      throw NotFoundException('Ordem de servico nao encontrada');
    }

    final os = OrdemServico.fromRow(row).toJson();

    // Carregar itens
    final itensServico = await _repository.findItensServico(id);
    final itensProduto = await _repository.findItensProduto(id);

    os['itens_servico'] =
        itensServico.map((r) => OsItemServico.fromRow(r).toJson()).toList();
    os['itens_produto'] =
        itensProduto.map((r) => OsItemProduto.fromRow(r).toJson()).toList();

    return os;
  }

  Future<Map<String, dynamic>> criar(Map<String, dynamic> data) async {
    final clienteId = data['cliente_id'];
    if (clienteId == null) {
      throw ValidationException('Cliente e obrigatorio');
    }

    final prestadorId = data['prestador_id'];
    if (prestadorId == null) {
      throw ValidationException('Prestador e obrigatorio');
    }

    final numero = await _repository.gerarNumero();

    final dbData = <String, String>{
      'numero': numero,
      'cliente_id': clienteId.toString(),
      'prestador_id': prestadorId.toString(),
      'data_inicio':
          data['data_inicio']?.toString() ?? DateTime.now().toIso8601String(),
      'status': 'aberta',
      'subtotal': '0.00',
      'desconto': '0.00',
      'total': '0.00',
    };

    if (data['detalhes'] != null && data['detalhes'].toString().isNotEmpty) {
      dbData['detalhes'] = data['detalhes'].toString();
    }
    if (data['pedido'] != null && data['pedido'].toString().isNotEmpty) {
      dbData['pedido'] = data['pedido'].toString();
    }
    if (data['texto_padrao'] != null) {
      dbData['texto_padrao'] = data['texto_padrao'].toString();
    }
    if (data['observacoes'] != null) {
      dbData['observacoes'] = data['observacoes'].toString();
    }

    final id = await _repository.create(dbData);
    return await obterPorId(id);
  }

  Future<Map<String, dynamic>> atualizar(
      int id, Map<String, dynamic> data) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Ordem de servico nao encontrada');
    }

    if (existing['status'] == 'finalizada' || existing['status'] == 'cancelada') {
      throw ValidationException(
          'Nao e possivel editar uma OS ${existing['status']}');
    }

    final updateData = <String, dynamic>{};

    final allowedFields = [
      'cliente_id',
      'prestador_id',
      'data_inicio',
      'data_termino',
      'detalhes',
      'pedido',
      'forma_pagamento',
      'desconto',
      'texto_padrao',
      'observacoes',
    ];

    for (final field in allowedFields) {
      if (data.containsKey(field)) {
        updateData[field] = data[field]?.toString();
      }
    }

    if (data.containsKey('desconto')) {
      final desconto = data['desconto'];
      final descontoNum = desconto is num
          ? desconto.toDouble()
          : double.tryParse(desconto?.toString() ?? '') ?? 0;
      updateData['desconto'] = descontoNum.toStringAsFixed(2);
    }

    if (updateData.isNotEmpty) {
      await _repository.update(id, updateData);
      await _recalcularTotais(id);
    }

    return await obterPorId(id);
  }

  Future<Map<String, dynamic>> adicionarItemServico(
      int osId, Map<String, dynamic> data) async {
    final existing = await _repository.findById(osId);
    if (existing == null) {
      throw NotFoundException('Ordem de servico nao encontrada');
    }

    if (existing['status'] == 'finalizada' || existing['status'] == 'cancelada') {
      throw ValidationException('Nao e possivel adicionar itens a uma OS ${existing['status']}');
    }

    final servicoId = data['servico_id'];
    if (servicoId == null) {
      throw ValidationException('Servico e obrigatorio');
    }

    final quantidade = data['quantidade'] is num
        ? (data['quantidade'] as num).toDouble()
        : double.tryParse(data['quantidade']?.toString() ?? '') ?? 1;

    final precoUnitario = data['preco_unitario'] is num
        ? (data['preco_unitario'] as num).toDouble()
        : double.tryParse(data['preco_unitario']?.toString() ?? '') ?? 0;

    final total = quantidade * precoUnitario;

    await _repository.addItemServico({
      'ordem_servico_id': osId.toString(),
      'servico_id': servicoId.toString(),
      'quantidade': quantidade.toStringAsFixed(3),
      'preco_unitario': precoUnitario.toStringAsFixed(2),
      'total': total.toStringAsFixed(2),
    });

    await _recalcularTotais(osId);
    return await obterPorId(osId);
  }

  Future<Map<String, dynamic>> removerItemServico(
      int osId, int itemId) async {
    final existing = await _repository.findById(osId);
    if (existing == null) {
      throw NotFoundException('Ordem de servico nao encontrada');
    }

    if (existing['status'] == 'finalizada' || existing['status'] == 'cancelada') {
      throw ValidationException('Nao e possivel remover itens de uma OS ${existing['status']}');
    }

    await _repository.removeItemServico(itemId);
    await _recalcularTotais(osId);
    return await obterPorId(osId);
  }

  Future<Map<String, dynamic>> adicionarItemProduto(
      int osId, Map<String, dynamic> data) async {
    final existing = await _repository.findById(osId);
    if (existing == null) {
      throw NotFoundException('Ordem de servico nao encontrada');
    }

    if (existing['status'] == 'finalizada' || existing['status'] == 'cancelada') {
      throw ValidationException('Nao e possivel adicionar itens a uma OS ${existing['status']}');
    }

    final produtoId = data['produto_id'];
    if (produtoId == null) {
      throw ValidationException('Produto e obrigatorio');
    }

    final quantidade = data['quantidade'] is num
        ? (data['quantidade'] as num).toDouble()
        : double.tryParse(data['quantidade']?.toString() ?? '') ?? 1;

    final precoUnitario = data['preco_unitario'] is num
        ? (data['preco_unitario'] as num).toDouble()
        : double.tryParse(data['preco_unitario']?.toString() ?? '') ?? 0;

    final total = quantidade * precoUnitario;

    await _repository.addItemProduto({
      'ordem_servico_id': osId.toString(),
      'produto_id': produtoId.toString(),
      'quantidade': quantidade.toStringAsFixed(3),
      'preco_unitario': precoUnitario.toStringAsFixed(2),
      'total': total.toStringAsFixed(2),
    });

    await _recalcularTotais(osId);
    return await obterPorId(osId);
  }

  Future<Map<String, dynamic>> removerItemProduto(
      int osId, int itemId) async {
    final existing = await _repository.findById(osId);
    if (existing == null) {
      throw NotFoundException('Ordem de servico nao encontrada');
    }

    if (existing['status'] == 'finalizada' || existing['status'] == 'cancelada') {
      throw ValidationException('Nao e possivel remover itens de uma OS ${existing['status']}');
    }

    await _repository.removeItemProduto(itemId);
    await _recalcularTotais(osId);
    return await obterPorId(osId);
  }

  Future<Map<String, dynamic>> finalizar(
      int id, Map<String, dynamic> data) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Ordem de servico nao encontrada');
    }

    if (existing['status'] == 'finalizada') {
      throw ValidationException('Esta OS ja foi finalizada');
    }

    if (existing['status'] == 'cancelada') {
      throw ValidationException('Esta OS esta cancelada');
    }

    final formaPagamento = data['forma_pagamento'] as String?;
    if (formaPagamento == null || formaPagamento.isEmpty) {
      throw ValidationException('Forma de pagamento e obrigatoria');
    }

    final updateData = <String, dynamic>{
      'status': 'finalizada',
      'forma_pagamento': formaPagamento,
      'data_termino':
          data['data_termino']?.toString() ?? DateTime.now().toIso8601String(),
    };

    await _repository.update(id, updateData);
    return await obterPorId(id);
  }

  Future<Map<String, dynamic>> cancelar(int id) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Ordem de servico nao encontrada');
    }

    if (existing['status'] == 'finalizada') {
      throw ValidationException(
          'Nao e possivel cancelar uma OS ja finalizada');
    }

    await _repository.update(id, {'status': 'cancelada'});
    return await obterPorId(id);
  }

  Future<void> excluir(int id) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Ordem de servico nao encontrada');
    }

    if (existing['status'] == 'finalizada') {
      throw ValidationException(
          'Nao e possivel excluir uma OS finalizada');
    }

    await _repository.delete(id);
  }

  Future<void> _recalcularTotais(int osId) async {
    final itensServico = await _repository.findItensServico(osId);
    final itensProduto = await _repository.findItensProduto(osId);

    double subtotal = 0;
    for (final item in itensServico) {
      subtotal += double.parse(item['total'] ?? '0');
    }
    for (final item in itensProduto) {
      subtotal += double.parse(item['total'] ?? '0');
    }

    final existing = await _repository.findById(osId);
    final desconto =
        double.parse(existing?['desconto'] ?? '0');
    final total = subtotal - desconto;

    await _repository.update(osId, {
      'subtotal': subtotal.toStringAsFixed(2),
      'total': (total < 0 ? 0 : total).toStringAsFixed(2),
    });
  }
}
