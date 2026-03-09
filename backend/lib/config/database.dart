import 'dart:async';
import 'package:mysql_client/mysql_client.dart';

import 'server_config.dart';

/// Zone key used to pass the transactional connection to nested calls.
final _zoneConnKey = Object();

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

  /// Returns the transactional connection if inside a [transaction], otherwise null.
  static MySQLConnection? get _txnConn =>
      Zone.current[_zoneConnKey] as MySQLConnection?;

  Future<List<Map<String, String?>>> query(
    String sql,
    Map<String, String> params,
  ) async {
    final conn = _txnConn;
    if (conn != null) {
      final result = await conn.execute(sql, params);
      return result.rows.map((row) => row.assoc()).toList();
    }
    final result = await pool.execute(sql, params);
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<IResultSet> execute(
    String sql,
    Map<String, String> params,
  ) async {
    final conn = _txnConn;
    if (conn != null) {
      return await conn.execute(sql, params);
    }
    return await pool.execute(sql, params);
  }

  /// Executes [fn] inside a database transaction.
  /// All [query] and [execute] calls within [fn] will automatically
  /// use the transactional connection via Dart Zones.
  /// If [fn] throws, the transaction is rolled back automatically.
  Future<T> transaction<T>(Future<T> Function() fn) async {
    // If already inside a transaction, just run fn (nested call).
    if (_txnConn != null) {
      return await fn();
    }

    return await pool.transactional((conn) async {
      return await runZoned(
        () => fn(),
        zoneValues: {_zoneConnKey: conn},
      );
    });
  }

  static Future<void> close() async {
    await _pool?.close();
    _pool = null;
  }
}
