import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'ordens_servico_controller.dart';
import '../../core/middleware/auth_middleware.dart';

Router ordensServicoRouter(OrdensServicoController controller) {
  final router = Router();
  final auth = authMiddleware();

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

  router.put(
    '/<id>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.atualizar(req),
        ),
  );

  router.post(
    '/<id>/itens-servico',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.adicionarItemServico(req),
        ),
  );

  router.delete(
    '/<id>/itens-servico/<itemId>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.removerItemServico(req),
        ),
  );

  router.post(
    '/<id>/itens-produto',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.adicionarItemProduto(req),
        ),
  );

  router.delete(
    '/<id>/itens-produto/<itemId>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.removerItemProduto(req),
        ),
  );

  router.post(
    '/<id>/finalizar',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.finalizar(req),
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
