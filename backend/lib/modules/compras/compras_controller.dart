import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/helpers/json_response.dart';
import '../../core/helpers/query_helpers.dart';
import 'compras_service.dart';

class ComprasController {
  final ComprasService _service;

  ComprasController(this._service);

  Future<Response> listar(Request request) async {
    final queryParams = request.url.queryParameters;
    final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
    final perPage = int.tryParse(queryParams['per_page'] ?? '50') ?? 50;
    final offset = (page - 1) * perPage;

    final params = <String, dynamic>{
      'limit': perPage,
      'offset': offset,
    };

    if (queryParams['fornecedor_id'] != null) {
      params['fornecedor_id'] = int.tryParse(queryParams['fornecedor_id']!);
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
    final compra = await _service.obterPorId(id);
    return JsonResponse.ok(compra);
  }

  Future<Response> criar(Request request) async {
    final body = await parseBody(request);
    final userId = request.context['userId'] as int;
    final compra = await _service.criar(body, userId);
    return JsonResponse.created(compra);
  }

  Future<Response> atualizar(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final userId = request.context['userId'] as int;
    final compra = await _service.atualizar(id, body, userId);
    return JsonResponse.ok(compra);
  }

  Future<Response> excluir(Request request) async {
    final id = int.parse(request.params['id']!);
    final userId = request.context['userId'] as int;
    await _service.excluir(id, userId);
    return JsonResponse.ok({'message': 'Compra excluída com sucesso'});
  }
}
