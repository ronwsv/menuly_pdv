import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/middleware/auth_middleware.dart';
import 'produtos_controller.dart';

Router produtosRouter(ProdutosController controller) {
  final router = Router();

  final auth = authMiddleware();

  router.get(
    '/',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.listar(req),
        ),
  );

  router.get(
    '/barcode/<codigo>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) =>
              controller.buscarPorCodigoBarras(req, req.params['codigo']!),
        ),
  );

  router.get(
    '/interno/<codigo>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) =>
              controller.buscarPorCodigoInterno(req, req.params['codigo']!),
        ),
  );

  // Report endpoints (must be before /<id> to avoid route conflicts)
  router.get(
    '/ranking/geral',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.rankingGeral(req),
        ),
  );

  router.get(
    '/ranking/por-data',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.rankingPorData(req),
        ),
  );

  // Importação CSV
  router.post(
    '/importar',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.importarCSV(req),
        ),
  );

  // Batch operations
  router.patch(
    '/batch/estoque-minimo',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.batchEstoqueMinimo(req),
        ),
  );

  router.patch(
    '/batch/margem',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.batchMargem(req),
        ),
  );

  router.get(
    '/<id>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.obterPorId(req, req.params['id']!),
        ),
  );

  router.post(
    '/',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.criar(req),
        ),
  );

  router.put(
    '/<id>',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.atualizar(req, req.params['id']!),
        ),
  );

  router.patch(
    '/<id>/inativar',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.inativar(req, req.params['id']!),
        ),
  );

  router.patch(
    '/<id>/bloquear',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.bloquear(req, req.params['id']!),
        ),
  );

  router.post(
    '/<id>/imagem',
    Pipeline().addMiddleware(auth).addHandler(
          (Request req) => controller.uploadImagem(req),
        ),
  );

  return router;
}
