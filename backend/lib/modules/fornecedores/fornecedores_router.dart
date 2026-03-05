import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'fornecedores_controller.dart';
import '../../core/middleware/auth_middleware.dart';

class FornecedoresRouter {
  final FornecedoresController _controller;

  FornecedoresRouter(this._controller);

  Router get router {
    final r = Router();

    r.get(
      '/',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler(_controller.listar),
    );

    r.get(
      '/<id>',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler((Request req) => _controller.obterPorId(req)),
    );

    r.post(
      '/',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler(_controller.criar),
    );

    r.put(
      '/<id>',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler((Request req) => _controller.atualizar(req)),
    );

    r.delete(
      '/<id>',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler((Request req) => _controller.excluir(req)),
    );

    return r;
  }
}
