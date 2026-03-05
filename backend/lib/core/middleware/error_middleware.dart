import 'package:shelf/shelf.dart';

import '../exceptions/api_exception.dart';
import '../helpers/json_response.dart';

Middleware errorMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } on ApiException catch (e) {
        return JsonResponse.error(e.statusCode, e.message, details: e.details);
      } catch (e, stackTrace) {
        print('Erro inesperado: $e');
        print('StackTrace: $stackTrace');
        return JsonResponse.error(500, 'Erro interno do servidor');
      }
    };
  };
}
