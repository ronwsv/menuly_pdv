import '../../config/database.dart';

class FornecedoresRepository {
  Future<List<Map<String, String?>>> findAll({
    String? busca,
    bool? ativo,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (busca != null && busca.isNotEmpty) {
      where +=
          ' AND (razao_social LIKE :b1 OR nome_fantasia LIKE :b2 OR cnpj LIKE :b3)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
      params['b3'] = '%$busca%';
    }

    if (ativo != null) {
      where += ' AND ativo = :ativo';
      params['ativo'] = ativo ? '1' : '0';
    }

    final sql =
        'SELECT * FROM fornecedores $where ORDER BY razao_social LIMIT $limit OFFSET $offset';

    final result = await Database.pool.execute(sql, params);
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<int> count({
    String? busca,
    bool? ativo,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (busca != null && busca.isNotEmpty) {
      where +=
          ' AND (razao_social LIKE :b1 OR nome_fantasia LIKE :b2 OR cnpj LIKE :b3)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
      params['b3'] = '%$busca%';
    }

    if (ativo != null) {
      where += ' AND ativo = :ativo';
      params['ativo'] = ativo ? '1' : '0';
    }

    final sql = 'SELECT COUNT(*) as total FROM fornecedores $where';
    final result = await Database.pool.execute(sql, params);
    final row = result.rows.first.assoc();

    return int.parse(row['total'] ?? '0');
  }

  Future<Map<String, String?>?> findById(int id) async {
    final result = await Database.pool.execute(
      'SELECT * FROM fornecedores WHERE id = :id',
      {'id': id.toString()},
    );

    if (result.rows.isEmpty) return null;

    return result.rows.first.assoc();
  }

  Future<Map<String, String?>?> findByCnpj(String cnpj) async {
    final result = await Database.pool.execute(
      'SELECT * FROM fornecedores WHERE cnpj = :cnpj',
      {'cnpj': cnpj},
    );

    if (result.rows.isEmpty) return null;

    return result.rows.first.assoc();
  }

  Future<int> create(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();

    final sql =
        'INSERT INTO fornecedores (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';

    final result = await Database.pool.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    if (data.isEmpty) return;

    final setClauses = <String>[];
    final params = <String, dynamic>{'id': id.toString()};

    data.forEach((key, value) {
      setClauses.add('$key = :$key');
      params[key] = value?.toString() ?? '';
    });

    final sql =
        'UPDATE fornecedores SET ${setClauses.join(', ')} WHERE id = :id';
    await Database.pool.execute(sql, params);
  }

  Future<void> delete(int id) async {
    await Database.pool.execute(
      'UPDATE fornecedores SET ativo = 0 WHERE id = :id',
      {'id': id.toString()},
    );
  }

  Future<bool> existsByCnpj(String cnpj, {int? excludeId}) async {
    String sql =
        'SELECT COUNT(*) as total FROM fornecedores WHERE cnpj = :cnpj AND ativo = 1';
    final params = <String, dynamic>{'cnpj': cnpj};

    if (excludeId != null) {
      sql += ' AND id != :excludeId';
      params['excludeId'] = excludeId.toString();
    }

    final result = await Database.pool.execute(sql, params);
    final row = result.rows.first.assoc();

    return int.parse(row['total']!) > 0;
  }
}
