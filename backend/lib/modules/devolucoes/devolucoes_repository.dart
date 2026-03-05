import '../../config/database.dart';

class DevolucoesRepository {
  // ── Devoluções ──

  Future<List<Map<String, String?>>> findAll({
    String? tipo,
    String? status,
    int? clienteId,
    int? vendaId,
    String? dataInicio,
    String? dataFim,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (tipo != null && tipo.isNotEmpty) {
      where += ' AND d.tipo = :tipo';
      params['tipo'] = tipo;
    }
    if (status != null && status.isNotEmpty) {
      where += ' AND d.status = :status';
      params['status'] = status;
    }
    if (clienteId != null) {
      where += ' AND d.cliente_id = :clienteId';
      params['clienteId'] = clienteId;
    }
    if (vendaId != null) {
      where += ' AND d.venda_id = :vendaId';
      params['vendaId'] = vendaId;
    }
    if (dataInicio != null && dataInicio.isNotEmpty) {
      where += ' AND d.data_devolucao >= :dataInicio';
      params['dataInicio'] = dataInicio;
    }
    if (dataFim != null && dataFim.isNotEmpty) {
      where += ' AND d.data_devolucao <= :dataFim';
      params['dataFim'] = '$dataFim 23:59:59';
    }

    final sql = '''
      SELECT d.*, c.nome as cliente_nome, u.nome as usuario_nome,
             v.numero as venda_numero
      FROM devolucoes d
      LEFT JOIN clientes c ON c.id = d.cliente_id
      LEFT JOIN usuarios u ON u.id = d.usuario_id
      LEFT JOIN vendas v ON v.id = d.venda_id
      $where
      ORDER BY d.data_devolucao DESC
      LIMIT $limit OFFSET $offset
    ''';

    final result = await Database.pool.execute(sql, params);
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<int> count({
    String? tipo,
    String? status,
    int? clienteId,
    int? vendaId,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (tipo != null && tipo.isNotEmpty) {
      where += ' AND d.tipo = :tipo';
      params['tipo'] = tipo;
    }
    if (status != null && status.isNotEmpty) {
      where += ' AND d.status = :status';
      params['status'] = status;
    }
    if (clienteId != null) {
      where += ' AND d.cliente_id = :clienteId';
      params['clienteId'] = clienteId;
    }
    if (vendaId != null) {
      where += ' AND d.venda_id = :vendaId';
      params['vendaId'] = vendaId;
    }

    final sql = '''
      SELECT COUNT(*) as total
      FROM devolucoes d
      $where
    ''';

    final result = await Database.pool.execute(sql, params);
    return int.parse(result.rows.first.assoc()['total'] ?? '0');
  }

  Future<Map<String, String?>?> findById(int id) async {
    final result = await Database.pool.execute(
      '''SELECT d.*, c.nome as cliente_nome, u.nome as usuario_nome,
                v.numero as venda_numero
         FROM devolucoes d
         LEFT JOIN clientes c ON c.id = d.cliente_id
         LEFT JOIN usuarios u ON u.id = d.usuario_id
         LEFT JOIN vendas v ON v.id = d.venda_id
         WHERE d.id = :id''',
      {'id': id},
    );
    if (result.rows.isEmpty) return null;
    return result.rows.first.assoc();
  }

  Future<int> create(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();

    final sql =
        'INSERT INTO devolucoes (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    final result = await Database.pool.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<void> updateStatus(int id, String status) async {
    await Database.pool.execute(
      'UPDATE devolucoes SET status = :status WHERE id = :id',
      {'id': id, 'status': status},
    );
  }

  Future<void> updateCreditoGerado(int id, double credito) async {
    await Database.pool.execute(
      'UPDATE devolucoes SET credito_gerado = :credito WHERE id = :id',
      {'id': id, 'credito': credito.toStringAsFixed(2)},
    );
  }

  // ── Itens da Devolução ──

  Future<List<Map<String, String?>>> findItensByDevolucaoId(
      int devolucaoId) async {
    final result = await Database.pool.execute(
      '''SELECT di.*, p.descricao as produto_descricao
         FROM devolucao_itens di
         LEFT JOIN produtos p ON p.id = di.produto_id
         WHERE di.devolucao_id = :devolucaoId''',
      {'devolucaoId': devolucaoId},
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<int> createItem(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();

    final sql =
        'INSERT INTO devolucao_itens (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    final result = await Database.pool.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  // ── Venda (para consultar dados da venda original) ──

  Future<Map<String, String?>?> getVenda(int vendaId) async {
    final result = await Database.pool.execute(
      '''SELECT v.*, c.nome as cliente_nome
         FROM vendas v
         LEFT JOIN clientes c ON c.id = v.cliente_id
         WHERE v.id = :id''',
      {'id': vendaId},
    );
    if (result.rows.isEmpty) return null;
    return result.rows.first.assoc();
  }

  Future<List<Map<String, String?>>> getItensVenda(int vendaId) async {
    final result = await Database.pool.execute(
      '''SELECT vi.*, p.descricao as produto_descricao
         FROM venda_itens vi
         LEFT JOIN produtos p ON p.id = vi.produto_id
         WHERE vi.venda_id = :vendaId''',
      {'vendaId': vendaId},
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  /// Busca venda por número para facilitar localização
  Future<Map<String, String?>?> getVendaByNumero(String numero) async {
    final result = await Database.pool.execute(
      '''SELECT v.*, c.nome as cliente_nome
         FROM vendas v
         LEFT JOIN clientes c ON c.id = v.cliente_id
         WHERE v.numero = :numero''',
      {'numero': numero},
    );
    if (result.rows.isEmpty) return null;
    return result.rows.first.assoc();
  }

  /// Busca vendas finalizadas por valor total
  Future<List<Map<String, String?>>> getVendasByValor(
    double valor, {
    double tolerancia = 0.01,
  }) async {
    final result = await Database.pool.execute(
      '''SELECT v.id, v.numero, v.total as valor_total, v.criado_em,
                c.nome as cliente_nome,
                (SELECT COUNT(*) FROM venda_itens vi WHERE vi.venda_id = v.id) as qtd_itens
         FROM vendas v
         LEFT JOIN clientes c ON c.id = v.cliente_id
         WHERE v.status = 'finalizada'
         AND v.total BETWEEN :valorMin AND :valorMax
         ORDER BY v.criado_em DESC
         LIMIT 20''',
      {
        'valorMin': (valor - tolerancia).toStringAsFixed(2),
        'valorMax': (valor + tolerancia).toStringAsFixed(2),
      },
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  /// Verifica quantidade já devolvida de um item da venda
  Future<double> getQuantidadeDevolvida(int vendaId, int produtoId) async {
    final result = await Database.pool.execute(
      '''SELECT COALESCE(SUM(di.quantidade), 0) as total
         FROM devolucao_itens di
         INNER JOIN devolucoes d ON d.id = di.devolucao_id
         WHERE d.venda_id = :vendaId
         AND di.produto_id = :produtoId
         AND d.status != 'recusada' ''',
      {'vendaId': vendaId, 'produtoId': produtoId},
    );
    return double.parse(result.rows.first.assoc()['total'] ?? '0');
  }

  // ── Estoque ──

  Future<void> adicionarEstoque(int produtoId, int quantidade) async {
    await Database.pool.execute(
      'UPDATE produtos SET estoque_atual = estoque_atual + :qtd WHERE id = :id',
      {'id': produtoId, 'qtd': quantidade},
    );
  }

  Future<void> registrarHistoricoEstoque(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO historico_estoque (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    await Database.pool.execute(sql, data);
  }

  // ── Caixa ──

  Future<void> registrarMovimentoCaixa(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO caixa_movimentos (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    await Database.pool.execute(sql, data);
  }

  Future<void> atualizarSaldoCaixa(int caixaId, double valor) async {
    await Database.pool.execute(
      'UPDATE caixas SET saldo_atual = saldo_atual + :valor WHERE id = :id',
      {'id': caixaId, 'valor': valor.toStringAsFixed(2)},
    );
  }

  // ── Customer Credits ──

  Future<int> createCredit(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO customer_credits (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    final result = await Database.pool.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<List<Map<String, String?>>> findCredits({
    int? clienteId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (clienteId != null) {
      where += ' AND cc.cliente_id = :clienteId';
      params['clienteId'] = clienteId;
    }
    if (status != null && status.isNotEmpty) {
      where += ' AND cc.status = :status';
      params['status'] = status;
    }

    final sql = '''
      SELECT cc.*, c.nome as cliente_nome
      FROM customer_credits cc
      LEFT JOIN clientes c ON c.id = cc.cliente_id
      $where
      ORDER BY cc.criado_em DESC
      LIMIT $limit OFFSET $offset
    ''';

    final result = await Database.pool.execute(sql, params);
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<int> countCredits({int? clienteId, String? status}) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (clienteId != null) {
      where += ' AND cc.cliente_id = :clienteId';
      params['clienteId'] = clienteId;
    }
    if (status != null && status.isNotEmpty) {
      where += ' AND cc.status = :status';
      params['status'] = status;
    }

    final sql = 'SELECT COUNT(*) as total FROM customer_credits cc $where';
    final result = await Database.pool.execute(sql, params);
    return int.parse(result.rows.first.assoc()['total'] ?? '0');
  }

  Future<Map<String, String?>?> findCreditById(int id) async {
    final result = await Database.pool.execute(
      '''SELECT cc.*, c.nome as cliente_nome
         FROM customer_credits cc
         LEFT JOIN clientes c ON c.id = cc.cliente_id
         WHERE cc.id = :id''',
      {'id': id},
    );
    if (result.rows.isEmpty) return null;
    return result.rows.first.assoc();
  }

  Future<double> getSaldoCreditosCliente(int clienteId) async {
    final result = await Database.pool.execute(
      '''SELECT COALESCE(SUM(saldo), 0) as total
         FROM customer_credits
         WHERE cliente_id = :clienteId AND status = 'ativo' ''',
      {'clienteId': clienteId},
    );
    return double.parse(result.rows.first.assoc()['total'] ?? '0');
  }

  Future<List<Map<String, String?>>> getCreditosAtivosCliente(
      int clienteId) async {
    final result = await Database.pool.execute(
      '''SELECT cc.*, c.nome as cliente_nome
         FROM customer_credits cc
         LEFT JOIN clientes c ON c.id = cc.cliente_id
         WHERE cc.cliente_id = :clienteId AND cc.status = 'ativo'
         ORDER BY cc.criado_em ASC''',
      {'clienteId': clienteId},
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<void> updateCredit(int id, Map<String, dynamic> data) async {
    if (data.isEmpty) return;
    final setClauses = <String>[];
    final params = <String, dynamic>{'id': id};

    data.forEach((key, value) {
      setClauses.add('$key = :$key');
      params[key] = value;
    });

    final sql =
        'UPDATE customer_credits SET ${setClauses.join(', ')} WHERE id = :id';
    await Database.pool.execute(sql, params);
  }

  Future<Map<String, String?>> getCreditTotais({int? clienteId}) async {
    var where = 'WHERE 1=1';
    final params = <String, dynamic>{};

    if (clienteId != null) {
      where += ' AND cliente_id = :clienteId';
      params['clienteId'] = clienteId;
    }

    final sql = '''
      SELECT
        COALESCE(SUM(CASE WHEN status = 'ativo' THEN saldo ELSE 0 END), 0) as total_ativo,
        COALESCE(SUM(valor_utilizado), 0) as total_utilizado,
        COUNT(CASE WHEN status = 'ativo' THEN 1 END) as qtd_ativo,
        COUNT(CASE WHEN status = 'utilizado' THEN 1 END) as qtd_utilizado,
        COUNT(CASE WHEN status = 'expirado' THEN 1 END) as qtd_expirado
      FROM customer_credits
      $where
    ''';

    final result = await Database.pool.execute(sql, params);
    return result.rows.first.assoc();
  }

  // ── Configurações ──

  Future<String?> getConfigValue(String chave) async {
    final result = await Database.pool.execute(
      'SELECT valor FROM configuracoes WHERE chave = :chave',
      {'chave': chave},
    );
    if (result.rows.isEmpty) return null;
    return result.rows.first.assoc()['valor'];
  }
}
