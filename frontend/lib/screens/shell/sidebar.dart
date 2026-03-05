import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.point_of_sale, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(text: 'Menuly ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    TextSpan(text: 'PDV', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                  ]),
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: [
                if (auth.temPermissaoMenu(0))
                  _MenuItem(icon: Icons.dashboard_outlined, label: 'Dashboard', index: 0, selected: selectedIndex == 0, onTap: onItemSelected),
                if (auth.temPermissaoMenu(1))
                  _MenuItem(icon: Icons.point_of_sale, label: 'PDV - Frente de Caixa', index: 1, selected: false, onTap: onItemSelected),
                if ([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15].any((i) => auth.temPermissaoMenu(i))) ...[
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('MÓDULOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted, letterSpacing: 1)),
                  ),
                ],
                if (auth.temPermissaoMenu(2))
                  _MenuItem(icon: Icons.inventory_2_outlined, label: 'Produtos', index: 2, selected: selectedIndex == 2, onTap: onItemSelected),
                if (auth.temPermissaoMenu(3))
                  _MenuItem(icon: Icons.warehouse_outlined, label: 'Estoque', index: 3, selected: selectedIndex == 3, onTap: onItemSelected),
                if (auth.temPermissaoMenu(4))
                  _MenuItem(icon: Icons.receipt_long_outlined, label: 'Vendas', index: 4, selected: selectedIndex == 4, onTap: onItemSelected),
                if (auth.temPermissaoMenu(5))
                  _MenuItem(icon: Icons.shopping_cart_outlined, label: 'Compras', index: 5, selected: selectedIndex == 5, onTap: onItemSelected),
                if (auth.temPermissaoMenu(6))
                  _MenuItem(icon: Icons.people_outlined, label: 'Clientes', index: 6, selected: selectedIndex == 6, onTap: onItemSelected),
                if (auth.temPermissaoMenu(7))
                  _MenuItem(icon: Icons.local_shipping_outlined, label: 'Fornecedores', index: 7, selected: selectedIndex == 7, onTap: onItemSelected),
                if (auth.temPermissaoMenu(8))
                  _MenuItem(icon: Icons.category_outlined, label: 'Categorias', index: 8, selected: selectedIndex == 8, onTap: onItemSelected),
                if (auth.temPermissaoMenu(9))
                  _MenuItem(icon: Icons.account_balance_wallet_outlined, label: 'Caixas', index: 9, selected: selectedIndex == 9, onTap: onItemSelected),
                if (auth.temPermissaoMenu(10))
                  _MenuItem(icon: Icons.request_quote_outlined, label: 'Contas a Receber', index: 10, selected: selectedIndex == 10, onTap: onItemSelected),
                if (auth.temPermissaoMenu(11))
                  _MenuItem(icon: Icons.money_off_outlined, label: 'Contas a Pagar', index: 11, selected: selectedIndex == 11, onTap: onItemSelected),
                if (auth.temPermissaoMenu(12))
                  _MenuItem(icon: Icons.credit_score_outlined, label: 'Crediario', index: 12, selected: selectedIndex == 12, onTap: onItemSelected),
                if (auth.temPermissaoMenu(13))
                  _MenuItem(icon: Icons.build_outlined, label: 'Servicos', index: 13, selected: selectedIndex == 13, onTap: onItemSelected),
                if (auth.temPermissaoMenu(14))
                  _MenuItem(icon: Icons.assignment_outlined, label: 'Ordens de Servico', index: 14, selected: selectedIndex == 14, onTap: onItemSelected),
                if (auth.temPermissaoMenu(15))
                  _MenuItem(icon: Icons.swap_horiz_outlined, label: 'Trocas e Devoluções', index: 15, selected: selectedIndex == 15, onTap: onItemSelected),
                if (auth.temPermissaoMenu(16) || auth.temPermissaoMenu(17)) ...[
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('GESTAO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted, letterSpacing: 1)),
                  ),
                ],
                if (auth.temPermissaoMenu(16))
                  _MenuItem(icon: Icons.bar_chart_outlined, label: 'Relatorios', index: 16, selected: selectedIndex == 16, onTap: onItemSelected),
                if (auth.temPermissaoMenu(17))
                  _MenuItem(icon: Icons.settings_outlined, label: 'Configuracoes', index: 17, selected: selectedIndex == 17, onTap: onItemSelected),
              ],
            ),
          ),

          // Footer - operator info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppTheme.greenSuccess,
                  child: Text(
                    auth.nomeUsuario.isNotEmpty ? auth.nomeUsuario[0].toUpperCase() : 'O',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(auth.nomeUsuario, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis),
                      Text(auth.papelUsuario, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.logout, size: 20, color: AppTheme.textSecondary),
                  onPressed: () => auth.logout(),
                  tooltip: 'Sair',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool selected;
  final ValueChanged<int> onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => widget.onTap(widget.index),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primary.withOpacity(0.15)
                  : _isHovered
                      ? Color(0xFF253347)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: isActive ? Border.all(color: AppTheme.primary.withOpacity(0.3)) : null,
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 20, color: isActive ? AppTheme.accent : AppTheme.textSecondary),
                SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
