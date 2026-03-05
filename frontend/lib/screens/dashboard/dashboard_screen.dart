import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/produtos_provider.dart';
import '../../providers/vendas_provider.dart';
import '../../providers/caixas_provider.dart';
import '../../providers/estoque_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/loading_widget.dart';

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

      await Future.wait([
        produtos.carregarProdutos(),
        vendas.carregarVendas(),
        caixas.carregarCaixas(),
        estoque.carregarAbaixoMinimo(),
      ]);

      if (mounted) {
        setState(() {
          _totalProdutos = produtos.total;
          _estoqueBaixo = estoque.abaixoMinimo.length;
          _totalVendas = vendas.total;
          _saldoCaixa = caixas.caixas.fold(0.0, (sum, c) => sum + c.saldoAtual);
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
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

            if (_isLoading)
              Expanded(child: LoadingWidget(message: 'Carregando dados...'))
            else ...[
              // Stat cards
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  StatCard(label: 'Total de Produtos', value: _totalProdutos.toString(), icon: Icons.inventory_2_outlined),
                  StatCard(label: 'Estoque Baixo', value: _estoqueBaixo.toString(), icon: Icons.warning_amber_outlined, valueColor: _estoqueBaixo > 0 ? AppTheme.error : null),
                  StatCard(label: 'Total de Vendas', value: _totalVendas.toString(), icon: Icons.receipt_long_outlined),
                  if (context.read<AuthProvider>().papelUsuario == 'admin')
                    StatCard(label: 'Saldo em Caixa', value: currencyFormat.format(_saldoCaixa), icon: Icons.account_balance_wallet_outlined, valueColor: AppTheme.greenSuccess),
                ],
              ),
              SizedBox(height: 32),

              // Quick actions
              Text('Acesso Rápido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
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
          ],
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
