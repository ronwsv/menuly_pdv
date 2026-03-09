import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/helpers/json_response.dart';
import '../../core/helpers/query_helpers.dart';
import 'consignacoes_service.dart';

class ConsignacoesController {
  final ConsignacoesService _service;

  ConsignacoesController(this._service);

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
    if (queryParams['fornecedor_id'] != null) {
      params['fornecedor_id'] = int.tryParse(queryParams['fornecedor_id']!);
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
    final result = await _service.obterPorId(id);
    return JsonResponse.ok(result);
  }

  Future<Response> criar(Request request) async {
    final body = await parseBody(request);
    final userId = request.context['userId'] as int;
    final result = await _service.criar(body, userId);
    return JsonResponse.created(result);
  }

  Future<Response> registrarAcerto(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final userId = request.context['userId'] as int;
    final result = await _service.registrarAcerto(id, body, userId);
    return JsonResponse.ok(result);
  }

  Future<Response> cancelar(Request request) async {
    final id = int.parse(request.params['id']!);
    final userId = request.context['userId'] as int;
    await _service.cancelar(id, userId);
    return JsonResponse.ok({'message': 'Consignação cancelada com sucesso'});
  }
}
