import '../../config/database.dart';

class OrdensServicoRepository {
  Future<List<Map<String, String?>>> findAll({
    String? busca,
    String? status,
    int? clienteId,
    int? prestadorId,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (busca != null && busca.isNotEmpty) {
      where += ' AND (os.numero LIKE :b1 OR c.nome LIKE :b2 OR os.pedido LIKE :b3)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
      params['b3'] = '%$busca%';
    }

    if (status != null && status.isNotEmpty) {
      where += ' AND os.status = :status';
      params['status'] = status;
    }

    if (clienteId != null) {
      where += ' AND os.cliente_id = :clienteId';
      params['clienteId'] = clienteId;
    }

    if (prestadorId != null) {
      where += ' AND os.prestador_id = :prestadorId';
      params['prestadorId'] = prestadorId;
    }

    final sql = '''
      SELECT os.*, c.nome as cliente_nome, u.nome as prestador_nome
      FROM ordens_servico os
      LEFT JOIN clientes c ON c.id = os.cliente_id
      LEFT JOIN usuarios u ON u.id = os.prestador_id
      $where
      ORDER BY os.criado_em DESC
      LIMIT $limit OFFSET $offset
    ''';

    final result = await Database.pool.execute(sql, params);
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<int> count({
    String? busca,
    String? status,
    int? clienteId,
    int? prestadorId,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (busca != null && busca.isNotEmpty) {
      where += ' AND (os.numero LIKE :b1 OR c.nome LIKE :b2 OR os.pedido LIKE :b3)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
      params['b3'] = '%$busca%';
    }

    if (status != null && status.isNotEmpty) {
      where += ' AND os.status = :status';
      params['status'] = status;
    }

    if (clienteId != null) {
      where += ' AND os.cliente_id = :clienteId';
      params['clienteId'] = clienteId;
    }

    if (prestadorId != null) {
      where += ' AND os.prestador_id = :prestadorId';
      params['prestadorId'] = prestadorId;
    }

    final sql = '''
      SELECT COUNT(*) as total
      FROM ordens_servico os
      LEFT JOIN clientes c ON c.id = os.cliente_id
      $where
    ''';

    final result = await Database.pool.execute(sql, params);
    final row = result.rows.first.assoc();
    return int.parse(row['total'] ?? '0');
  }

  Future<Map<String, String?>?> findById(int id) async {
    final result = await Database.pool.execute(
      '''SELECT os.*, c.nome as cliente_nome, u.nome as prestador_nome
         FROM ordens_servico os
         LEFT JOIN clientes c ON c.id = os.cliente_id
         LEFT JOIN usuarios u ON u.id = os.prestador_id
         WHERE os.id = :id''',
      {'id': id},
    );

    if (result.rows.isEmpty) return null;
    return result.rows.first.assoc();
  }

  Future<int> create(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();

    final sql =
        'INSERT INTO ordens_servico (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';

    final result = await Database.pool.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    if (data.isEmpty) return;

    final setClauses = <String>[];
    final params = <String, dynamic>{'id': id};

    data.forEach((key, value) {
      setClauses.add('$key = :$key');
      params[key] = value;
    });

    final sql =
        'UPDATE ordens_servico SET ${setClauses.join(', ')} WHERE id = :id';
    await Database.pool.execute(sql, params);
  }

  Future<void> delete(int id) async {
    await Database.pool.execute(
      'DELETE FROM os_itens_servico WHERE ordem_servico_id = :id',
      {'id': id},
    );
    await Database.pool.execute(
      'DELETE FROM os_itens_produto WHERE ordem_servico_id = :id',
      {'id': id},
    );
    await Database.pool.execute(
      'DELETE FROM ordens_servico WHERE id = :id',
      {'id': id},
    );
  }

  // ── Itens Servico ──

  Future<List<Map<String, String?>>> findItensServico(int osId) async {
    final result = await Database.pool.execute(
      '''SELECT ois.*, s.descricao as servico_descricao
         FROM os_itens_servico ois
         LEFT JOIN servicos s ON s.id = ois.servico_id
         WHERE ois.ordem_servico_id = :osId
         ORDER BY ois.id''',
      {'osId': osId},
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<int> addItemServico(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();

    final sql =
        'INSERT INTO os_itens_servico (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';

    final result = await Database.pool.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<void> removeItemServico(int itemId) async {
    await Database.pool.execute(
      'DELETE FROM os_itens_servico WHERE id = :id',
      {'id': itemId},
    );
  }

  // ── Itens Produto ──

  Future<List<Map<String, String?>>> findItensProduto(int osId) async {
    final result = await Database.pool.execute(
      '''SELECT oip.*, p.descricao as produto_descricao
         FROM os_itens_produto oip
         LEFT JOIN produtos p ON p.id = oip.produto_id
         WHERE oip.ordem_servico_id = :osId
         ORDER BY oip.id''',
      {'osId': osId},
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<int> addItemProduto(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();

    final sql =
        'INSERT INTO os_itens_produto (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';

    final result = await Database.pool.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<void> removeItemProduto(int itemId) async {
    await Database.pool.execute(
      'DELETE FROM os_itens_produto WHERE id = :id',
      {'id': itemId},
    );
  }

  // ── Gerar numero sequencial ──

  Future<String> gerarNumero() async {
    final now = DateTime.now();
    final prefix =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final result = await Database.pool.execute(
      "SELECT COUNT(*) as total FROM ordens_servico WHERE numero LIKE :prefix",
      {'prefix': '$prefix%'},
    );
    final row = result.rows.first.assoc();
    final seq = int.parse(row['total'] ?? '0') + 1;
    return '$prefix${seq.toString().padLeft(4, '0')}';
  }
}
