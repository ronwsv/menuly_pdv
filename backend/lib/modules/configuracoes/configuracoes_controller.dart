import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'configuracoes_service.dart';
import '../../core/helpers/json_response.dart';
import '../../core/helpers/query_helpers.dart';

class ConfiguracoesController {
  final ConfiguracoesService _service;

  ConfiguracoesController(this._service);

  Future<Response> listarConfigs(Request request) async {
    final grupo = request.requestedUri.queryParameters['grupo'];
    final configs = await _service.listarConfigs(grupo: grupo);

    return JsonResponse.ok(configs);
  }

  Future<Response> obterConfig(Request request) async {
    final chave = request.params['chave']!;
    final config = await _service.obterConfig(chave);

    return JsonResponse.ok(config);
  }

  Future<Response> salvarConfig(Request request) async {
    final body = await parseBody(request);
    final config = await _service.salvarConfig(body);

    return JsonResponse.created(config);
  }

  Future<Response> atualizarConfigByChave(Request request) async {
    final chave = request.params['chave']!;
    final body = await parseBody(request);
    body['chave'] = chave;
    final config = await _service.salvarConfig(body);

    return JsonResponse.ok(config);
  }

  Future<Response> salvarConfigs(Request request) async {
    final body = await parseBody(request);
    final configs = (body['configs'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final resultados = await _service.salvarConfigs(configs);

    return JsonResponse.ok(resultados);
  }

  Future<Response> listarUsuarios(Request request) async {
    final usuarios = await _service.listarUsuarios();

    return JsonResponse.ok(usuarios);
  }

  Future<Response> obterUsuario(Request request) async {
    final id = int.parse(request.params['id']!);
    final usuario = await _service.obterUsuario(id);

    return JsonResponse.ok(usuario);
  }

  Future<Response> criarUsuario(Request request) async {
    final body = await parseBody(request);
    final usuario = await _service.criarUsuario(body);

    return JsonResponse.created(usuario);
  }

  Future<Response> atualizarUsuario(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final usuario = await _service.atualizarUsuario(id, body);

    return JsonResponse.ok(usuario);
  }
}
