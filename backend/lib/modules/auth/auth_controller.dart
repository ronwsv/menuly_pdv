import 'package:shelf/shelf.dart';

import 'auth_service.dart';
import '../../core/helpers/json_response.dart';
import '../../core/helpers/query_helpers.dart';

class AuthController {
  final AuthService _service;

  AuthController(this._service);

  Future<Response> login(Request request) async {
    final body = await parseBody(request);
    final login = body['login'] as String;
    final senha = body['senha'] as String;

    final resultado = await _service.login(login, senha);

    return JsonResponse.ok({
      'token': resultado['token'],
      'usuario': resultado['usuario'],
    });
  }

  Future<Response> logout(Request request) async {
    final authHeader = request.headers['Authorization']!;
    final token = authHeader.substring(7);

    await _service.logout(token);

    return JsonResponse.ok({'message': 'Logout realizado com sucesso'});
  }

  Future<Response> validarAdmin(Request request) async {
    final body = await parseBody(request);
    final login = body['login'] as String;
    final senha = body['senha'] as String;

    await _service.validarAdmin(login, senha);

    return JsonResponse.ok({'message': 'Administrador validado'});
  }

  Future<Response> alterarSenha(Request request) async {
    final userId = request.context['userId'] as int;
    final body = await parseBody(request);
    final senhaAtual = body['senha_atual'] as String;
    final novaSenha = body['nova_senha'] as String;

    await _service.alterarSenha(userId, senhaAtual, novaSenha);

    return JsonResponse.ok({'message': 'Senha alterada com sucesso'});
  }
}
