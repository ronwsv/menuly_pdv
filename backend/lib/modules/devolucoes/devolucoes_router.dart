import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'devolucoes_controller.dart';
import '../../core/middleware/auth_middleware.dart';

Router devolucoesRouter(DevolucoesController controller) {
  final router = Router();
  final auth = authMiddleware();

  // ── Devoluções ──

  // Buscar venda por número (para montar tela de devolução)
  router.get(
    '/venda/<numero>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.buscarVenda(req),
        ),
  );

  // Buscar vendas por valor (para localizar venda na devolução)
  router.get(
    '/venda-por-valor',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.buscarVendasPorValor(req),
        ),
  );

  // Créditos - rotas específicas primeiro
  router.get(
    '/creditos/totais',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.totaisCreditos(req),
        ),
  );

  router.get(
    '/creditos/cliente/<clienteId>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.saldoCliente(req),
        ),
  );

  router.get(
    '/creditos',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.listarCreditos(req),
        ),
  );

  router.post(
    '/creditos/<id>/utilizar',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.utilizarCredito(req),
        ),
  );

  // Devoluções CRUD
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

  router.get(
    '/<id>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.obterPorId(req),
        ),
  );

  return router;
}
