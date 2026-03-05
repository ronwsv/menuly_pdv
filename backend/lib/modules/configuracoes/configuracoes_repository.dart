import '../../config/database.dart';

class ConfiguracoesRepository {
  // ─── Configuracoes ───────────────────────────────────────────────

  Future<List<Map<String, String?>>> findAll({String? grupo}) async {
    if (grupo != null) {
      final result = await Database.pool.execute(
        'SELECT * FROM configuracoes WHERE grupo = :grupo ORDER BY chave',
        {'grupo': grupo},
      );
      return result.rows.map((row) => row.assoc()).toList();
    }

    final result = await Database.pool.execute(
      'SELECT * FROM configuracoes ORDER BY grupo, chave',
    );

    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<Map<String, String?>?> findByChave(String chave) async {
    final result = await Database.pool.execute(
      'SELECT * FROM configuracoes WHERE chave = :chave',
      {'chave': chave},
    );

    if (result.rows.isEmpty) return null;

    return result.rows.first.assoc();
  }

  Future<void> upsert(String chave, String? valor,
      {String? grupo, String? descricao}) async {
    await Database.pool.execute(
      'INSERT INTO configuracoes (chave, valor, grupo, descricao) '
      'VALUES (:chave, :valor, :grupo, :descricao) '
      'ON DUPLICATE KEY UPDATE valor = :valor, grupo = :grupo, descricao = :descricao',
      {
        'chave': chave,
        'valor': valor,
        'grupo': grupo,
        'descricao': descricao,
      },
    );
  }

  Future<List<Map<String, String?>>> findAllByGrupo(String grupo) async {
    final result = await Database.pool.execute(
      'SELECT * FROM configuracoes WHERE grupo = :grupo ORDER BY chave',
      {'grupo': grupo},
    );

    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<void> deleteByChave(String chave) async {
    await Database.pool.execute(
      'DELETE FROM configuracoes WHERE chave = :chave',
      {'chave': chave},
    );
  }

  // ─── Usuarios ────────────────────────────────────────────────────

  Future<List<Map<String, String?>>> findAllUsuarios() async {
    final result = await Database.pool.execute(
      'SELECT * FROM usuarios ORDER BY nome',
    );

    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<Map<String, String?>?> findUsuarioById(int id) async {
    final result = await Database.pool.execute(
      'SELECT * FROM usuarios WHERE id = :id',
      {'id': id},
    );

    if (result.rows.isEmpty) return null;

    return result.rows.first.assoc();
  }

  Future<int> createUsuario(Map<String, String> data) async {
    final columns = data.keys.join(', ');
    final placeholders = data.keys.map((k) => ':$k').join(', ');

    final result = await Database.pool.execute(
      'INSERT INTO usuarios ($columns) VALUES ($placeholders)',
      data,
    );

    return result.lastInsertID.toInt();
  }

  Future<void> updateUsuario(int id, Map<String, dynamic> data) async {
    if (data.isEmpty) return;

    final setClauses = <String>[];
    final params = <String, dynamic>{'id': id};

    data.forEach((key, value) {
      setClauses.add('$key = :$key');
      params[key] = value;
    });

    final sql = 'UPDATE usuarios SET ${setClauses.join(', ')} WHERE id = :id';
    await Database.pool.execute(sql, params);
  }

  Future<bool> existsByLogin(String login, {int? excludeId}) async {
    String sql = 'SELECT COUNT(*) as total FROM usuarios WHERE login = :login';
    final params = <String, dynamic>{'login': login};

    if (excludeId != null) {
      sql += ' AND id != :excludeId';
      params['excludeId'] = excludeId;
    }

    final result = await Database.pool.execute(sql, params);
    final row = result.rows.first.assoc();

    return int.parse(row['total']!) > 0;
  }
}
