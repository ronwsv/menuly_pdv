import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/middleware/auth_middleware.dart';
import 'estoque_controller.dart';

Router estoqueRouter(EstoqueController controller) {
  final router = Router();

  final auth = authMiddleware();

  // Specific routes BEFORE parameterized routes
  router.get(
    '/posicao',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.getPosicao(req),
        ),
  );

  router.get(
    '/abaixo-minimo',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.getAbaixoMinimo(req),
        ),
  );

  router.get(
    '/historico',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.getHistorico(req),
        ),
  );

  router.post(
    '/movimentos',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.registrarMovimento(req),
        ),
  );

  // Parameterized route LAST
  router.get(
    '/<produto_id>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.getEstoqueProduto(
            req,
            req.params['produto_id']!,
          ),
        ),
  );

  return router;
}
