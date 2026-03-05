import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../providers/pdv_provider.dart';

class PdvHeader extends StatelessWidget {
  final VoidCallback onMenuPressed;
  PdvHeader({super.key, required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final produto = pdv.produtoAtual;
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.accent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  produto?.descricao.toUpperCase() ?? 'AGUARDANDO PRODUTO...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 4, color: Color(0x80000000))
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (produto != null && pdv.itens.isNotEmpty)
                  Text(
                    '${pdv.itens.last.quantidade} x ${currencyFormat.format(produto.precoVenda)}',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
              ],
            ),
          ),
          // Menu / Exit button
          Material(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onMenuPressed,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.menu, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
