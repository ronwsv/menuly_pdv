import 'package:shelf/shelf.dart';

Middleware logMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();
      final response = await innerHandler(request);
      stopwatch.stop();

      final timestamp = DateTime.now().toIso8601String();
      final method = request.method;
      final path = request.requestedUri.path;
      final statusCode = response.statusCode;
      final duration = stopwatch.elapsedMilliseconds;

      print('[$timestamp] $method $path -> $statusCode (${duration}ms)');

      return response;
    };
  };
}
