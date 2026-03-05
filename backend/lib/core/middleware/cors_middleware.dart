import 'package:shelf/shelf.dart';

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Origin,Content-Type,Authorization',
};

Middleware corsMiddleware() {
  return createMiddleware(
    requestHandler: (Request request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      return null;
    },
    responseHandler: (Response response) {
      return response.change(headers: _corsHeaders);
    },
  );
}
