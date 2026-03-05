import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:menuly_pdv_backend/config/server_config.dart';
import 'package:menuly_pdv_backend/config/database.dart';
import 'package:menuly_pdv_backend/core/helpers/json_response.dart';
import 'package:menuly_pdv_backend/core/helpers/password_hasher.dart';
import 'package:menuly_pdv_backend/core/middleware/log_middleware.dart';
import 'package:menuly_pdv_backend/core/middleware/cors_middleware.dart';
import 'package:menuly_pdv_backend/core/middleware/error_middleware.dart';

// Auth
import 'package:menuly_pdv_backend/modules/auth/auth_repository.dart';
import 'package:menuly_pdv_backend/modules/auth/auth_service.dart';
import 'package:menuly_pdv_backend/modules/auth/auth_controller.dart';
import 'package:menuly_pdv_backend/modules/auth/auth_router.dart';

// Categorias
import 'package:menuly_pdv_backend/modules/categorias/categorias_repository.dart';
import 'package:menuly_pdv_backend/modules/categorias/categorias_service.dart';
import 'package:menuly_pdv_backend/modules/categorias/categorias_controller.dart';
import 'package:menuly_pdv_backend/modules/categorias/categorias_router.dart';

// Produtos
import 'package:menuly_pdv_backend/modules/produtos/produtos_repository.dart';
import 'package:menuly_pdv_backend/modules/produtos/produtos_service.dart';
import 'package:menuly_pdv_backend/modules/produtos/produtos_controller.dart';
import 'package:menuly_pdv_backend/modules/produtos/produtos_router.dart';

// Estoque
import 'package:menuly_pdv_backend/modules/estoque/estoque_repository.dart';
import 'package:menuly_pdv_backend/modules/estoque/estoque_service.dart';
import 'package:menuly_pdv_backend/modules/estoque/estoque_controller.dart';
import 'package:menuly_pdv_backend/modules/estoque/estoque_router.dart';

// Vendas
import 'package:menuly_pdv_backend/modules/vendas/vendas_repository.dart';
import 'package:menuly_pdv_backend/modules/vendas/vendas_service.dart';
import 'package:menuly_pdv_backend/modules/vendas/vendas_controller.dart';
import 'package:menuly_pdv_backend/modules/vendas/vendas_router.dart';

// Caixas
import 'package:menuly_pdv_backend/modules/caixas/caixas_repository.dart';
import 'package:menuly_pdv_backend/modules/caixas/caixas_service.dart';
import 'package:menuly_pdv_backend/modules/caixas/caixas_controller.dart';
import 'package:menuly_pdv_backend/modules/caixas/caixas_router.dart';

// Clientes
import 'package:menuly_pdv_backend/modules/clientes/clientes_repository.dart';
import 'package:menuly_pdv_backend/modules/clientes/clientes_service.dart';
import 'package:menuly_pdv_backend/modules/clientes/clientes_controller.dart';
import 'package:menuly_pdv_backend/modules/clientes/clientes_router.dart';

// Fornecedores
import 'package:menuly_pdv_backend/modules/fornecedores/fornecedores_repository.dart';
import 'package:menuly_pdv_backend/modules/fornecedores/fornecedores_service.dart';
import 'package:menuly_pdv_backend/modules/fornecedores/fornecedores_controller.dart';
import 'package:menuly_pdv_backend/modules/fornecedores/fornecedores_router.dart';

// Configuracoes
import 'package:menuly_pdv_backend/modules/configuracoes/configuracoes_repository.dart';
import 'package:menuly_pdv_backend/modules/configuracoes/configuracoes_service.dart';
import 'package:menuly_pdv_backend/modules/configuracoes/configuracoes_controller.dart';
import 'package:menuly_pdv_backend/modules/configuracoes/configuracoes_router.dart';

// Compras
import 'package:menuly_pdv_backend/modules/compras/compras_repository.dart';
import 'package:menuly_pdv_backend/modules/compras/compras_service.dart';
import 'package:menuly_pdv_backend/modules/compras/compras_controller.dart';
import 'package:menuly_pdv_backend/modules/compras/compras_router.dart';

// Emitente
import 'package:menuly_pdv_backend/modules/emitente/emitente_repository.dart';
import 'package:menuly_pdv_backend/modules/emitente/emitente_controller.dart';
import 'package:menuly_pdv_backend/modules/emitente/emitente_router.dart';

// Contas a Receber
import 'package:menuly_pdv_backend/modules/contas_receber/contas_receber_repository.dart';
import 'package:menuly_pdv_backend/modules/contas_receber/contas_receber_service.dart';
import 'package:menuly_pdv_backend/modules/contas_receber/contas_receber_controller.dart';
import 'package:menuly_pdv_backend/modules/contas_receber/contas_receber_router.dart';

