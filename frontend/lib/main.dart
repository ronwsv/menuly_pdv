import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'providers/pdv_provider.dart';
import 'providers/produtos_provider.dart';
import 'providers/estoque_provider.dart';
import 'providers/vendas_provider.dart';
import 'providers/caixas_provider.dart';
import 'providers/clientes_provider.dart';
import 'providers/fornecedores_provider.dart';
import 'providers/categorias_provider.dart';
import 'providers/configuracoes_provider.dart';
import 'providers/compras_provider.dart';
import 'providers/relatorios_provider.dart';
import 'providers/contas_receber_provider.dart';
import 'providers/servicos_provider.dart';
import 'providers/ordens_servico_provider.dart';
import 'providers/contas_pagar_provider.dart';
import 'providers/crediario_provider.dart';
import 'providers/devolucoes_provider.dart';
import 'providers/backup_provider.dart';
import 'providers/theme_provider.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await windowManager.setTitle('Menuly PDV');
  await windowManager.setMinimumSize(const Size(1024, 600));

  final apiClient = ApiClient();
  final authService = AuthService(apiClient);
  final authProvider = AuthProvider(authService);

  // Auto-logout quando o backend retornar 401
  apiClient.onUnauthorized = () => authProvider.logout();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => PdvProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ProdutosProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => EstoqueProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => VendasProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => CaixasProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ClientesProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => FornecedoresProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => CategoriasProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ComprasProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ConfiguracoesProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => RelatoriosProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ContasReceberProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ContasPagarProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => CrediarioProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ServicosProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => OrdensServicoProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => DevolucoesProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => BackupProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MenulyApp(),
    ),
  );
}
