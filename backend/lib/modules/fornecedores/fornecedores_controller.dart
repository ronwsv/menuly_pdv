import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'fornecedores_service.dart';
import '../../core/helpers/json_response.dart';
import '../../core/helpers/query_helpers.dart';

class FornecedoresController {
  final FornecedoresService _service;

  FornecedoresController(this._service);

  Future<Response> listar(Request request) async {
    final queryParams = request.url.queryParameters;

    final page = getPage(queryParams);
    final perPage = getPerPage(queryParams);
    final offset = getOffset(page, perPage);

    final params = <String, dynamic>{
      'busca': queryParams['busca'],
      'limit': perPage,
      'offset': offset,
    };

    if (queryParams['ativo'] != null) {
      params['ativo'] = queryParams['ativo'] == '1' ||
          queryParams['ativo'] == 'true';
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
    final fornecedor = await _service.obterPorId(id);

    return JsonResponse.ok(fornecedor);
  }

  Future<Response> criar(Request request) async {
    final body = await parseBody(request);
    final fornecedor = await _service.criar(body);

    return JsonResponse.created(fornecedor);
  }

  Future<Response> atualizar(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final fornecedor = await _service.atualizar(id, body);

    return JsonResponse.ok(fornecedor);
  }

  Future<Response> excluir(Request request) async {
    final id = int.parse(request.params['id']!);
    await _service.excluir(id);

    return JsonResponse.ok({'message': 'Fornecedor excluído com sucesso'});
  }
}
