import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'crediario_controller.dart';
import '../../core/middleware/auth_middleware.dart';

Router crediarioRouter(CrediarioController controller) {
  final router = Router();
  final auth = authMiddleware();

  // Specific routes first
  router.get(
    '/totais',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.totais(req),
        ),
  );

  router.get(
    '/cliente/<clienteId>/limite',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.verificarLimite(req),
        ),
  );

  router.get(
    '/',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.listar(req),
        ),
  );

  // Parameterized routes
  router.get(
    '/<id>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.obterPorId(req),
        ),
  );

  router.post(
    '/<id>/pagar',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.pagar(req),
        ),
  );

  return router;
}
