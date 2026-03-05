import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'ordens_servico_service.dart';
import '../../core/helpers/json_response.dart';
import '../../core/helpers/query_helpers.dart';

class OrdensServicoController {
  final OrdensServicoService _service;

  OrdensServicoController(this._service);

  Future<Response> listar(Request request) async {
    final queryParams = request.url.queryParameters;

    final page = getPage(queryParams);
    final perPage = getPerPage(queryParams);
    final offset = getOffset(page, perPage);

    final params = <String, dynamic>{
      'busca': queryParams['busca'],
      'status': queryParams['status'],
      'limit': perPage,
      'offset': offset,
    };

    if (queryParams['cliente_id'] != null) {
      params['cliente_id'] = int.tryParse(queryParams['cliente_id']!);
    }
    if (queryParams['prestador_id'] != null) {
      params['prestador_id'] = int.tryParse(queryParams['prestador_id']!);
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
    final os = await _service.obterPorId(id);
    return JsonResponse.ok(os);
  }

  Future<Response> criar(Request request) async {
    final body = await parseBody(request);
    final os = await _service.criar(body);
    return JsonResponse.created(os);
  }

  Future<Response> atualizar(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final os = await _service.atualizar(id, body);
    return JsonResponse.ok(os);
  }

  Future<Response> adicionarItemServico(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final os = await _service.adicionarItemServico(id, body);
    return JsonResponse.ok(os);
  }

  Future<Response> removerItemServico(Request request) async {
    final osId = int.parse(request.params['id']!);
    final itemId = int.parse(request.params['itemId']!);
    final os = await _service.removerItemServico(osId, itemId);
    return JsonResponse.ok(os);
  }

  Future<Response> adicionarItemProduto(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final os = await _service.adicionarItemProduto(id, body);
    return JsonResponse.ok(os);
  }

  Future<Response> removerItemProduto(Request request) async {
    final osId = int.parse(request.params['id']!);
    final itemId = int.parse(request.params['itemId']!);
    final os = await _service.removerItemProduto(osId, itemId);
    return JsonResponse.ok(os);
  }

  Future<Response> finalizar(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final os = await _service.finalizar(id, body);
    return JsonResponse.ok(os, message: 'OS finalizada com sucesso');
  }

  Future<Response> cancelar(Request request) async {
    final id = int.parse(request.params['id']!);
    final os = await _service.cancelar(id);
    return JsonResponse.ok(os, message: 'OS cancelada com sucesso');
  }

  Future<Response> excluir(Request request) async {
    final id = int.parse(request.params['id']!);
    await _service.excluir(id);
    return JsonResponse.ok({'message': 'OS excluida com sucesso'});
  }
}
