import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/middleware/auth_middleware.dart';
import 'vendas_controller.dart';

Router vendasRouter(VendasController controller) {
  final router = Router();
  final auth = authMiddleware();

  router.get(
    '/',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.listar(req),
        ),
  );

  // Analytics routes must come BEFORE /<id> to avoid being caught by the wildcard
  router.get(
    '/resumo-diario',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.resumoDiario(req),
        ),
  );

  router.get(
    '/por-forma-pagamento',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.vendasPorFormaPagamento(req),
        ),
  );

  router.get(
    '/receita-por-categoria',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.receitaPorCategoria(req),
        ),
  );

  // Comissões routes must come BEFORE /<id> to avoid being caught by the wildcard
  router.get(
    '/comissoes',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.listarComissoes(req),
        ),
  );

  router.get(
    '/comissoes/resumo',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.resumoComissoes(req),
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
    '/<id>/cancelar',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.cancelar(req),
        ),
  );

  router.post(
    '/<id>/converter',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.converterOrcamento(req),
        ),
  );

  return router;
}
