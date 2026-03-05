import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'contas_pagar_controller.dart';
import '../../core/middleware/auth_middleware.dart';

Router contasPagarRouter(ContasPagarController controller) {
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
    '/',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.listar(req),
        ),
  );

  router.post(
    '/',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.criar(req),
        ),
  );

  // Parameterized routes last
  router.get(
    '/<id>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.obterPorId(req),
        ),
  );

  router.put(
    '/<id>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.atualizar(req),
        ),
  );

  router.post(
    '/<id>/baixa',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.darBaixa(req),
        ),
  );

  router.post(
    '/<id>/cancelar',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.cancelar(req),
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
