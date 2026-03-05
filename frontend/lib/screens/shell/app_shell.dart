import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../providers/auth_provider.dart';
import '../../providers/configuracoes_provider.dart';
import '../../providers/theme_provider.dart';
import 'sidebar.dart';
import '../dashboard/dashboard_screen.dart';
import '../pdv/pdv_screen.dart';
import '../produtos/produtos_screen.dart';
import '../estoque/estoque_screen.dart';
import '../vendas/vendas_screen.dart';
import '../compras/compras_screen.dart';
import '../clientes/clientes_screen.dart';
import '../fornecedores/fornecedores_screen.dart';
import '../categorias/categorias_screen.dart';
import '../caixas/caixas_screen.dart';
import '../contas_receber/contas_receber_screen.dart';
import '../contas_pagar/contas_pagar_screen.dart';
import '../crediario/crediario_screen.dart';
import '../servicos/servicos_screen.dart';
import '../ordens_servico/ordens_servico_screen.dart';
import '../devolucoes/devolucoes_screen.dart';
import '../relatorios/relatorios_screen.dart';
import '../configuracoes/configuracoes_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _isPdvFullscreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarTema();
    });
  }

  Future<void> _carregarTema() async {
    final configProvider = context.read<ConfiguracoesProvider>();
    await configProvider.carregarConfigs();
    if (!mounted) return;
    context.read<ThemeProvider>().carregarConfigs(configProvider);
  }

  void _onMenuSelected(int index) {
    final auth = context.read<AuthProvider>();
    if (!auth.temPermissaoMenu(index)) return;

    if (index == 1) {
      // PDV opens in native fullscreen mode
      windowManager.setFullScreen(true);
      setState(() => _isPdvFullscreen = true);
    } else {
      setState(() {
        _selectedIndex = index;
        _isPdvFullscreen = false;
      });
    }
  }

  void _exitPdv() {
    windowManager.setFullScreen(false);
    setState(() => _isPdvFullscreen = false);
  }

  List<Widget> get _screens => <Widget>[
    DashboardScreen(onNavigate: _onMenuSelected),  // 0
    const Placeholder(),                             // 1 - PDV placeholder (fullscreen)
    ProdutosScreen(),                          // 2
    EstoqueScreen(),                           // 3
    VendasScreen(),                            // 4
    ComprasScreen(),                           // 5
    ClientesScreen(),                          // 6
    FornecedoresScreen(),                      // 7
    CategoriasScreen(),                        // 8
    CaixasScreen(),                            // 9
    ContasReceberScreen(),                     // 10
    ContasPagarScreen(),                       // 11
    CrediarioScreen(),                         // 12
    ServicosScreen(),                          // 13
    OrdensServicoScreen(),                     // 14
    DevolucoesScreen(),                        // 15
    RelatoriosScreen(),                        // 16
    ConfiguracoesScreen(),                     // 17
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    context.watch<ThemeProvider>(); // Rebuild when theme changes

    if (_isPdvFullscreen) {
      return PdvScreen(
        onExit: _exitPdv,
      );
    }

    // Guard: if current index is not allowed, fall back to Dashboard
    final effectiveIndex =
        auth.temPermissaoMenu(_selectedIndex) ? _selectedIndex : 0;

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: effectiveIndex,
            onItemSelected: _onMenuSelected,
          ),
          Expanded(
            child: _screens[effectiveIndex],
          ),
        ],
      ),
    );
  }
}
