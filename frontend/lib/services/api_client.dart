import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  String? _token;
  void Function()? onUnauthorized;

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(String url,
      {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String url,
      {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// POST com body genérico (List ou Map).
  Future<Map<String, dynamic>> postJson(String url,
      {required Object body}) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String url,
      {Map<String, dynamic>? body}) async {
    final response = await http.put(
      Uri.parse(url),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(String url,
      {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      Uri.parse(url),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String url) async {
    final response = await http.delete(Uri.parse(url), headers: _headers);
    return _handleResponse(response);
  }

  /// Baixa bytes brutos de uma URL (para downloads de arquivos).
  Future<List<int>> getBytes(String url) async {
    final response = await http.get(Uri.parse(url), headers: {
      if (_token != null) 'Authorization': 'Bearer $_token',
    });
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Erro ao baixar arquivo: ${response.statusCode}',
    );
  }

  /// Envia texto bruto (não JSON) via POST.
  Future<Map<String, dynamic>> postRaw(String url, String body) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'text/plain; charset=utf-8',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
      body: body,
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: body['error']?.toString() ?? 'Erro desconhecido',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
