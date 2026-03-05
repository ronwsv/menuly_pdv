import 'package:mysql_client/mysql_client.dart';

import 'server_config.dart';

class Database {
  static MySQLConnectionPool? _pool;
  static final Database instance = Database._();

  Database._();

  static void initialize() {
    _pool = MySQLConnectionPool(
      host: ServerConfig.dbHost,
      port: ServerConfig.dbPort,
      userName: ServerConfig.dbUser,
      password: ServerConfig.dbPassword,
      databaseName: ServerConfig.dbName,
      maxConnections: ServerConfig.dbPoolSize,
    );
  }

  static MySQLConnectionPool get pool {
    if (_pool == null) {
      throw StateError(
        'Database não foi inicializado. Chame Database.initialize() primeiro.',
      );
    }
    return _pool!;
  }

  Future<List<Map<String, String?>>> query(
    String sql,
    Map<String, String> params,
  ) async {
    final result = await pool.execute(sql, params);
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<IResultSet> execute(
    String sql,
    Map<String, String> params,
  ) async {
    return await pool.execute(sql, params);
  }

  static Future<void> close() async {
    await _pool?.close();
    _pool = null;
  }
}
