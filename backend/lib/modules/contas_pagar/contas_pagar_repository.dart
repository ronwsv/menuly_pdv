import '../../config/database.dart';

class ContasPagarRepository {
  Future<List<Map<String, String?>>> findAll({
    String? busca,
    String? status,
    String? filtroVencimento,
    int? fornecedorId,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (busca != null && busca.isNotEmpty) {
      where += ' AND (cp.descricao LIKE :b1 OR COALESCE(f.nome_fantasia, f.razao_social) LIKE :b2)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
    }

    if (status != null && status.isNotEmpty) {
      where += ' AND cp.status = :status';
      params['status'] = status;
    }

    if (fornecedorId != null) {
      where += ' AND cp.fornecedor_id = :fornecedorId';
      params['fornecedorId'] = fornecedorId;
    }

    if (filtroVencimento == 'hoje') {
      where += ' AND cp.data_vencimento = CURDATE() AND cp.status = \'pendente\'';
    } else if (filtroVencimento == 'atrasado') {
      where +=
          ' AND cp.data_vencimento < CURDATE() AND cp.status = \'pendente\'';
    } else if (filtroVencimento == 'semana') {
      where +=
          ' AND cp.data_vencimento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) AND cp.status = \'pendente\'';
    }

    final sql = '''
      SELECT cp.*, COALESCE(f.nome_fantasia, f.razao_social) as fornecedor_nome
      FROM contas_pagar cp
      LEFT JOIN fornecedores f ON f.id = cp.fornecedor_id
      $where
      ORDER BY cp.data_vencimento ASC
      LIMIT $limit OFFSET $offset
    ''';

    final result = await Database.pool.execute(sql, params);
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<int> count({
    String? busca,
    String? status,
    String? filtroVencimento,
    int? fornecedorId,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (busca != null && busca.isNotEmpty) {
      where += ' AND (cp.descricao LIKE :b1 OR COALESCE(f.nome_fantasia, f.razao_social) LIKE :b2)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
    }

    if (status != null && status.isNotEmpty) {
      where += ' AND cp.status = :status';
      params['status'] = status;
    }

    if (fornecedorId != null) {
      where += ' AND cp.fornecedor_id = :fornecedorId';
      params['fornecedorId'] = fornecedorId;
    }

    if (filtroVencimento == 'hoje') {
      where += ' AND cp.data_vencimento = CURDATE() AND cp.status = \'pendente\'';
    } else if (filtroVencimento == 'atrasado') {
      where +=
          ' AND cp.data_vencimento < CURDATE() AND cp.status = \'pendente\'';
    } else if (filtroVencimento == 'semana') {
      where +=
          ' AND cp.data_vencimento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) AND cp.status = \'pendente\'';
    }

    final sql = '''
      SELECT COUNT(*) as total
      FROM contas_pagar cp
      LEFT JOIN fornecedores f ON f.id = cp.fornecedor_id
      $where
    ''';

    final result = await Database.pool.execute(sql, params);
    final row = result.rows.first.assoc();
    return int.parse(row['total'] ?? '0');
  }

  Future<Map<String, String?>?> findById(int id) async {
    final result = await Database.pool.execute(
      '''SELECT cp.*, COALESCE(f.nome_fantasia, f.razao_social) as fornecedor_nome
         FROM contas_pagar cp
         LEFT JOIN fornecedores f ON f.id = cp.fornecedor_id
         WHERE cp.id = :id''',
      {'id': id},
    );

    if (result.rows.isEmpty) return null;
    return result.rows.first.assoc();
  }

  Future<int> create(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();

    final sql =
        'INSERT INTO contas_pagar (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';

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
        'UPDATE contas_pagar SET ${setClauses.join(', ')} WHERE id = :id';
    await Database.pool.execute(sql, params);
  }

  Future<void> delete(int id) async {
    await Database.pool.execute(
      'DELETE FROM contas_pagar WHERE id = :id',
      {'id': id},
    );
  }

  Future<Map<String, String?>> getTotais({
    int? fornecedorId,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (fornecedorId != null) {
      where += ' AND fornecedor_id = :fornecedorId';
      params['fornecedorId'] = fornecedorId;
    }

    final sql = '''
      SELECT
        COALESCE(SUM(CASE WHEN status = 'pendente' THEN valor ELSE 0 END), 0) as total_pendente,
        COALESCE(SUM(CASE WHEN status = 'pago' THEN valor ELSE 0 END), 0) as total_pago,
        COALESCE(SUM(CASE WHEN status = 'pendente' AND data_vencimento < CURDATE() THEN valor ELSE 0 END), 0) as total_atrasado,
        COUNT(CASE WHEN status = 'pendente' THEN 1 END) as qtd_pendente,
        COUNT(CASE WHEN status = 'pendente' AND data_vencimento < CURDATE() THEN 1 END) as qtd_atrasado,
        COUNT(CASE WHEN status = 'pendente' AND data_vencimento = CURDATE() THEN 1 END) as qtd_vencendo_hoje
      FROM contas_pagar
      $where
    ''';

    final result = await Database.pool.execute(sql, params);
    return result.rows.first.assoc();
  }
}
