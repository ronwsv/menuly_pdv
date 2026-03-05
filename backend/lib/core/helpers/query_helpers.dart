import 'dart:convert';

import 'package:shelf/shelf.dart';

Future<Map<String, dynamic>> parseBody(Request request) async {
  final body = await request.readAsString();
  return jsonDecode(body) as Map<String, dynamic>;
}

int getPage(Map<String, String> params) {
  final page = int.tryParse(params['page'] ?? '') ?? 1;
  return page < 1 ? 1 : page;
}

int getPerPage(Map<String, String> params) {
  final perPage = int.tryParse(params['per_page'] ?? '') ?? 50;
  return perPage < 1 ? 50 : perPage;
}

int getOffset(int page, int perPage) {
  return (page - 1) * perPage;
}
