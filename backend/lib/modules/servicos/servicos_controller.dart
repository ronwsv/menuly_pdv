import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'servicos_service.dart';
import '../../core/helpers/json_response.dart';
import '../../core/helpers/query_helpers.dart';

class ServicosController {
  final ServicosService _service;

  ServicosController(this._service);

  Future<Response> listar(Request request) async {
    final queryParams = request.url.queryParameters;

    final page = getPage(queryParams);
    final perPage = getPerPage(queryParams);
    final offset = getOffset(page, perPage);

    final params = <String, dynamic>{
      'busca': queryParams['busca'],
      'ativo': queryParams['ativo'],
      'limit': perPage,
      'offset': offset,
    };

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
    final servico = await _service.obterPorId(id);
    return JsonResponse.ok(servico);
  }

  Future<Response> criar(Request request) async {
    final body = await parseBody(request);
    final servico = await _service.criar(body);
    return JsonResponse.created(servico);
  }

  Future<Response> atualizar(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final servico = await _service.atualizar(id, body);
    return JsonResponse.ok(servico);
  }

  Future<Response> excluir(Request request) async {
    final id = int.parse(request.params['id']!);
    await _service.excluir(id);
    return JsonResponse.ok({'message': 'Servico excluido com sucesso'});
  }

  Future<Response> inativar(Request request) async {
    final id = int.parse(request.params['id']!);
    await _service.inativar(id);
    return JsonResponse.ok({'message': 'Servico inativado com sucesso'});
  }
}
