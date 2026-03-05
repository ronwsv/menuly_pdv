import '../../config/database.dart';
import 'caixa_model.dart';
import 'caixa_fechamento_model.dart';
import 'caixa_movimento_model.dart';

class CaixasRepository {
  Future<List<Caixa>> findAll() async {
    final results = await Database.instance.query(
      'SELECT * FROM caixas WHERE ativo = 1 ORDER BY nome',
      {},
    );
    return results.map((row) => Caixa.fromRow(row)).toList();
  }

  Future<Caixa?> findById(int id) async {
    final results = await Database.instance.query(
      'SELECT * FROM caixas WHERE id = :id',
      {'id': id.toString()},
    );
    if (results.isEmpty) return null;
    return Caixa.fromRow(results.first);
  }

  Future<List<CaixaMovimento>> findMovimentos({
    int? caixaId,
    String? tipo,
    String? dataInicio,
    String? dataFim,
    int limit = 50,
    int offset = 0,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (caixaId != null) {
      where += ' AND cm.caixa_id = :caixa_id';
      params['caixa_id'] = caixaId.toString();
    }
    if (tipo != null) {
      where += ' AND cm.tipo = :tipo';
      params['tipo'] = tipo;
    }
    if (dataInicio != null) {
      where += ' AND cm.criado_em >= :data_inicio';
      params['data_inicio'] = dataInicio;
    }
    if (dataFim != null) {
      where += ' AND cm.criado_em <= :data_fim';
      params['data_fim'] = dataFim;
    }

    final results = await Database.instance.query(
      'SELECT cm.* FROM caixa_movimentos cm '
      '$where ORDER BY cm.criado_em DESC '
      'LIMIT $limit OFFSET $offset',
      params,
    );
    return results.map((row) => CaixaMovimento.fromRow(row)).toList();
  }

  Future<int> countMovimentos({
    int? caixaId,
    String? tipo,
    String? dataInicio,
    String? dataFim,
  }) async {
    var where = 'WHERE 1=1';
    final params = <String, String>{};

    if (caixaId != null) {
      where += ' AND caixa_id = :caixa_id';
      params['caixa_id'] = caixaId.toString();
    }
    if (tipo != null) {
      where += ' AND tipo = :tipo';
      params['tipo'] = tipo;
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
      'SELECT COUNT(*) as total FROM caixa_movimentos $where',
      params,
    );
    if (results.isEmpty) return 0;
    return int.parse(results.first['total'] ?? '0');
  }

  Future<int> criarMovimento(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO caixa_movimentos (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    final result = await Database.instance.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<void> atualizarSaldo(int caixaId, double valor) async {
    await Database.instance.execute(
      'UPDATE caixas SET saldo_atual = saldo_atual + :valor WHERE id = :id',
      {'valor': valor.toString(), 'id': caixaId.toString()},
    );
  }

  Future<void> atualizarStatus(int caixaId, String status) async {
    await Database.instance.execute(
      'UPDATE caixas SET status = :status WHERE id = :id',
      {'status': status, 'id': caixaId.toString()},
    );
  }

  Future<void> zerarSaldo(int caixaId) async {
    await Database.instance.execute(
      'UPDATE caixas SET saldo_atual = 0 WHERE id = :id',
      {'id': caixaId.toString()},
    );
  }

  Future<void> definirSaldo(int caixaId, double valor) async {
    await Database.instance.execute(
      'UPDATE caixas SET saldo_atual = :valor WHERE id = :id',
      {'valor': valor.toStringAsFixed(2), 'id': caixaId.toString()},
    );
  }

  Future<List<Map<String, String?>>> getVendasPorFormaPagamento(
    int caixaId, {
    String? dataInicio,
    String? dataFim,
  }) async {
    var where =
        'WHERE cm.caixa_id = :caixa_id AND cm.referencia_tipo = :ref_tipo';
    final params = <String, String>{
      'caixa_id': caixaId.toString(),
      'ref_tipo': 'venda',
    };

    if (dataInicio != null) {
      where += ' AND cm.criado_em >= :data_inicio';
      params['data_inicio'] = dataInicio;
    }
    if (dataFim != null) {
      where += ' AND cm.criado_em <= :data_fim';
      params['data_fim'] = dataFim;
    }

    final results = await Database.instance.query(
      'SELECT COALESCE(v.forma_pagamento, \'outros\') as forma_pagamento, '
      'COUNT(*) as qtd, COALESCE(SUM(cm.valor), 0) as total '
      'FROM caixa_movimentos cm '
      'LEFT JOIN vendas v ON cm.referencia_id = v.id '
      '$where '
      'GROUP BY v.forma_pagamento',
      params,
    );
    return results;
  }

  Future<List<Map<String, String?>>> getMovimentosPorCategoria(
    int caixaId, {
    String? dataInicio,
    String? dataFim,
  }) async {
    var where = 'WHERE caixa_id = :caixa_id';
    final params = <String, String>{
      'caixa_id': caixaId.toString(),
    };

    if (dataInicio != null) {
      where += ' AND criado_em >= :data_inicio';
      params['data_inicio'] = dataInicio;
    }
    if (dataFim != null) {
      where += ' AND criado_em <= :data_fim';
      params['data_fim'] = dataFim;
    }

    final results = await Database.instance.query(
      'SELECT tipo, COALESCE(categoria, \'manual\') as categoria, '
      'COALESCE(SUM(valor), 0) as total, COUNT(*) as qtd '
      'FROM caixa_movimentos '
      '$where '
      'GROUP BY tipo, categoria',
      params,
    );
    return results;
  }

  Future<Map<String, dynamic>> getResumo(int caixaId, {
    String? dataInicio,
    String? dataFim,
  }) async {
    var where = 'WHERE caixa_id = :caixa_id';
    final params = <String, String>{'caixa_id': caixaId.toString()};

    if (dataInicio != null) {
      where += ' AND criado_em >= :data_inicio';
      params['data_inicio'] = dataInicio;
    }
    if (dataFim != null) {
      where += ' AND criado_em <= :data_fim';
      params['data_fim'] = dataFim;
    }

    final entradas = await Database.instance.query(
      'SELECT COALESCE(SUM(valor), 0) as total FROM caixa_movimentos $where AND tipo = :tipo',
      {...params, 'tipo': 'entrada'},
    );
    final saidas = await Database.instance.query(
      'SELECT COALESCE(SUM(valor), 0) as total FROM caixa_movimentos $where AND tipo = :tipo',
      {...params, 'tipo': 'saida'},
    );

    return {
      'total_entradas': double.parse(entradas.first['total'] ?? '0'),
      'total_saidas': double.parse(saidas.first['total'] ?? '0'),
    };
  }

  // ── Fechamento ──────────────────────────────────────────────────────

  Future<int> criarFechamento(Map<String, String> data) async {
    final columns = data.keys.toList();
    final placeholders = columns.map((c) => ':$c').toList();
    final sql =
        'INSERT INTO caixa_fechamentos (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    final result = await Database.instance.execute(sql, data);
    return result.lastInsertID.toInt();
  }

  Future<CaixaFechamento?> findUltimoFechamento(int caixaId) async {
    final results = await Database.instance.query(
      'SELECT cf.*, u.nome as nome_usuario '
      'FROM caixa_fechamentos cf '
      'LEFT JOIN usuarios u ON cf.usuario_id = u.id '
      'WHERE cf.caixa_id = :caixa_id '
      'ORDER BY cf.criado_em DESC LIMIT 1',
      {'caixa_id': caixaId.toString()},
    );
    if (results.isEmpty) return null;
    return CaixaFechamento.fromRow(results.first);
  }

  Future<List<CaixaFechamento>> findFechamentos(int caixaId) async {
    final results = await Database.instance.query(
      'SELECT cf.*, u.nome as nome_usuario '
      'FROM caixa_fechamentos cf '
      'LEFT JOIN usuarios u ON cf.usuario_id = u.id '
      'WHERE cf.caixa_id = :caixa_id '
      'ORDER BY cf.criado_em DESC '
      'LIMIT 50',
      {'caixa_id': caixaId.toString()},
    );
    return results.map((row) => CaixaFechamento.fromRow(row)).toList();
  }
}
