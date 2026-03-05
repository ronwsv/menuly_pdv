import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'configuracoes_controller.dart';
import '../../core/middleware/auth_middleware.dart';

class ConfiguracoesRouter {
  final ConfiguracoesController _controller;

  ConfiguracoesRouter(this._controller);

  Router get router {
    final r = Router();

    r.get(
      '/',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler(_controller.listarConfigs),
    );

    r.get(
      '/chave/<chave>',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler((Request req) => _controller.obterConfig(req)),
    );

    r.put(
      '/chave/<chave>',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler((Request req) => _controller.atualizarConfigByChave(req)),
    );

    r.post(
      '/',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler(_controller.salvarConfig),
    );

    r.post(
      '/batch',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler(_controller.salvarConfigs),
    );

    r.get(
      '/usuarios',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler(_controller.listarUsuarios),
    );

    r.get(
      '/usuarios/<id>',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler((Request req) => _controller.obterUsuario(req)),
    );

    r.post(
      '/usuarios',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler(_controller.criarUsuario),
    );

    r.put(
      '/usuarios/<id>',
      Pipeline()
          .addMiddleware(authMiddleware())
          .addHandler((Request req) => _controller.atualizarUsuario(req)),
    );

    return r;
  }
}
