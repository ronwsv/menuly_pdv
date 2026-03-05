import 'dart:convert';

import 'package:shelf/shelf.dart';

class JsonResponse {
  static const _headers = {'Content-Type': 'application/json; charset=utf-8'};

  static Response ok(dynamic data, {String? message}) {
    final body = <String, dynamic>{
      'success': true,
      'data': data,
    };
    if (message != null) {
      body['message'] = message;
    }
    return Response.ok(jsonEncode(body), headers: _headers);
  }

  static Response created(dynamic data, {String? message}) {
    final body = <String, dynamic>{
      'success': true,
      'data': data,
    };
    if (message != null) {
      body['message'] = message;
    }
    return Response(201, body: jsonEncode(body), headers: _headers);
  }

  static Response error(int statusCode, String message,
      {Map<String, dynamic>? details}) {
    final body = <String, dynamic>{
      'success': false,
      'error': message,
    };
    if (details != null) {
      body['details'] = details;
    }
    return Response(statusCode, body: jsonEncode(body), headers: _headers);
  }

  static Response paginated(List data, int total, int page, int perPage) {
    final body = <String, dynamic>{
      'success': true,
      'data': data,
      'pagination': {
        'total': total,
        'page': page,
        'per_page': perPage,
        'total_pages': (total / perPage).ceil(),
      },
    };
    return Response.ok(jsonEncode(body), headers: _headers);
  }
}