// Servicos
import 'package:menuly_pdv_backend/modules/servicos/servicos_repository.dart';
import 'package:menuly_pdv_backend/modules/servicos/servicos_service.dart';
import 'package:menuly_pdv_backend/modules/servicos/servicos_controller.dart';
import 'package:menuly_pdv_backend/modules/servicos/servicos_router.dart';

// Ordens de Servico
import 'package:menuly_pdv_backend/modules/ordens_servico/ordens_servico_repository.dart';
import 'package:menuly_pdv_backend/modules/ordens_servico/ordens_servico_service.dart';
import 'package:menuly_pdv_backend/modules/ordens_servico/ordens_servico_controller.dart';
import 'package:menuly_pdv_backend/modules/ordens_servico/ordens_servico_router.dart';

// Crediario
import 'package:menuly_pdv_backend/modules/crediario/crediario_repository.dart';
import 'package:menuly_pdv_backend/modules/crediario/crediario_service.dart';
import 'package:menuly_pdv_backend/modules/crediario/crediario_controller.dart';
import 'package:menuly_pdv_backend/modules/crediario/crediario_router.dart';

// Contas a Pagar
import 'package:menuly_pdv_backend/modules/contas_pagar/contas_pagar_repository.dart';
import 'package:menuly_pdv_backend/modules/contas_pagar/contas_pagar_service.dart';
import 'package:menuly_pdv_backend/modules/contas_pagar/contas_pagar_controller.dart';
import 'package:menuly_pdv_backend/modules/contas_pagar/contas_pagar_router.dart';

// Devolucoes
import 'package:menuly_pdv_backend/modules/devolucoes/devolucoes_repository.dart';
import 'package:menuly_pdv_backend/modules/devolucoes/devolucoes_service.dart';
import 'package:menuly_pdv_backend/modules/devolucoes/devolucoes_controller.dart';
import 'package:menuly_pdv_backend/modules/devolucoes/devolucoes_router.dart';

// Backup
import 'package:menuly_pdv_backend/modules/backup/backup_service.dart';
import 'package:menuly_pdv_backend/modules/backup/backup_controller.dart';
import 'package:menuly_pdv_backend/modules/backup/backup_router.dart';

