import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/middleware/auth_middleware.dart';
import 'emitente_controller.dart';

Router emitenteRouter(EmitenteController controller) {
  final router = Router();
  final auth = authMiddleware();

  router.get(
    '/',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.obter(req),
        ),
  );

  router.put(
    '/',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.atualizar(req),
        ),
  );

  return router;
}
