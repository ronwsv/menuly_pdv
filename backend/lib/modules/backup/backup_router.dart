import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/middleware/auth_middleware.dart';
import 'backup_controller.dart';

Router backupRouter(BackupController controller) {
  final router = Router();
  final auth = authMiddleware();

  router.get(
    '/gerar',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.gerar(req),
        ),
  );

  router.post(
    '/restaurar',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.restaurar(req),
        ),
  );

  return router;
}
