import '../../config/database.dart';

class AuthRepository {
  Future<Map<String, String?>?> findByLogin(String login) async {
    final result = await Database.pool.execute(
      'SELECT * FROM usuarios WHERE login = :login AND ativo = 1',
      {'login': login},
    );

    if (result.rows.isEmpty) return null;

    return result.rows.first.assoc();
  }

  Future<Map<String, String?>?> findById(int id) async {
    final result = await Database.pool.execute(
      'SELECT * FROM usuarios WHERE id = :id AND ativo = 1',
      {'id': id},
    );

    if (result.rows.isEmpty) return null;

    return result.rows.first.assoc();
  }

  Future<Map<String, String?>?> findAdminByLogin(String login) async {
    final result = await Database.pool.execute(
      "SELECT * FROM usuarios WHERE login = :login AND ativo = 1 AND papel = 'admin'",
      {'login': login},
    );

    if (result.rows.isEmpty) return null;

    return result.rows.first.assoc();
  }

  Future<void> updatePassword(int id, String novoHash) async {
    await Database.pool.execute(
      'UPDATE usuarios SET senha_hash = :hash WHERE id = :id',
      {'hash': novoHash, 'id': id},
    );
  }
}
