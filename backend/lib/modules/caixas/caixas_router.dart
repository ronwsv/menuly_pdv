import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/middleware/auth_middleware.dart';
import 'caixas_controller.dart';

Router caixasRouter(CaixasController controller) {
  final router = Router();
  final auth = authMiddleware();

  router.get(
    '/',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.listarCaixas(req),
        ),
  );

  // Specific routes BEFORE parameterized ones
  router.get(
    '/movimentos',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.listarMovimentos(req),
        ),
  );

  router.post(
    '/lancamento',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.lancamento(req),
        ),
  );

  router.post(
    '/transferencia',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.transferencia(req),
        ),
  );

  router.post(
    '/lancamento/batch',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.lancamentoBatch(req),
        ),
  );

  // Parameterized routes LAST
  router.get(
    '/<id>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.obterCaixa(req),
        ),
  );

  router.get(
    '/<id>/resumo',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.resumo(req),
        ),
  );

  router.get(
    '/<id>/fechamento',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.fechamento(req),
        ),
  );

  router.post(
    '/<id>/abrir',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.abrirCaixa(req),
        ),
  );

  router.post(
    '/<id>/fechar',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.fecharCaixa(req),
        ),
  );

  router.get(
    '/<id>/fechamentos',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.listarFechamentos(req),
        ),
  );

  return router;
}
