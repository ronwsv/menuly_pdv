import '../../config/database.dart';

class ServicosRepository {
  Future<List<Map<String, String?>>> findAll({
    String? busca,
    bool? ativo,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (busca != null && busca.isNotEmpty) {
      where += ' AND descricao LIKE :busca';
      params['busca'] = '%$busca%';
    }

    if (ativo != null) {
      where += ' AND ativo = :ativo';
      params['ativo'] = ativo ? 1 : 0;
    }

    final sql = '''
      SELECT * FROM servicos
      $where
      ORDER BY descricao ASC
      LIMIT $limit OFFSET $offset
    ''';

    final result = await Database.pool.execute(sql, params);
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<int> count({
    String? busca,
    bool? ativo,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (busca != null && busca.isNotEmpty) {
      where += ' AND descricao LIKE :busca';
      params['busca'] = '%$busca%';
    }

    if (ativo != null) {
      where += ' AND ativo = :ativo';
      params['ativo'] = ativo ? 1 : 0;
    }

    final sql = '''
      SELECT COUNT(*) as total FROM servicos
      $where
    ''';

    final result = await Database.pool.execute(sql, params);
    final row = result.rows.first.assoc();
    return int.parse(row['total'] ?? '0');
  }

  Future<Map<String, String?>?> findById(int id) async {
    final result = await Database.pool.execute(
      'SELECT * FROM servicos WHERE id = :id',
      {'id': id},
    );

    if (result.rows.isEmpty) return null;
    return result.rows.first.assoc();
  }

  Future<int> create(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();

    final sql =
        'INSERT INTO servicos (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';

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
        'UPDATE servicos SET ${setClauses.join(', ')} WHERE id = :id';
    await Database.pool.execute(sql, params);
  }

  Future<void> delete(int id) async {
    await Database.pool.execute(
      'DELETE FROM servicos WHERE id = :id',
      {'id': id},
    );
  }
}
