import '../../config/database.dart';

class ContasReceberRepository {
  Future<List<Map<String, String?>>> findAll({
    String? busca,
    String? status,
    String? filtroVencimento,
    int? clienteId,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (busca != null && busca.isNotEmpty) {
      where += ' AND (cr.descricao LIKE :b1 OR c.nome LIKE :b2)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
    }

    if (status != null && status.isNotEmpty) {
      where += ' AND cr.status = :status';
      params['status'] = status;
    }

    if (clienteId != null) {
      where += ' AND cr.cliente_id = :clienteId';
      params['clienteId'] = clienteId;
    }

    if (filtroVencimento == 'hoje') {
      where += ' AND cr.data_vencimento = CURDATE() AND cr.status = \'pendente\'';
    } else if (filtroVencimento == 'atrasado') {
      where +=
          ' AND cr.data_vencimento < CURDATE() AND cr.status = \'pendente\'';
    } else if (filtroVencimento == 'semana') {
      where +=
          ' AND cr.data_vencimento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) AND cr.status = \'pendente\'';
    }

    final sql = '''
      SELECT cr.*, c.nome as cliente_nome
      FROM contas_receber cr
      LEFT JOIN clientes c ON c.id = cr.cliente_id
      $where
      ORDER BY cr.data_vencimento ASC
      LIMIT $limit OFFSET $offset
    ''';

    final result = await Database.pool.execute(sql, params);
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<int> count({
    String? busca,
    String? status,
    String? filtroVencimento,
    int? clienteId,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (busca != null && busca.isNotEmpty) {
      where += ' AND (cr.descricao LIKE :b1 OR c.nome LIKE :b2)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
    }

    if (status != null && status.isNotEmpty) {
      where += ' AND cr.status = :status';
      params['status'] = status;
    }

    if (clienteId != null) {
      where += ' AND cr.cliente_id = :clienteId';
      params['clienteId'] = clienteId;
    }

    if (filtroVencimento == 'hoje') {
      where += ' AND cr.data_vencimento = CURDATE() AND cr.status = \'pendente\'';
    } else if (filtroVencimento == 'atrasado') {
      where +=
          ' AND cr.data_vencimento < CURDATE() AND cr.status = \'pendente\'';
    } else if (filtroVencimento == 'semana') {
      where +=
          ' AND cr.data_vencimento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) AND cr.status = \'pendente\'';
    }

    final sql = '''
      SELECT COUNT(*) as total
      FROM contas_receber cr
      LEFT JOIN clientes c ON c.id = cr.cliente_id
      $where
    ''';

    final result = await Database.pool.execute(sql, params);
    final row = result.rows.first.assoc();
    return int.parse(row['total'] ?? '0');
  }

  Future<Map<String, String?>?> findById(int id) async {
    final result = await Database.pool.execute(
      '''SELECT cr.*, c.nome as cliente_nome
         FROM contas_receber cr
         LEFT JOIN clientes c ON c.id = cr.cliente_id
         WHERE cr.id = :id''',
      {'id': id},
    );

    if (result.rows.isEmpty) return null;
    return result.rows.first.assoc();
  }

  Future<int> create(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();

    final sql =
        'INSERT INTO contas_receber (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';

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
        'UPDATE contas_receber SET ${setClauses.join(', ')} WHERE id = :id';
    await Database.pool.execute(sql, params);
  }

  Future<void> delete(int id) async {
    await Database.pool.execute(
      'DELETE FROM contas_receber WHERE id = :id',
      {'id': id},
    );
  }

  Future<Map<String, String?>> getTotais({
    int? clienteId,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (clienteId != null) {
      where += ' AND cliente_id = :clienteId';
      params['clienteId'] = clienteId;
    }

    final sql = '''
      SELECT
        COALESCE(SUM(CASE WHEN status = 'pendente' THEN valor ELSE 0 END), 0) as total_pendente,
        COALESCE(SUM(CASE WHEN status = 'recebido' THEN valor ELSE 0 END), 0) as total_recebido,
        COALESCE(SUM(CASE WHEN status = 'pendente' AND data_vencimento < CURDATE() THEN valor ELSE 0 END), 0) as total_atrasado,
        COUNT(CASE WHEN status = 'pendente' THEN 1 END) as qtd_pendente,
        COUNT(CASE WHEN status = 'pendente' AND data_vencimento < CURDATE() THEN 1 END) as qtd_atrasado,
        COUNT(CASE WHEN status = 'pendente' AND data_vencimento = CURDATE() THEN 1 END) as qtd_vencendo_hoje
      FROM contas_receber
      $where
    ''';

    final result = await Database.pool.execute(sql, params);
    return result.rows.first.assoc();
  }
}