Future<void> main() async {
  print('====================================');
  print(' MENULY PDV - Backend Server');
  print('====================================');

  // 1. Inicializar banco de dados
  print('[1/4] Conectando ao banco de dados...');
  Database.initialize();
  print('      Conectado: ${ServerConfig.dbHost}:${ServerConfig.dbPort}/${ServerConfig.dbName}');

  // 1.5. Migrar colunas de permissão
  await _migratePermissions();

  // 2. Corrigir hash do admin se for placeholder
  print('[2/4] Verificando senha do admin...');
  await _fixAdminPassword();

  // 3. DI Manual - instanciar repositórios, services, controllers
  print('[3/4] Configurando módulos...');

  // Auth
  final authRepository = AuthRepository();
  final authService = AuthService(authRepository);
  final authController = AuthController(authService);
  final authRouter = AuthRouter(authController);

  // Categorias
  final categoriasRepository = CategoriasRepository();
  final categoriasService = CategoriasService(categoriasRepository);
  final categoriasController = CategoriasController(categoriasService);
  final categoriasRouter = CategoriasRouter(categoriasController);

  // Produtos
  final produtosRepository = ProdutosRepository();
  final produtosService = ProdutosService(produtosRepository);
  final produtosController = ProdutosController(produtosService);

  // Estoque
  final estoqueRepository = EstoqueRepository();
  final estoqueService = EstoqueService(estoqueRepository);
  final estoqueController = EstoqueController(estoqueService);

  // Crediario
  final crediarioRepository = CrediarioRepository();
  final crediarioService = CrediarioService(crediarioRepository);
  final crediarioController = CrediarioController(crediarioService);

  // Vendas
  final vendasRepository = VendasRepository();
  final vendasService = VendasService(vendasRepository, crediarioService: crediarioService);
  final vendasController = VendasController(vendasService);

  // Caixas
  final caixasRepository = CaixasRepository();
  final caixasService = CaixasService(caixasRepository);
  final caixasController = CaixasController(caixasService);

  // Clientes
  final clientesRepository = ClientesRepository();
  final clientesService = ClientesService(clientesRepository);
  final clientesController = ClientesController(clientesService);
  final clientesRouter = ClientesRouter(clientesController);

  // Fornecedores
  final fornecedoresRepository = FornecedoresRepository();
  final fornecedoresService = FornecedoresService(fornecedoresRepository);
  final fornecedoresController = FornecedoresController(fornecedoresService);
  final fornecedoresRouter = FornecedoresRouter(fornecedoresController);

  // Configuracoes
  final configuracoesRepository = ConfiguracoesRepository();
  final configuracoesService = ConfiguracoesService(configuracoesRepository);
  final configuracoesController = ConfiguracoesController(configuracoesService);
  final configuracoesRouter = ConfiguracoesRouter(configuracoesController);

  // Compras
  final comprasRepository = ComprasRepository();
  final comprasService = ComprasService(comprasRepository);
  final comprasController = ComprasController(comprasService);

  // Emitente
  final emitenteRepository = EmitenteRepository();
  final emitenteController = EmitenteController(emitenteRepository);

  // Contas a Receber
  final contasReceberRepository = ContasReceberRepository();
  final contasReceberService = ContasReceberService(contasReceberRepository);
  final contasReceberController = ContasReceberController(contasReceberService);

  // Servicos
  final servicosRepository = ServicosRepository();
  final servicosService = ServicosService(servicosRepository);
  final servicosController = ServicosController(servicosService);

  // Ordens de Servico
  final ordensServicoRepository = OrdensServicoRepository();
  final ordensServicoService = OrdensServicoService(ordensServicoRepository);
  final ordensServicoController = OrdensServicoController(ordensServicoService);

  // Contas a Pagar
  final contasPagarRepository = ContasPagarRepository();
  final contasPagarService = ContasPagarService(contasPagarRepository);
  final contasPagarController = ContasPagarController(contasPagarService);

  // Devolucoes
  final devolucoesRepository = DevolucoesRepository();
  final devolucoesService = DevolucoesService(devolucoesRepository);
  final devolucoesController = DevolucoesController(devolucoesService);

  // Backup
  final backupService = BackupService();
  final backupController = BackupController(backupService);

  // 4. Montar rotas
  final app = Router();

  // Health check (público)
  app.get('/api/health', (Request request) {
    return JsonResponse.ok({
      'status': 'running',
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
    });
  });

  // Static file serving para imagens de produtos
  app.get('/uploads/<path|.*>', (Request request) async {
    final filePath = request.params['path']!;
    if (filePath.contains('..')) {
      return Response.forbidden(
        jsonEncode({'error': 'Acesso negado'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    final file = File('uploads/$filePath');
    if (!await file.exists()) {
      return Response.notFound(
        jsonEncode({'error': 'Arquivo nao encontrado'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    final bytes = await file.readAsBytes();
    final contentType = filePath.endsWith('.png') ? 'image/png' : 'image/jpeg';
    return Response.ok(bytes, headers: {
      'Content-Type': contentType,
      'Cache-Control': 'public, max-age=86400',
    });
  });

  // Montar módulos
  app.mount('/api/auth/', authRouter.router.call);
  app.mount('/api/categorias/', categoriasRouter.router.call);
  app.mount('/api/produtos/', produtosRouter(produtosController).call);
  app.mount('/api/estoque/', estoqueRouter(estoqueController).call);
  app.mount('/api/vendas/', vendasRouter(vendasController).call);
  app.mount('/api/caixas/', caixasRouter(caixasController).call);
  app.mount('/api/clientes/', clientesRouter.router.call);
  app.mount('/api/fornecedores/', fornecedoresRouter.router.call);
  app.mount('/api/configuracoes/', configuracoesRouter.router.call);
  app.mount('/api/compras/', comprasRouter(comprasController).call);
  app.mount('/api/emitente/', emitenteRouter(emitenteController).call);
  app.mount('/api/contas-receber/', contasReceberRouter(contasReceberController).call);
  app.mount('/api/contas-pagar/', contasPagarRouter(contasPagarController).call);
  app.mount('/api/servicos/', servicosRouter(servicosController).call);
  app.mount('/api/ordens-servico/', ordensServicoRouter(ordensServicoController).call);
  app.mount('/api/crediario/', crediarioRouter(crediarioController).call);
  app.mount('/api/devolucoes/', devolucoesRouter(devolucoesController).call);
  app.mount('/api/backup/', backupRouter(backupController).call);

  // Pipeline: log -> cors -> trailing slash -> error -> rotas
  final handler = Pipeline()
      .addMiddleware(logMiddleware())
      .addMiddleware(corsMiddleware())
      .addMiddleware(_trailingSlashMiddleware())
      .addMiddleware(errorMiddleware())
      .addHandler(app.call);

  // Iniciar servidor
  print('[4/4] Iniciando servidor...');
  final server = await shelf_io.serve(
    handler,
    ServerConfig.host,
    ServerConfig.port,
  );

  print('');
  print('====================================');
  print(' Servidor rodando em:');
  print(' http://${server.address.host}:${server.port}');
  print('====================================');
  print('');
  print('Endpoints disponíveis:');
  print('  GET  /api/health');
  print('  POST /api/auth/login');
  print('  POST /api/auth/logout');
  print('  POST /api/auth/alterar-senha');
  print('  GET  /api/categorias');
  print('  GET  /api/produtos');
  print('  GET  /api/estoque/posicao');
  print('  GET  /api/vendas');
  print('  POST /api/vendas');
  print('  GET  /api/caixas');
  print('  POST /api/caixas/lancamento');
  print('  GET  /api/clientes');
  print('  POST /api/clientes');
  print('  GET  /api/fornecedores');
  print('  POST /api/fornecedores');
  print('  GET  /api/compras');
  print('  POST /api/compras');
  print('  GET  /api/configuracoes');
  print('  POST /api/produtos/<id>/imagem');
  print('  GET  /uploads/<path>');
  print('  GET  /api/configuracoes/usuarios');
  print('  GET  /api/emitente');
  print('  GET  /api/contas-receber');
  print('  POST /api/contas-receber');
  print('  GET  /api/servicos');
  print('  POST /api/servicos');
  print('  GET  /api/ordens-servico');
  print('  POST /api/ordens-servico');
  print('  GET  /api/crediario');
  print('  POST /api/crediario/<id>/pagar');
  print('  GET  /api/devolucoes');
  print('  POST /api/devolucoes');
  print('  GET  /api/contas-pagar');
  print('  POST /api/contas-pagar');
  print('  GET  /api/devolucoes/creditos');
  print('');
  print('Pressione Ctrl+C para parar.');

  // Graceful shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('\nDesligando servidor...');
    server.close();
    await Database.close();
    print('Servidor desligado.');
    exit(0);
  });
}

/// Middleware que adiciona trailing slash para paths de módulos API
/// shelf_router mount() exige que requests tenham trailing slash
const _apiPrefixes = [
  '/api/auth',
  '/api/categorias',
  '/api/produtos',
  '/api/estoque',
  '/api/vendas',
  '/api/caixas',
  '/api/clientes',
  '/api/fornecedores',
  '/api/configuracoes',
  '/api/compras',
  '/api/emitente',
  '/api/contas-receber',
  '/api/contas-pagar',
  '/api/servicos',
  '/api/ordens-servico',
  '/api/crediario',
  '/api/devolucoes',
  '/api/backup',
];

Middleware _trailingSlashMiddleware() {
  return (Handler innerHandler) {
    return (Request request) {
      final path = request.requestedUri.path;

      // Verificar se o path é exatamente um prefixo de módulo (sem trailing slash)
      for (final prefix in _apiPrefixes) {
        if (path == prefix) {
          final newUri = request.requestedUri.replace(path: '$path/');
          return innerHandler(
            Request(
              request.method,
              newUri,
              headers: request.headers,
              body: request.read(),
              context: request.context,
            ),
          );
        }
      }

      return innerHandler(request);
    };
  };
}

/// Add new permission columns if they don't exist yet
Future<void> _migratePermissions() async {
  const newCols = {
    'perm_pdv': '1',
    'perm_produtos': '0',
    'perm_vendas': '0',
    'perm_compras': '0',
    'perm_clientes': '1',
    'perm_categorias': '0',
    'perm_contas_receber': '0',
    'perm_contas_pagar': '0',
    'perm_servicos': '0',
    'perm_ordens_servico': '0',
    'perm_devolucoes': '0',
    'perm_relatorios': '0',
  };
  for (final entry in newCols.entries) {
    try {
      await Database.instance.execute(
        'ALTER TABLE usuarios ADD COLUMN ${entry.key} TINYINT(1) DEFAULT ${entry.value}',
        {},
      );
    } catch (_) {
      // Column already exists — ignore
    }
  }
}

/// Verifica se o admin tem hash placeholder e gera hash real para admin123
Future<void> _fixAdminPassword() async {
  try {
    final results = await Database.instance.query(
      'SELECT id, senha_hash FROM usuarios WHERE login = :login',
      {'login': 'admin'},
    );

    if (results.isEmpty) {
      print('      Admin não encontrado. Pulando correção.');
      return;
    }

    final senhaHash = results.first['senha_hash'] ?? '';

    // Verificar se é o placeholder do seed
    if (senhaHash.contains('hash_do_bcrypt_aqui') || senhaHash.length < 20) {
      print('      Hash placeholder detectado. Gerando hash real para admin123...');
      final novoHash = PasswordHasher.hash('admin123');
      await Database.instance.execute(
        'UPDATE usuarios SET senha_hash = :hash WHERE login = :login',
        {'hash': novoHash, 'login': 'admin'},
      );
      print('      Senha do admin atualizada! (admin / admin123)');
    } else {
      print('      Senha do admin OK.');
    }
  } catch (e) {
    print('      Aviso: Erro ao verificar admin: $e');
  }
}
