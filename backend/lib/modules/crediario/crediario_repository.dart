import '../../config/database.dart';

class CrediarioRepository {
  Future<List<Map<String, String?>>> findAll({
    String? busca,
    String? status,
    int? clienteId,
    int? vendaId,
    String? filtroVencimento,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (busca != null && busca.isNotEmpty) {
      where += ' AND (c.nome LIKE :b1 OR v.numero LIKE :b2)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
    }

    if (status != null && status.isNotEmpty) {
      where += ' AND cp.status = :status';
      params['status'] = status;
    }

    if (clienteId != null) {
      where += ' AND cp.cliente_id = :clienteId';
      params['clienteId'] = clienteId;
    }

    if (vendaId != null) {
      where += ' AND cp.venda_id = :vendaId';
      params['vendaId'] = vendaId;
    }

    if (filtroVencimento == 'hoje') {
      where +=
          ' AND cp.data_vencimento = CURDATE() AND cp.status = \'pendente\'';
    } else if (filtroVencimento == 'atrasado') {
      where +=
          ' AND cp.data_vencimento < CURDATE() AND cp.status = \'pendente\'';
    } else if (filtroVencimento == 'semana') {
      where +=
          ' AND cp.data_vencimento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) AND cp.status = \'pendente\'';
    }

    final sql = '''
      SELECT cp.*, c.nome as cliente_nome, v.numero as venda_numero
      FROM crediario_parcelas cp
      LEFT JOIN clientes c ON c.id = cp.cliente_id
      LEFT JOIN vendas v ON v.id = cp.venda_id
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
    int? clienteId,
    String? filtroVencimento,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (busca != null && busca.isNotEmpty) {
      where += ' AND (c.nome LIKE :b1 OR v.numero LIKE :b2)';
      params['b1'] = '%$busca%';
      params['b2'] = '%$busca%';
    }

    if (status != null && status.isNotEmpty) {
      where += ' AND cp.status = :status';
      params['status'] = status;
    }

    if (clienteId != null) {
      where += ' AND cp.cliente_id = :clienteId';
      params['clienteId'] = clienteId;
    }

    if (filtroVencimento == 'hoje') {
      where +=
          ' AND cp.data_vencimento = CURDATE() AND cp.status = \'pendente\'';
    } else if (filtroVencimento == 'atrasado') {
      where +=
          ' AND cp.data_vencimento < CURDATE() AND cp.status = \'pendente\'';
    } else if (filtroVencimento == 'semana') {
      where +=
          ' AND cp.data_vencimento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) AND cp.status = \'pendente\'';
    }

    final sql = '''
      SELECT COUNT(*) as total
      FROM crediario_parcelas cp
      LEFT JOIN clientes c ON c.id = cp.cliente_id
      LEFT JOIN vendas v ON v.id = cp.venda_id
      $where
    ''';

    final result = await Database.pool.execute(sql, params);
    final row = result.rows.first.assoc();
    return int.parse(row['total'] ?? '0');
  }

  Future<Map<String, String?>?> findById(int id) async {
    final result = await Database.pool.execute(
      '''SELECT cp.*, c.nome as cliente_nome, v.numero as venda_numero
         FROM crediario_parcelas cp
         LEFT JOIN clientes c ON c.id = cp.cliente_id
         LEFT JOIN vendas v ON v.id = cp.venda_id
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
        'INSERT INTO crediario_parcelas (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';

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
        'UPDATE crediario_parcelas SET ${setClauses.join(', ')} WHERE id = :id';
    await Database.pool.execute(sql, params);
  }

  Future<Map<String, String?>> getTotais({int? clienteId}) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (clienteId != null) {
      where += ' AND cliente_id = :clienteId';
      params['clienteId'] = clienteId;
    }

    final sql = '''
      SELECT
        COALESCE(SUM(CASE WHEN status = 'pendente' THEN valor ELSE 0 END), 0) as total_pendente,
        COALESCE(SUM(CASE WHEN status = 'pago' THEN valor ELSE 0 END), 0) as total_pago,
        COALESCE(SUM(CASE WHEN status = 'pendente' AND data_vencimento < CURDATE() THEN valor ELSE 0 END), 0) as total_atrasado,
        COUNT(CASE WHEN status = 'pendente' THEN 1 END) as qtd_pendente,
        COUNT(CASE WHEN status = 'pago' THEN 1 END) as qtd_pago,
        COUNT(CASE WHEN status = 'pendente' AND data_vencimento < CURDATE() THEN 1 END) as qtd_atrasado
      FROM crediario_parcelas
      $where
    ''';

    final result = await Database.pool.execute(sql, params);
    return result.rows.first.assoc();
  }

  Future<Map<String, String?>?> getCliente(int clienteId) async {
    final result = await Database.pool.execute(
      'SELECT id, nome, limite_credito FROM clientes WHERE id = :id',
      {'id': clienteId},
    );
    if (result.rows.isEmpty) return null;
    return result.rows.first.assoc();
  }

  Future<double> getSaldoDevedorCliente(int clienteId) async {
    final result = await Database.pool.execute(
      '''SELECT COALESCE(SUM(valor), 0) as total
         FROM crediario_parcelas
         WHERE cliente_id = :clienteId AND status = 'pendente' ''',
      {'clienteId': clienteId},
    );
    final row = result.rows.first.assoc();
    return double.parse(row['total'] ?? '0');
  }

  Future<bool> clienteTemParcelasAtrasadas(int clienteId) async {
    final result = await Database.pool.execute(
      '''SELECT COUNT(*) as total
         FROM crediario_parcelas
         WHERE cliente_id = :clienteId
         AND status = 'pendente'
         AND data_vencimento < CURDATE()''',
      {'clienteId': clienteId},
    );
    final row = result.rows.first.assoc();
    return int.parse(row['total'] ?? '0') > 0;
  }

  Future<void> cancelarParcelasVenda(int vendaId) async {
    await Database.pool.execute(
      '''UPDATE crediario_parcelas
         SET status = 'cancelado'
         WHERE venda_id = :vendaId AND status = 'pendente' ''',
      {'vendaId': vendaId},
    );
  }
}
