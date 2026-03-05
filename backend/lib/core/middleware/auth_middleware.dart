import 'package:shelf/shelf.dart';

import '../exceptions/api_exception.dart';
import '../helpers/token_manager.dart';

Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        throw UnauthorizedException(
          'Token de autenticação não fornecido ou formato inválido.',
        );
      }

      final token = authHeader.substring(7);
      final tokenData = TokenManager.validateToken(token);

      if (tokenData == null) {
        throw UnauthorizedException(
          'Token inválido ou expirado.',
        );
      }

      final updatedRequest = request.change(context: {
        'userId': tokenData.userId,
        'papel': tokenData.papel,
      });

      return innerHandler(updatedRequest);
    };
  };
}
