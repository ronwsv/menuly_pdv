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

  // importar-xml must come BEFORE /<id> to avoid wildcard conflict
  router.post(
    '/importar-xml',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.importarXml(req),
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
