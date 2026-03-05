import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth_controller.dart';
import '../../core/middleware/auth_middleware.dart';

class AuthRouter {
  final AuthController _controller;

  AuthRouter(this._controller);

  Router get router {
    final r = Router();

    r.post('/login', _controller.login);

    r.post(
      '/logout',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler(_controller.logout),
    );

    r.post(
      '/validar-admin',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler(_controller.validarAdmin),
    );

    r.post(
      '/alterar-senha',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler(_controller.alterarSenha),
    );

    return r;
  }
}
