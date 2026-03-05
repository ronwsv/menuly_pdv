import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/helpers/json_response.dart';
import '../../core/helpers/query_helpers.dart';
import 'caixas_service.dart';

class CaixasController {
  final CaixasService _service;

  CaixasController(this._service);

  Future<Response> listarCaixas(Request request) async {
    final caixas = await _service.listarCaixas();
    return JsonResponse.ok(caixas);
  }

  Future<Response> obterCaixa(Request request) async {
    final id = int.parse(request.params['id']!);
    final caixa = await _service.obterCaixa(id);
    return JsonResponse.ok(caixa);
  }

  Future<Response> listarMovimentos(Request request) async {
    final queryParams = request.url.queryParameters;
    final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
    final perPage = int.tryParse(queryParams['per_page'] ?? '50') ?? 50;
    final offset = (page - 1) * perPage;

    final params = <String, dynamic>{
      'limit': perPage,
      'offset': offset,
    };

    if (queryParams['caixa_id'] != null) {
      params['caixa_id'] = int.tryParse(queryParams['caixa_id']!);
    }
    if (queryParams['tipo'] != null) params['tipo'] = queryParams['tipo'];
    if (queryParams['data_inicio'] != null) {
      params['data_inicio'] = queryParams['data_inicio'];
    }
    if (queryParams['data_fim'] != null) {
      params['data_fim'] = queryParams['data_fim'];
    }

    final result = await _service.listarMovimentos(params);

    return JsonResponse.paginated(
      result['items'] as List,
      result['total'] as int,
      page,
      perPage,
    );
  }

  Future<Response> lancamento(Request request) async {
    final body = await parseBody(request);
    final userId = request.context['userId'] as int;
    final result = await _service.lancamento(body, userId);
    return JsonResponse.created(result);
  }

  Future<Response> transferencia(Request request) async {
    final body = await parseBody(request);
    final userId = request.context['userId'] as int;
    final result = await _service.transferencia(body, userId);
    return JsonResponse.ok(result);
  }

  Future<Response> lancamentoBatch(Request request) async {
    final body = await parseBody(request);
    final userId = request.context['userId'] as int;
    final result = await _service.lancamentoBatch(body, userId);
    return JsonResponse.created(result);
  }

  Future<Response> resumo(Request request) async {
    final id = int.parse(request.params['id']!);
    final queryParams = request.url.queryParameters;

    final params = <String, dynamic>{};
    if (queryParams['data_inicio'] != null) {
      params['data_inicio'] = queryParams['data_inicio'];
    }
    if (queryParams['data_fim'] != null) {
      params['data_fim'] = queryParams['data_fim'];
    }

    final result = await _service.resumo(id, params);
    return JsonResponse.ok(result);
  }

  Future<Response> fechamento(Request request) async {
    final id = int.parse(request.params['id']!);
    final queryParams = request.url.queryParameters;

    final params = <String, dynamic>{};
    if (queryParams['data_inicio'] != null) {
      params['data_inicio'] = queryParams['data_inicio'];
    }
    if (queryParams['data_fim'] != null) {
      params['data_fim'] = queryParams['data_fim'];
    }

    final result = await _service.fechamento(id, params);
    return JsonResponse.ok(result);
  }

  Future<Response> abrirCaixa(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final userId = request.context['userId'] as int;
    final result = await _service.abrirCaixa(id, body, userId);
    return JsonResponse.ok(result);
  }

  Future<Response> fecharCaixa(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final userId = request.context['userId'] as int;
    final result = await _service.fecharCaixa(id, body, userId);
    return JsonResponse.created(result);
  }

  Future<Response> listarFechamentos(Request request) async {
    final id = int.parse(request.params['id']!);
    final result = await _service.listarFechamentos(id);
    return JsonResponse.ok(result);
  }
}
