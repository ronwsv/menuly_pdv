import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../core/exceptions/api_exception.dart';
import 'estoque_service.dart';

class EstoqueController {
  final EstoqueService _service;

  EstoqueController(this._service);

  Future<Response> getPosicao(Request request) async {
    try {
      final posicao = await _service.getPosicao();

      return Response.ok(
        jsonEncode({'data': posicao}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getAbaixoMinimo(Request request) async {
    try {
      final items = await _service.getAbaixoMinimo();

      return Response.ok(
        jsonEncode({'data': items}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getEstoqueProduto(
      Request request, String produtoId) async {
    try {
      final id = int.tryParse(produtoId);
      if (id == null) {
        return Response(
          400,
          body: jsonEncode({'error': 'ID inválido'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final estoque = await _service.getEstoqueProduto(id);

      return Response.ok(
        jsonEncode({'data': estoque}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> registrarMovimento(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final userId = request.context['userId'] as int;

      final result = await _service.registrarMovimento(data, userId);

      return Response(
        201,
        body: jsonEncode(result),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getHistorico(Request request) async {
    try {
      final queryParams = request.url.queryParameters;

      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final perPage = int.tryParse(queryParams['per_page'] ?? '50') ?? 50;
      final offset = (page - 1) * perPage;

      final params = <String, dynamic>{
        'limit': perPage,
        'offset': offset,
      };

      if (queryParams['produto_id'] != null) {
        params['produto_id'] = int.tryParse(queryParams['produto_id']!);
      }

      if (queryParams['tipo'] != null) {
        params['tipo'] = queryParams['tipo'];
      }
      if (queryParams['ocorrencia'] != null) {
        params['ocorrencia'] = queryParams['ocorrencia'];
      }
      if (queryParams['data_inicio'] != null) {
        params['data_inicio'] = queryParams['data_inicio'];
      }
      if (queryParams['data_fim'] != null) {
        params['data_fim'] = queryParams['data_fim'];
      }

      final result = await _service.getHistorico(params);

      return Response.ok(
        jsonEncode({
          'data': result['items'],
          'page': page,
          'per_page': perPage,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
