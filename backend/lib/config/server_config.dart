class ServerConfig {
  // Servidor
  static const String host = '127.0.0.1';
  static const int port = 8080;

  // Banco de dados
  static const String dbHost = '127.0.0.1';
  static const int dbPort = 3306;
  static const String dbUser = 'pdv_user';
  static const String dbPassword = 'pdv_senha_segura';
  static const String dbName = 'menuly_pdv';
  static const int dbPoolSize = 10;

  // Token
  static const Duration tokenExpiry = Duration(hours: 12);
}
