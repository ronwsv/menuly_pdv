import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/middleware/auth_middleware.dart';
import 'consignacoes_controller.dart';

Router consignacoesRouter(ConsignacoesController controller) {
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

  router.post(
    '/<id>/acerto',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.registrarAcerto(req),
        ),
  );

  router.post(
    '/<id>/cancelar',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.cancelar(req),
        ),
  );

  return router;
}
