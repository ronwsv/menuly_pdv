import '../../config/database.dart';
import 'consignacao_model.dart';
import 'consignacao_item_model.dart';
import 'consignacao_acerto_model.dart';
import 'consignacao_acerto_item_model.dart';

class ConsignacoesRepository {
  Future<Consignacao?> findById(int id) async {
    final results = await Database.instance.query(
      'SELECT c.*, cl.nome AS cliente_nome, f.razao_social AS fornecedor_nome '
      'FROM consignacoes c '
      'LEFT JOIN clientes cl ON c.cliente_id = cl.id '
      'LEFT JOIN fornecedores f ON c.fornecedor_id = f.id '
      'WHERE c.id = :id',
      {'id': id.toString()},
    );
    if (results.isEmpty) return null;
    return Consignacao.fromRow(results.first);
  }

  Future<List<Consignacao>> findAll({
    String? tipo,
    String? status,
    int? clienteId,
    int? fornecedorId,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (tipo != null) {
      where += ' AND c.tipo = :tipo';
      params['tipo'] = tipo;
    }
    if (status != null) {
      where += ' AND c.status = :status';
      params['status'] = status;
    }
    if (clienteId != null) {
      where += ' AND c.cliente_id = :cliente_id';
      params['cliente_id'] = clienteId.toString();
    }
    if (fornecedorId != null) {
      where += ' AND c.fornecedor_id = :fornecedor_id';
      params['fornecedor_id'] = fornecedorId.toString();
    }

    final sql =
        'SELECT c.*, cl.nome AS cliente_nome, f.razao_social AS fornecedor_nome '
        'FROM consignacoes c '
        'LEFT JOIN clientes cl ON c.cliente_id = cl.id '
        'LEFT JOIN fornecedores f ON c.fornecedor_id = f.id '
        '$where ORDER BY c.criado_em DESC LIMIT $limit OFFSET $offset';

    final results = await Database.instance.query(sql, params);
    return results.map((row) => Consignacao.fromRow(row)).toList();
  }

  Future<int> count({
    String? tipo,
    String? status,
    int? clienteId,
    int? fornecedorId,
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
    if (fornecedorId != null) {
      where += ' AND fornecedor_id = :fornecedor_id';
      params['fornecedor_id'] = fornecedorId.toString();
    }

    final sql = 'SELECT COUNT(*) as total FROM consignacoes $where';
    final results = await Database.instance.query(sql, params);
    if (results.isEmpty) return 0;
    return int.parse(results.first['total'] ?? '0');
  }

  Future<String> gerarNumero() async {
    final now = DateTime.now();
    final prefix = 'CONS${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // Use MAX instead of COUNT to avoid duplicate numbers when records are deleted
    final results = await Database.instance.query(
      "SELECT MAX(CAST(SUBSTRING(numero, :prefixLen) AS UNSIGNED)) as max_seq "
      "FROM consignacoes WHERE numero LIKE :prefix",
      {'prefix': '$prefix%', 'prefixLen': (prefix.length + 1).toString()},
    );
    final seq = int.parse(results.first['max_seq'] ?? '0') + 1;
    return '$prefix${seq.toString().padLeft(3, '0')}';
  }

  Future<int> create(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO consignacoes (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    final result = await Database.instance.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<int> createItem(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO consignacao_itens (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    final result = await Database.instance.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<List<ConsignacaoItem>> findItensByConsignacaoId(int id) async {
    final results = await Database.instance.query(
      'SELECT ci.*, p.descricao AS produto_descricao, p.tamanho AS produto_tamanho '
      'FROM consignacao_itens ci '
      'JOIN produtos p ON ci.produto_id = p.id '
      'WHERE ci.consignacao_id = :id '
      'ORDER BY p.descricao',
      {'id': id.toString()},
    );
    return results.map((row) => ConsignacaoItem.fromRow(row)).toList();
  }

  Future<ConsignacaoItem?> findItemById(int id) async {
    final results = await Database.instance.query(
      'SELECT ci.*, p.descricao AS produto_descricao, p.tamanho AS produto_tamanho '
      'FROM consignacao_itens ci '
      'JOIN produtos p ON ci.produto_id = p.id '
      'WHERE ci.id = :id',
      {'id': id.toString()},
    );
    if (results.isEmpty) return null;
    return ConsignacaoItem.fromRow(results.first);
  }

  Future<void> updateStatus(int id, String status) async {
    await Database.instance.execute(
      'UPDATE consignacoes SET status = :status WHERE id = :id',
      {'id': id.toString(), 'status': status},
    );
  }

  Future<void> updateValorAcertado(int id, double valor) async {
    await Database.instance.execute(
      'UPDATE consignacoes SET valor_acertado = valor_acertado + :valor WHERE id = :id',
      {'id': id.toString(), 'valor': valor.toStringAsFixed(2)},
    );
  }

  Future<void> updateItemQuantidades(
      int itemId, double vendida, double devolvida) async {
    await Database.instance.execute(
      'UPDATE consignacao_itens '
      'SET quantidade_vendida = quantidade_vendida + :vendida, '
      'quantidade_devolvida = quantidade_devolvida + :devolvida '
      'WHERE id = :id',
      {
        'id': itemId.toString(),
        'vendida': vendida.toString(),
        'devolvida': devolvida.toString(),
      },
    );
  }

  Future<int> createAcerto(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO consignacao_acertos (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    final result = await Database.instance.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<void> createAcertoItem(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO consignacao_acerto_itens (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    await Database.instance.execute(sql, data);
  }

  Future<List<ConsignacaoAcerto>> findAcertosByConsignacaoId(int id) async {
    final results = await Database.instance.query(
      'SELECT * FROM consignacao_acertos WHERE consignacao_id = :id ORDER BY criado_em DESC',
      {'id': id.toString()},
    );
    return results.map((row) => ConsignacaoAcerto.fromRow(row)).toList();
  }

  Future<List<ConsignacaoAcertoItem>> findAcertoItensByAcertoId(int acertoId) async {
    final results = await Database.instance.query(
      'SELECT * FROM consignacao_acerto_itens WHERE acerto_id = :id',
      {'id': acertoId.toString()},
    );
    return results.map((row) => ConsignacaoAcertoItem.fromRow(row)).toList();
  }

  Future<void> updateAcertoValor(int acertoId, double valor) async {
    await Database.instance.execute(
      'UPDATE consignacao_acertos SET valor_vendido = :valor WHERE id = :id',
      {'id': acertoId.toString(), 'valor': valor.toStringAsFixed(2)},
    );
  }

  /// Returns the ID of an open cash register, or 1 as fallback.
  Future<int> buscarCaixaAberto() async {
    final results = await Database.instance.query(
      "SELECT id FROM caixas WHERE status = 'aberto' LIMIT 1",
      {},
    );
    if (results.isEmpty) return 1;
    return int.parse(results.first['id'] ?? '1');
  }

  // Stock and cash helpers (same pattern as VendasRepository)

  Future<Map<String, String?>?> getProduto(int id) async {
    final results = await Database.instance.query(
      'SELECT id, descricao, estoque_atual, preco_venda, bloqueado, ativo '
      'FROM produtos WHERE id = :id',
      {'id': id.toString()},
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> atualizarEstoque(int produtoId, int quantidade) async {
    await Database.instance.execute(
      'UPDATE produtos SET estoque_atual = estoque_atual + :qtd WHERE id = :id',
      {'id': produtoId.toString(), 'qtd': quantidade.toString()},
    );
  }

  Future<void> registrarHistoricoEstoque(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    await Database.instance.execute(
      'INSERT INTO historico_estoque (${columns.join(', ')}) VALUES (${placeholders.join(', ')})',
      data,
    );
  }

  Future<void> registrarMovimentoCaixa(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    await Database.instance.execute(
      'INSERT INTO caixa_movimentos (${columns.join(', ')}) VALUES (${placeholders.join(', ')})',
      data,
    );
  }

  Future<void> atualizarSaldoCaixa(int caixaId, double valor) async {
    await Database.instance.execute(
      'UPDATE caixas SET saldo_atual = saldo_atual + :valor WHERE id = :id',
      {'id': caixaId.toString(), 'valor': valor.toStringAsFixed(2)},
    );
  }

  Future<double> somaAcertosValor(int consignacaoId) async {
    final results = await Database.instance.query(
      'SELECT COALESCE(SUM(valor_vendido), 0) as total '
      'FROM consignacao_acertos WHERE consignacao_id = :id',
      {'id': consignacaoId.toString()},
    );
    return double.parse(results.first['total'] ?? '0');
  }
}
