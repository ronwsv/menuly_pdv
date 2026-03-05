import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'categorias_service.dart';
import '../../core/helpers/json_response.dart';
import '../../core/helpers/query_helpers.dart';

class CategoriasController {
  final CategoriasService _service;

  CategoriasController(this._service);

  Future<Response> listar(Request request) async {
    final categorias = await _service.listar();

    return JsonResponse.ok(categorias);
  }

  Future<Response> obterPorId(Request request) async {
    final id = int.parse(request.params['id']!);
    final categoria = await _service.obterPorId(id);

    return JsonResponse.ok(categoria);
  }

  Future<Response> criar(Request request) async {
    final body = await parseBody(request);
    final categoria = await _service.criar(body);

    return JsonResponse.created(categoria);
  }

  Future<Response> atualizar(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final categoria = await _service.atualizar(id, body);

    return JsonResponse.ok(categoria);
  }

  Future<Response> excluir(Request request) async {
    final id = int.parse(request.params['id']!);
    await _service.excluir(id);

    return JsonResponse.ok({'message': 'Categoria excluída com sucesso'});
  }
}
