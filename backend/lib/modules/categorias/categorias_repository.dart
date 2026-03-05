import '../../config/database.dart';

class CategoriasRepository {
  Future<List<Map<String, String?>>> findAll() async {
    final result = await Database.pool.execute(
      'SELECT * FROM categorias WHERE ativo = 1 ORDER BY nome',
    );

    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<Map<String, String?>?> findById(int id) async {
    final result = await Database.pool.execute(
      'SELECT * FROM categorias WHERE id = :id',
      {'id': id},
    );

    if (result.rows.isEmpty) return null;

    return result.rows.first.assoc();
  }

  Future<int> create(String nome, String? descricao) async {
    final result = await Database.pool.execute(
      'INSERT INTO categorias (nome, descricao) VALUES (:nome, :descricao)',
      {'nome': nome, 'descricao': descricao},
    );

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

    final sql = 'UPDATE categorias SET ${setClauses.join(', ')} WHERE id = :id';
    await Database.pool.execute(sql, params);
  }

  Future<void> delete(int id) async {
    await Database.pool.execute(
      'UPDATE categorias SET ativo = 0 WHERE id = :id',
      {'id': id},
    );
  }

  Future<bool> existsByNome(String nome, {int? excludeId}) async {
    String sql = 'SELECT COUNT(*) as total FROM categorias WHERE nome = :nome AND ativo = 1';
    final params = <String, dynamic>{'nome': nome};

    if (excludeId != null) {
      sql += ' AND id != :excludeId';
      params['excludeId'] = excludeId;
    }

    final result = await Database.pool.execute(sql, params);
    final row = result.rows.first.assoc();

    return int.parse(row['total']!) > 0;
  }
}
