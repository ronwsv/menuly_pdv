import '../../config/database.dart';

class EstoqueRepository {

  Future<List<Map<String, String?>>> getPosicao() async {
    final results = await Database.instance.query(
      'SELECT id, descricao, estoque_atual, estoque_minimo, ativo '
      'FROM produtos WHERE ativo = 1 ORDER BY descricao',
      {},
    );
    return results;
  }

  Future<List<Map<String, String?>>> getAbaixoMinimo() async {
    final results = await Database.instance.query(
      'SELECT id, descricao, estoque_atual, estoque_minimo, ativo '
      'FROM produtos '
      'WHERE ativo = 1 AND estoque_minimo > 0 AND estoque_atual < estoque_minimo '
      'ORDER BY descricao',
      {},
    );
    return results;
  }

  Future<Map<String, String?>?> getEstoqueProduto(int produtoId) async {
    final results = await Database.instance.query(
      'SELECT id, descricao, estoque_atual, estoque_minimo, ativo '
      'FROM produtos WHERE id = :id',
      {'id': produtoId.toString()},
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<List<Map<String, String?>>> getHistorico({
    int? produtoId,
    String? tipo,
    String? ocorrencia,
    String? dataInicio,
    String? dataFim,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (produtoId != null) {
      where += ' AND h.produto_id = :produto_id';
      params['produto_id'] = produtoId.toString();
    }

    if (tipo != null && tipo.isNotEmpty) {
      where += ' AND h.tipo = :tipo';
      params['tipo'] = tipo;
    }

    if (ocorrencia != null && ocorrencia.isNotEmpty) {
      where += ' AND h.ocorrencia = :ocorrencia';
      params['ocorrencia'] = ocorrencia;
    }

    if (dataInicio != null) {
      where += ' AND h.criado_em >= :data_inicio';
      params['data_inicio'] = dataInicio;
    }

    if (dataFim != null) {
      where += ' AND h.criado_em <= :data_fim';
      params['data_fim'] = dataFim;
    }

    final sql = 'SELECT h.*, p.descricao as produto_descricao '
        'FROM historico_estoque h '
        'JOIN produtos p ON h.produto_id = p.id '
        '$where '
        'ORDER BY h.criado_em DESC '
        'LIMIT $limit OFFSET $offset';

    final results = await Database.instance.query(sql, params);
    return results;
  }

  Future<int> registrarMovimento(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();

    final sql = 'INSERT INTO historico_estoque '
        '(${columns.join(', ')}) VALUES (${placeholders.join(', ')})';

    final result = await Database.instance.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<void> atualizarEstoque(int produtoId, int novaQtd) async {
    await Database.instance.execute(
      'UPDATE produtos SET estoque_atual = :qtd WHERE id = :id',
      {
        'qtd': novaQtd.toString(),
        'id': produtoId.toString(),
      },
    );
  }
}
