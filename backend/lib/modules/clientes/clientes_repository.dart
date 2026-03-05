import '../../config/database.dart';

class ClientesRepository {
  Future<List<Map<String, String?>>> findAll({
    String? busca,
    bool? ativo,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (busca != null && busca.isNotEmpty) {
      where += ' AND (nome LIKE :b1 OR cpf_cnpj LIKE :b2)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
    }

    if (ativo != null) {
      where += ' AND ativo = :ativo';
      params['ativo'] = ativo ? '1' : '0';
    }

    final sql =
        'SELECT * FROM clientes $where ORDER BY nome LIMIT $limit OFFSET $offset';

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
      where += ' AND (nome LIKE :b1 OR cpf_cnpj LIKE :b2)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
    }

    if (ativo != null) {
      where += ' AND ativo = :ativo';
      params['ativo'] = ativo ? '1' : '0';
    }

    final sql = 'SELECT COUNT(*) as total FROM clientes $where';
    final result = await Database.pool.execute(sql, params);
    final row = result.rows.first.assoc();

    return int.parse(row['total'] ?? '0');
  }

  Future<Map<String, String?>?> findById(int id) async {
    final result = await Database.pool.execute(
      'SELECT * FROM clientes WHERE id = :id',
      {'id': id},
    );

    if (result.rows.isEmpty) return null;

    return result.rows.first.assoc();
  }

  Future<Map<String, String?>?> findByCpfCnpj(String cpfCnpj) async {
    final result = await Database.pool.execute(
      'SELECT * FROM clientes WHERE cpf_cnpj = :cpfCnpj AND ativo = 1',
      {'cpfCnpj': cpfCnpj},
    );

    if (result.rows.isEmpty) return null;

    return result.rows.first.assoc();
  }

  Future<int> create(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();

    final sql =
        'INSERT INTO clientes (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';

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

    final sql = 'UPDATE clientes SET ${setClauses.join(', ')} WHERE id = :id';
    await Database.pool.execute(sql, params);
  }

  Future<void> delete(int id) async {
    await Database.pool.execute(
      'UPDATE clientes SET ativo = 0 WHERE id = :id',
      {'id': id},
    );
  }
}
