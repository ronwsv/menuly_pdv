import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/helpers/json_response.dart';
import '../../core/helpers/query_helpers.dart';
import 'vendas_service.dart';

class VendasController {
  final VendasService _service;

  VendasController(this._service);

  Future<Response> listar(Request request) async {
    final queryParams = request.url.queryParameters;
    final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
    final perPage = int.tryParse(queryParams['per_page'] ?? '50') ?? 50;
    final offset = (page - 1) * perPage;

    final params = <String, dynamic>{
      'limit': perPage,
      'offset': offset,
    };

    if (queryParams['tipo'] != null) params['tipo'] = queryParams['tipo'];
    if (queryParams['status'] != null) params['status'] = queryParams['status'];
    if (queryParams['cliente_id'] != null) {
      params['cliente_id'] = int.tryParse(queryParams['cliente_id']!);
    }
    if (queryParams['data_inicio'] != null) {
      params['data_inicio'] = queryParams['data_inicio'];
    }
    if (queryParams['data_fim'] != null) {
      params['data_fim'] = queryParams['data_fim'];
    }

    final result = await _service.listar(params);

    return JsonResponse.paginated(
      result['items'] as List,
      result['total'] as int,
      page,
      perPage,
    );
  }

  Future<Response> obterPorId(Request request) async {
    final id = int.parse(request.params['id']!);
    final venda = await _service.obterPorId(id);
    return JsonResponse.ok(venda);
  }

  Future<Response> criar(Request request) async {
    final body = await parseBody(request);
    final userId = request.context['userId'] as int;
    final venda = await _service.criarVenda(body, userId);
    return JsonResponse.created(venda);
  }

  Future<Response> cancelar(Request request) async {
    final id = int.parse(request.params['id']!);
    final userId = request.context['userId'] as int;
    await _service.cancelar(id, userId);
    return JsonResponse.ok({'message': 'Venda cancelada com sucesso'});
  }

  Future<Response> converterOrcamento(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final userId = request.context['userId'] as int;
    final venda = await _service.converterOrcamento(id, body, userId);
    return JsonResponse.created(venda);
  }

  Future<Response> listarComissoes(Request request) async {
    final queryParams = request.url.queryParameters;
    final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
    final perPage = int.tryParse(queryParams['per_page'] ?? '50') ?? 50;
    final offset = (page - 1) * perPage;

    final params = <String, dynamic>{
      'limit': perPage,
      'offset': offset,
    };

    if (queryParams['vendedor_id'] != null) {
      params['vendedor_id'] = int.tryParse(queryParams['vendedor_id']!);
    }
    if (queryParams['data_inicio'] != null) {
      params['data_inicio'] = queryParams['data_inicio'];
    }
    if (queryParams['data_fim'] != null) {
      params['data_fim'] = queryParams['data_fim'];
    }
    if (queryParams['status'] != null) {
      params['status'] = queryParams['status'];
    }

    final result = await _service.listarComissoes(params);
    return JsonResponse.paginated(
      result['items'] as List,
      result['total'] as int,
      page,
      perPage,
    );
  }

  Future<Response> resumoComissoes(Request request) async {
    final queryParams = request.url.queryParameters;
    final params = <String, dynamic>{};

    if (queryParams['vendedor_id'] != null) {
      params['vendedor_id'] = int.tryParse(queryParams['vendedor_id']!);
    }
    if (queryParams['data_inicio'] != null) {
      params['data_inicio'] = queryParams['data_inicio'];
    }
    if (queryParams['data_fim'] != null) {
      params['data_fim'] = queryParams['data_fim'];
    }

    final result = await _service.resumoComissoes(params);
    return JsonResponse.ok(result);
  }
}
