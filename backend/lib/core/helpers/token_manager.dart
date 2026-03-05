import 'package:uuid/uuid.dart';

import '../../config/server_config.dart';

class TokenData {
  final int userId;
  final String papel;
  final DateTime createdAt;
  final DateTime expiresAt;

  TokenData({
    required this.userId,
    required this.papel,
    required this.createdAt,
    required this.expiresAt,
  });
}

class TokenManager {
  static const _uuid = Uuid();
  static final Map<String, TokenData> _activeTokens = {};

  static String generateToken(int userId, String papel) {
    final token = _uuid.v4();
    final now = DateTime.now();
    _activeTokens[token] = TokenData(
      userId: userId,
      papel: papel,
      createdAt: now,
      expiresAt: now.add(ServerConfig.tokenExpiry),
    );
    return token;
  }

  static TokenData? validateToken(String token) {
    final data = _activeTokens[token];
    if (data == null) return null;
    if (DateTime.now().isAfter(data.expiresAt)) {
      _activeTokens.remove(token);
      return null;
    }
    return data;
  }

  static void revokeToken(String token) {
    _activeTokens.remove(token);
  }
}
