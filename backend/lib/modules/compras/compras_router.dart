import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/middleware/auth_middleware.dart';
import 'compras_controller.dart';

Router comprasRouter(ComprasController controller) {
  final router = Router();
  final auth = authMiddleware();

  router.get(
    '/',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.listar(req),
        ),
  );

  router.get(
    '/<id>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.obterPorId(req),
        ),
  );

  router.post(
    '/',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.criar(req),
        ),
  );

  router.put(
    '/<id>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.atualizar(req),
        ),
  );

  router.delete(
    '/<id>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.excluir(req),
        ),
  );

  return router;
}
