import '../../config/database.dart';

import 'produto_model.dart';

class ProdutosRepository {

  Future<List<Produto>> findAll({
    String? busca,
    int? categoriaId,
    bool? ativo,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (busca != null && busca.isNotEmpty) {
      where +=
          ' AND (p.descricao LIKE :b1 OR p.codigo_barras LIKE :b2 OR p.codigo_interno LIKE :b3)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
      params['b3'] = '%$busca%';
    }

    if (categoriaId != null) {
      where += ' AND p.categoria_id = :cat';
      params['cat'] = categoriaId.toString();
    }

    if (ativo != null) {
      where += ' AND p.ativo = :ativo';
      params['ativo'] = ativo ? '1' : '0';
    }

    final sql =
        'SELECT p.*, c.nome AS categoria_nome, f.razao_social AS fornecedor_nome '
        'FROM produtos p '
        'LEFT JOIN categorias c ON p.categoria_id = c.id '
        'LEFT JOIN fornecedores f ON p.fornecedor_id = f.id '
        '$where ORDER BY p.descricao LIMIT $limit OFFSET $offset';

    final results = await Database.instance.query(sql, params);
    return results.map((row) => Produto.fromRow(row)).toList();
  }

  Future<int> count({
    String? busca,
    int? categoriaId,
    bool? ativo,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (busca != null && busca.isNotEmpty) {
      where +=
          ' AND (descricao LIKE :b1 OR codigo_barras LIKE :b2 OR codigo_interno LIKE :b3)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
      params['b3'] = '%$busca%';
    }

    if (categoriaId != null) {
      where += ' AND categoria_id = :cat';
      params['cat'] = categoriaId.toString();
    }

    if (ativo != null) {
      where += ' AND ativo = :ativo';
      params['ativo'] = ativo ? '1' : '0';
    }

    final sql = 'SELECT COUNT(*) as total FROM produtos $where';
    final results = await Database.instance.query(sql, params);

    if (results.isEmpty) return 0;
    return int.parse(results.first['total'] ?? '0');
  }

  Future<Produto?> findById(int id) async {
    final results = await Database.instance.query(
      'SELECT p.*, c.nome AS categoria_nome, f.razao_social AS fornecedor_nome '
      'FROM produtos p '
      'LEFT JOIN categorias c ON p.categoria_id = c.id '
      'LEFT JOIN fornecedores f ON p.fornecedor_id = f.id '
      'WHERE p.id = :id',
      {'id': id.toString()},
    );

    if (results.isEmpty) return null;
    return Produto.fromRow(results.first);
  }

  Future<Produto?> findByBarcode(String codigo) async {
    final results = await Database.instance.query(
      'SELECT p.*, c.nome AS categoria_nome, f.razao_social AS fornecedor_nome '
      'FROM produtos p '
      'LEFT JOIN categorias c ON p.categoria_id = c.id '
      'LEFT JOIN fornecedores f ON p.fornecedor_id = f.id '
      'WHERE p.codigo_barras = :codigo',
      {'codigo': codigo},
    );

    if (results.isEmpty) return null;
    return Produto.fromRow(results.first);
  }

  Future<Produto?> findByCodigoInterno(String codigo) async {
    final results = await Database.instance.query(
      'SELECT p.*, c.nome AS categoria_nome, f.razao_social AS fornecedor_nome '
      'FROM produtos p '
      'LEFT JOIN categorias c ON p.categoria_id = c.id '
      'LEFT JOIN fornecedores f ON p.fornecedor_id = f.id '
      'WHERE p.codigo_interno = :codigo',
      {'codigo': codigo},
    );

    if (results.isEmpty) return null;
    return Produto.fromRow(results.first);
  }

  Future<int> create(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();

    final sql =
        'INSERT INTO produtos (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';

    final result = await Database.instance.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<void> update(int id, Map<String, String> data) async {
    final setClauses = data.keys.map((k) => '$k = :$k').toList();
    final params = Map<String, String>.from(data);
    params['id'] = id.toString();

    final sql =
        'UPDATE produtos SET ${setClauses.join(', ')} WHERE id = :id';

    await Database.instance.execute(sql, params);
  }

  Future<int> updateEstoqueMinimoAll(int valor) async {
    final result = await Database.instance.execute(
      'UPDATE produtos SET estoque_minimo = :valor WHERE ativo = 1',
      {'valor': valor.toString()},
    );
    return result.affectedRows.toInt();
  }

  Future<List<Produto>> findAllAtivos() async {
    final results = await Database.instance.query(
      'SELECT * FROM produtos WHERE ativo = 1',
      {},
    );
    return results.map((row) => Produto.fromRow(row)).toList();
  }

  Future<List<Map<String, String?>>> rankingGeral({int limit = 20}) async {
    final results = await Database.instance.query(
      'SELECT p.id, p.descricao, p.categoria_id, p.preco_venda, '
      'SUM(vi.quantidade) as total_quantidade, '
      'SUM(vi.subtotal) as total_faturamento '
      'FROM venda_itens vi '
      'JOIN produtos p ON vi.produto_id = p.id '
      'JOIN vendas v ON vi.venda_id = v.id '
      'WHERE v.status = :status '
      'GROUP BY p.id, p.descricao, p.categoria_id, p.preco_venda '
      'ORDER BY total_quantidade DESC '
      'LIMIT $limit',
      {'status': 'finalizada'},
    );
    return results;
  }

  Future<List<Map<String, String?>>> rankingPorData({
    required String dataInicio,
    required String dataFim,
    int limit = 20,
  }) async {
    final results = await Database.instance.query(
      'SELECT p.id, p.descricao, p.categoria_id, p.preco_venda, '
      'SUM(vi.quantidade) as total_quantidade, '
      'SUM(vi.subtotal) as total_faturamento '
      'FROM venda_itens vi '
      'JOIN produtos p ON vi.produto_id = p.id '
      'JOIN vendas v ON vi.venda_id = v.id '
      'WHERE v.status = :status '
      'AND v.criado_em >= :data_inicio '
      'AND v.criado_em <= :data_fim '
      'GROUP BY p.id, p.descricao, p.categoria_id, p.preco_venda '
      'ORDER BY total_quantidade DESC '
      'LIMIT $limit',
      {
        'status': 'finalizada',
        'data_inicio': dataInicio,
        'data_fim': dataFim,
      },
    );
    return results;
  }
}
