import '../../config/database.dart';
import 'venda_model.dart';
import 'venda_item_model.dart';

class VendasRepository {
  Future<Venda?> findById(int id) async {
    final results = await Database.instance.query(
      'SELECT * FROM vendas WHERE id = :id',
      {'id': id.toString()},
    );
    if (results.isEmpty) return null;
    return Venda.fromRow(results.first);
  }

  Future<Venda?> findByNumero(String numero) async {
    final results = await Database.instance.query(
      'SELECT * FROM vendas WHERE numero = :numero',
      {'numero': numero},
    );
    if (results.isEmpty) return null;
    return Venda.fromRow(results.first);
  }

  Future<List<Venda>> findAll({
    String? tipo,
    String? status,
    int? clienteId,
    int? usuarioId,
    String? dataInicio,
    String? dataFim,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (tipo != null) {
      where += ' AND tipo = :tipo';
      params['tipo'] = tipo;
    }
    if (status != null) {
      where += ' AND status = :status';
      params['status'] = status;
    }
    if (clienteId != null) {
      where += ' AND cliente_id = :cliente_id';
      params['cliente_id'] = clienteId.toString();
    }
    if (usuarioId != null) {
      where += ' AND usuario_id = :usuario_id';
      params['usuario_id'] = usuarioId.toString();
    }
    if (dataInicio != null) {
      where += ' AND criado_em >= :data_inicio';
      params['data_inicio'] = dataInicio;
    }
    if (dataFim != null) {
      where += ' AND criado_em <= :data_fim';
      params['data_fim'] = dataFim;
    }

    final results = await Database.instance.query(
      'SELECT * FROM vendas $where ORDER BY criado_em DESC LIMIT $limit OFFSET $offset',
      params,
    );
    return results.map((row) => Venda.fromRow(row)).toList();
  }

  Future<int> count({
    String? tipo,
    String? status,
    int? clienteId,
    int? usuarioId,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (tipo != null) {
      where += ' AND tipo = :tipo';
      params['tipo'] = tipo;
    }
    if (status != null) {
      where += ' AND status = :status';
      params['status'] = status;
    }
    if (clienteId != null) {
      where += ' AND cliente_id = :cliente_id';
      params['cliente_id'] = clienteId.toString();
    }
    if (usuarioId != null) {
      where += ' AND usuario_id = :usuario_id';
      params['usuario_id'] = usuarioId.toString();
    }

    final results = await Database.instance.query(
      'SELECT COUNT(*) as total FROM vendas $where',
      params,
    );
    if (results.isEmpty) return 0;
    return int.parse(results.first['total'] ?? '0');
  }

  Future<String> gerarNumero() async {
    final now = DateTime.now();
    final prefix =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final results = await Database.instance.query(
      'SELECT COUNT(*) as total FROM vendas WHERE numero LIKE :prefix',
      {'prefix': '$prefix%'},
    );
    final seq = int.parse(results.first['total'] ?? '0') + 1;
    return '$prefix${seq.toString().padLeft(4, '0')}';
  }

  Future<int> create(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO vendas (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    final result = await Database.instance.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<void> createItem(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO venda_itens (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    await Database.instance.execute(sql, data);
  }

  Future<List<VendaItem>> findItensByVendaId(int vendaId) async {
    final results = await Database.instance.query(
      'SELECT vi.*, '
      'COALESCE(p.descricao, s.descricao) as produto_descricao '
      'FROM venda_itens vi '
      'LEFT JOIN produtos p ON vi.produto_id = p.id '
      'LEFT JOIN servicos s ON vi.servico_id = s.id '
      'WHERE vi.venda_id = :venda_id '
      'ORDER BY vi.id',
      {'venda_id': vendaId.toString()},
    );
    return results.map((row) => VendaItem.fromRow(row)).toList();
  }

  Future<void> updateStatus(int id, String status) async {
    await Database.instance.execute(
      'UPDATE vendas SET status = :status WHERE id = :id',
      {'status': status, 'id': id.toString()},
    );
  }

  Future<void> atualizarEstoque(int produtoId, int quantidade) async {
    await Database.instance.execute(
      'UPDATE produtos SET estoque_atual = estoque_atual - :qtd WHERE id = :id',
      {'qtd': quantidade.toString(), 'id': produtoId.toString()},
    );
  }

  Future<Map<String, String?>?> getProduto(int id) async {
    final results = await Database.instance.query(
      'SELECT id, descricao, estoque_atual, preco_venda, bloqueado, ativo FROM produtos WHERE id = :id',
      {'id': id.toString()},
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<Map<String, String?>?> getServico(int id) async {
    final results = await Database.instance.query(
      'SELECT id, descricao, preco, ativo FROM servicos WHERE id = :id',
      {'id': id.toString()},
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> registrarHistoricoEstoque(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO historico_estoque (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    await Database.instance.execute(sql, data);
  }

  Future<void> registrarMovimentoCaixa(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO caixa_movimentos (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    await Database.instance.execute(sql, data);
  }

  Future<void> atualizarSaldoCaixa(int caixaId, double valor) async {
    await Database.instance.execute(
      'UPDATE caixas SET saldo_atual = saldo_atual + :valor WHERE id = :id',
      {'valor': valor.toString(), 'id': caixaId.toString()},
    );
  }

  Future<void> createPagamento(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO venda_pagamentos (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    await Database.instance.execute(sql, data);
  }

  Future<List<Map<String, String?>>> findPagamentosByVendaId(
      int vendaId) async {
    return await Database.instance.query(
      'SELECT * FROM venda_pagamentos WHERE venda_id = :venda_id ORDER BY id',
      {'venda_id': vendaId.toString()},
    );
  }
}
