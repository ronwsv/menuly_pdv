import '../../config/database.dart';
import 'compra_model.dart';
import 'compra_item_model.dart';

class ComprasRepository {
  Future<Compra?> findById(int id) async {
    final results = await Database.instance.query(
      'SELECT c.*, f.razao_social as fornecedor_nome '
      'FROM compras c '
      'LEFT JOIN fornecedores f ON c.fornecedor_id = f.id '
      'WHERE c.id = :id',
      {'id': id.toString()},
    );
    if (results.isEmpty) return null;
    return Compra.fromRow(results.first);
  }

  Future<List<Compra>> findAll({
    int? fornecedorId,
    String? dataInicio,
    String? dataFim,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (fornecedorId != null) {
      where += ' AND c.fornecedor_id = :fornecedor_id';
      params['fornecedor_id'] = fornecedorId.toString();
    }
    if (dataInicio != null) {
      where += ' AND c.data_compra >= :data_inicio';
      params['data_inicio'] = dataInicio;
    }
    if (dataFim != null) {
      where += ' AND c.data_compra <= :data_fim';
      params['data_fim'] = dataFim;
    }

    final results = await Database.instance.query(
      'SELECT c.*, f.razao_social as fornecedor_nome '
      'FROM compras c '
      'LEFT JOIN fornecedores f ON c.fornecedor_id = f.id '
      '$where ORDER BY c.data_compra DESC LIMIT $limit OFFSET $offset',
      params,
    );
    return results.map((row) => Compra.fromRow(row)).toList();
  }

  Future<int> count({
    int? fornecedorId,
    String? dataInicio,
    String? dataFim,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (fornecedorId != null) {
      where += ' AND fornecedor_id = :fornecedor_id';
      params['fornecedor_id'] = fornecedorId.toString();
    }
    if (dataInicio != null) {
      where += ' AND data_compra >= :data_inicio';
      params['data_inicio'] = dataInicio;
    }
    if (dataFim != null) {
      where += ' AND data_compra <= :data_fim';
      params['data_fim'] = dataFim;
    }

    final results = await Database.instance.query(
      'SELECT COUNT(*) as total FROM compras $where',
      params,
    );
    if (results.isEmpty) return 0;
    return int.parse(results.first['total'] ?? '0');
  }

  Future<int> create(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO compras (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    final result = await Database.instance.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<void> update(int id, Map<String, String> data) async {
    final sets = data.keys.map((c) => '$c = :$c').toList();
    data['id'] = id.toString();
    final sql = 'UPDATE compras SET ${sets.join(', ')} WHERE id = :id';
    await Database.instance.execute(sql, data);
  }

  Future<void> delete(int id) async {
    await Database.instance.execute(
      'DELETE FROM compra_itens WHERE compra_id = :id',
      {'id': id.toString()},
    );
    await Database.instance.execute(
      'DELETE FROM compras WHERE id = :id',
      {'id': id.toString()},
    );
  }

  Future<void> createItem(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO compra_itens (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    await Database.instance.execute(sql, data);
  }

  Future<List<CompraItem>> findItensByCompraId(int compraId) async {
    final results = await Database.instance.query(
      'SELECT ci.*, p.descricao as produto_descricao '
      'FROM compra_itens ci '
      'LEFT JOIN produtos p ON ci.produto_id = p.id '
      'WHERE ci.compra_id = :compra_id '
      'ORDER BY ci.id',
      {'compra_id': compraId.toString()},
    );
    return results.map((row) => CompraItem.fromRow(row)).toList();
  }

  Future<void> deleteItensByCompraId(int compraId) async {
    await Database.instance.execute(
      'DELETE FROM compra_itens WHERE compra_id = :compra_id',
      {'compra_id': compraId.toString()},
    );
  }

  Future<void> atualizarEstoque(int produtoId, double quantidade) async {
    await Database.instance.execute(
      'UPDATE produtos SET estoque_atual = estoque_atual + :qtd WHERE id = :id',
      {'qtd': quantidade.toString(), 'id': produtoId.toString()},
    );
  }

  Future<Map<String, String?>?> getProduto(int id) async {
    final results = await Database.instance.query(
      'SELECT id, descricao, estoque_atual, preco_custo, preco_venda, ativo FROM produtos WHERE id = :id',
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
}
