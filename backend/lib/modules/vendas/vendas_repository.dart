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

    final prefixLen = (prefix.length + 1).toString();
    final results = await Database.instance.query(
      "SELECT MAX(CAST(SUBSTRING(numero, :prefixLen) AS UNSIGNED)) as max_seq "
      "FROM vendas WHERE numero LIKE :prefix",
      {'prefix': '$prefix%', 'prefixLen': prefixLen},
    );
    final seq = int.parse(results.first['max_seq'] ?? '0') + 1;
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
      'SELECT id, descricao, estoque_atual, preco_venda, bloqueado, ativo, is_combo FROM produtos WHERE id = :id',
      {'id': id.toString()},
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<List<Map<String, String?>>> getComboItens(int comboId) async {
    return await Database.instance.query(
      'SELECT ci.produto_id, ci.quantidade, p.descricao, p.estoque_atual '
      'FROM combo_itens ci '
      'JOIN produtos p ON ci.produto_id = p.id '
      'WHERE ci.combo_id = :combo_id',
      {'combo_id': comboId.toString()},
    );
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

  Future<int> buscarCaixaAberto() async {
    final results = await Database.instance.query(
      "SELECT id FROM caixas WHERE status = 'aberto' LIMIT 1", {});
    if (results.isEmpty) return 1;
    return int.parse(results.first['id'] ?? '1');
  }

  // ─── Comissões ──────────────────────────────────────────────────

  Future<void> criarComissao(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO comissoes (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    await Database.instance.execute(sql, data);
  }

  Future<void> cancelarComissaoPorVenda(int vendaId) async {
    await Database.instance.execute(
      "UPDATE comissoes SET status = 'cancelada' WHERE venda_id = :venda_id",
      {'venda_id': vendaId.toString()},
    );
  }

  Future<double?> buscarPercentualVendedor(int vendedorId) async {
    final results = await Database.instance.query(
      'SELECT comissao_percentual FROM usuarios WHERE id = :id',
      {'id': vendedorId.toString()},
    );
    if (results.isEmpty) return null;
    final val = results.first['comissao_percentual'];
    if (val == null) return null;
    return double.tryParse(val);
  }

  Future<double> buscarPercentualPadrao() async {
    final results = await Database.instance.query(
      "SELECT valor FROM configuracoes WHERE chave = 'comissao_percentual_padrao'",
      {},
    );
    if (results.isEmpty) return 0;
    return double.tryParse(results.first['valor'] ?? '0') ?? 0;
  }

  Future<List<Map<String, String?>>> buscarComissoes({
    int? vendedorId,
    String? dataInicio,
    String? dataFim,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (vendedorId != null) {
      where += ' AND c.vendedor_id = :vendedor_id';
      params['vendedor_id'] = vendedorId.toString();
    }
    if (dataInicio != null) {
      where += ' AND c.criado_em >= :data_inicio';
      params['data_inicio'] = dataInicio;
    }
    if (dataFim != null) {
      where += ' AND c.criado_em <= :data_fim';
      params['data_fim'] = dataFim;
    }
    if (status != null) {
      where += ' AND c.status = :status';
      params['status'] = status;
    }

    return await Database.instance.query(
      'SELECT c.*, v.numero as venda_numero, u.nome as vendedor_nome '
      'FROM comissoes c '
      'JOIN vendas v ON c.venda_id = v.id '
      'JOIN usuarios u ON c.vendedor_id = u.id '
      '$where ORDER BY c.criado_em DESC LIMIT $limit OFFSET $offset',
      params,
    );
  }

  Future<int> countComissoes({
    int? vendedorId,
    String? dataInicio,
    String? dataFim,
    String? status,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (vendedorId != null) {
      where += ' AND vendedor_id = :vendedor_id';
      params['vendedor_id'] = vendedorId.toString();
    }
    if (dataInicio != null) {
      where += ' AND criado_em >= :data_inicio';
      params['data_inicio'] = dataInicio;
    }
    if (dataFim != null) {
      where += ' AND criado_em <= :data_fim';
      params['data_fim'] = dataFim;
    }
    if (status != null) {
      where += ' AND status = :status';
      params['status'] = status;
    }

    final results = await Database.instance.query(
      'SELECT COUNT(*) as total FROM comissoes $where',
      params,
    );
    if (results.isEmpty) return 0;
    return int.parse(results.first['total'] ?? '0');
  }

  Future<List<Map<String, String?>>> buscarResumoComissoes({
    int? vendedorId,
    String? dataInicio,
    String? dataFim,
  }) async {
    var where = "WHERE c.status = 'ativa'";
    final params = <String, String>{};

    if (vendedorId != null) {
      where += ' AND c.vendedor_id = :vendedor_id';
      params['vendedor_id'] = vendedorId.toString();
    }
    if (dataInicio != null) {
      where += ' AND c.criado_em >= :data_inicio';
      params['data_inicio'] = dataInicio;
    }
    if (dataFim != null) {
      where += ' AND c.criado_em <= :data_fim';
      params['data_fim'] = dataFim;
    }

    return await Database.instance.query(
      'SELECT c.vendedor_id, u.nome as vendedor_nome, '
      'COUNT(*) as total_vendas, '
      'SUM(c.valor_venda) as total_vendido, '
      'SUM(c.valor_comissao) as total_comissao, '
      'AVG(c.percentual) as percentual_medio '
      'FROM comissoes c '
      'JOIN usuarios u ON c.vendedor_id = u.id '
      '$where '
      'GROUP BY c.vendedor_id, u.nome '
      'ORDER BY total_comissao DESC',
      params,
    );
  }
}
