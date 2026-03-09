import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/produtos_provider.dart';
import '../../providers/vendas_provider.dart';
import '../../providers/caixas_provider.dart';
import '../../providers/estoque_provider.dart';
import '../../providers/relatorios_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/charts/chart_card.dart';
import '../../widgets/charts/sales_line_chart.dart';
import '../../widgets/charts/payment_pie_chart.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  DashboardScreen({super.key, this.onNavigate});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  int _totalProdutos = 0;
  int _estoqueBaixo = 0;
  int _totalVendas = 0;
  double _saldoCaixa = 0;
  double _faturamentoHoje = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final produtos = context.read<ProdutosProvider>();
      final vendas = context.read<VendasProvider>();
      final caixas = context.read<CaixasProvider>();
      final estoque = context.read<EstoqueProvider>();
      final isAdmin = context.read<AuthProvider>().papelUsuario == 'admin';

      final now = DateTime.now();
      final inicio7d = now.subtract(Duration(days: 7));

      final futures = <Future>[
        produtos.carregarProdutos(),
        vendas.carregarVendas(),
        caixas.carregarCaixas(),
        estoque.carregarAbaixoMinimo(),
      ];

      RelatoriosProvider? relatorios;
      if (isAdmin) {
        relatorios = context.read<RelatoriosProvider>();
        futures.add(relatorios.carregarDadosGraficos(
          dataInicio: inicio7d.toIso8601String().split('T').first,
          dataFim: now.toIso8601String().split('T').first,
        ));
      }

      await Future.wait(futures);

      if (mounted) {
        // Calcular faturamento de hoje
        double fatHoje = 0;
        if (isAdmin && relatorios != null) {
          final hoje = now.toIso8601String().split('T').first;
          for (final d in relatorios.resumoDiario) {
            if (d['data'] == hoje) {
              fatHoje = ((d['total_vendas'] as num?) ?? 0).toDouble();
              break;
            }
          }
        }

        setState(() {
          _totalProdutos = produtos.total;
          _estoqueBaixo = estoque.abaixoMinimo.length;
          _totalVendas = vendas.total;
          _saldoCaixa = caixas.caixas.fold(0.0, (sum, c) => sum + c.saldoAtual);
          _faturamentoHoje = fatHoje;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final isAdmin = context.read<AuthProvider>().papelUsuario == 'admin';

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? LoadingWidget(message: 'Carregando dados...')
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        IconButton(
                          icon: Icon(Icons.refresh, color: AppTheme.textSecondary),
                          onPressed: _loadData,
                          tooltip: 'Atualizar',
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Stat cards
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        StatCard(label: 'Total de Produtos', value: _totalProdutos.toString(), icon: Icons.inventory_2_outlined),
                        StatCard(label: 'Estoque Baixo', value: _estoqueBaixo.toString(), icon: Icons.warning_amber_outlined, valueColor: _estoqueBaixo > 0 ? AppTheme.error : null),
                        StatCard(label: 'Total de Vendas', value: _totalVendas.toString(), icon: Icons.receipt_long_outlined),
                        if (isAdmin)
                          StatCard(label: 'Saldo em Caixa', value: currencyFormat.format(_saldoCaixa), icon: Icons.account_balance_wallet_outlined, valueColor: AppTheme.greenSuccess),
                        if (isAdmin)
                          StatCard(label: 'Faturamento Hoje', value: currencyFormat.format(_faturamentoHoje), icon: Icons.trending_up, valueColor: AppTheme.primary),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Charts row
                    if (isAdmin)
                      Consumer<RelatoriosProvider>(
                        builder: (context, relProv, _) {
                          if (relProv.isLoadingCharts) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: ChartCard(
                                  title: 'Vendas - Ultimos 7 dias',
                                  height: 180,
                                  chart: SalesLineChart(
                                    data: relProv.resumoDiario,
                                    currencyFormat: currencyFormat,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ChartCard(
                                  title: 'Formas de Pagamento',
                                  height: 180,
                                  chart: PaymentPieChart(
                                    data: relProv.porFormaPagamento,
                                    currencyFormat: currencyFormat,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    SizedBox(height: 24),

                    // Quick actions
                    Text('Acesso Rapido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _QuickAction(icon: Icons.point_of_sale, label: 'Abrir PDV', color: AppTheme.primary, onTap: () {
                          widget.onNavigate?.call(1);
                        }),
                        _QuickAction(icon: Icons.add_box_outlined, label: 'Novo Produto', color: AppTheme.accent, onTap: () {
                          widget.onNavigate?.call(2);
                        }),
                        _QuickAction(icon: Icons.warehouse_outlined, label: 'Ver Estoque', color: AppTheme.yellowWarning, onTap: () {
                          widget.onNavigate?.call(3);
                        }),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, this.onTap});

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 140,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withOpacity(0.1) : AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: _hovered ? widget.color : AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 32, color: widget.color),
              SizedBox(height: 8),
              Text(widget.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
