import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../config/api_config.dart';
import '../../../providers/pdv_provider.dart';

class PdvControlPanel extends StatefulWidget {
  final FocusNode barcodeFocusNode;
  final VoidCallback onPayment;
  final VoidCallback onDiscount;
  final VoidCallback onCancel;
  final VoidCallback onShortcutsHelp;
  final VoidCallback onGaveta;
  final VoidCallback onInformarCliente;
  final VoidCallback onSalvarOrcamento;

  PdvControlPanel({
    super.key,
    required this.barcodeFocusNode,
    required this.onPayment,
    required this.onDiscount,
    required this.onCancel,
    required this.onShortcutsHelp,
    required this.onGaveta,
    required this.onInformarCliente,
    required this.onSalvarOrcamento,
  });

  @override
  State<PdvControlPanel> createState() => _PdvControlPanelState();
}

class _PdvControlPanelState extends State<PdvControlPanel> {
  final _barcodeController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _showResults = false;
  String? _searchError;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeSubmitted(String value) async {
    if (value.trim().isEmpty) return;
    final pdv = context.read<PdvProvider>();

    // Try exact barcode match first
    final produto = await pdv.buscarProdutoPorBarcode(value.trim());
    if (produto != null) {
      pdv.adicionarProduto(produto);
      _barcodeController.clear();
      setState(() => _showResults = false);
      return;
    }

    // If no barcode match, search by name
    final results = await pdv.buscarProdutos(value.trim());
    if (results.length == 1) {
      pdv.adicionarProduto(results.first);
      _barcodeController.clear();
      setState(() {
        _showResults = false;
        _searchError = null;
      });
    } else if (results.isNotEmpty) {
      setState(() {
        _searchResults = results;
        _showResults = true;
        _searchError = null;
      });
    } else {
      setState(() {
        _searchError = pdv.error;
      });
    }
  }

  void _onSearchChanged(String value) async {
    if (value.length < 2) {
      setState(() {
        _showResults = false;
        _searchError = null;
      });
      return;
    }
    final pdv = context.read<PdvProvider>();
    final results = await pdv.buscarProdutos(value);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _showResults = results.isNotEmpty;
        _searchError = results.isEmpty ? pdv.error : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      color: AppTheme.cardSurface,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Main column content
          Column(
            children: [
              // Barcode input
              TextField(
                controller: _barcodeController,
                focusNode: widget.barcodeFocusNode,
                style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Consolas',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333)),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Codigo de barras ou busca',
                  hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      fontFamily: 'Consolas'),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(
                          color: AppTheme.primary, width: 2)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(
                          color: AppTheme.primary, width: 2)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(
                          color: AppTheme.accent, width: 2)),
                  prefixIcon: Icon(Icons.qr_code_scanner,
                      color: AppTheme.primary),
                ),
                onSubmitted: _onBarcodeSubmitted,
                onChanged: _onSearchChanged,
              ),
              if (_searchError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _searchError!,
                    style: TextStyle(fontSize: 11, color: AppTheme.error),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              SizedBox(height: 16),

          // Total box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryDark,
                  AppTheme.primary,
                  AppTheme.accent
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [
                BoxShadow(
                    color: Color(0x660a3d6b),
                    blurRadius: 16,
                    offset: Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                Text('TOTAL',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 2)),
                SizedBox(height: 4),
                Text(currencyFormat.format(pdv.total),
                    style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
          ),

          // Discount info
          if (pdv.descontoValor > 0) ...[
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Desconto: -${currencyFormat.format(pdv.descontoValor)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          SizedBox(height: 8),
          // Item count
          Text(
              '${pdv.totalItens} ${pdv.totalItens == 1 ? "item" : "itens"} no carrinho',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),

          // Product image
          if (pdv.produtoAtual?.imagemPath != null &&
              pdv.produtoAtual!.imagemPath!.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Image.network(
                      ApiConfig.uploadUrl(pdv.produtoAtual!.imagemPath!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            )
          else
            Spacer(),

          // Shortcut buttons
          _ShortcutButton(
              label: 'Finalizar',
              shortcut: 'F9',
              color: AppTheme.greenSuccess,
              icon: Icons.check_circle_outline,
              onPressed: pdv.isEmpty ? null : widget.onPayment),
          SizedBox(height: 8),
          _ShortcutButton(
              label: 'Salvar Orcamento',
              shortcut: 'F7',
              color: AppTheme.primary,
              icon: Icons.save_outlined,
              onPressed: pdv.isEmpty ? null : widget.onSalvarOrcamento),
          SizedBox(height: 8),
          _ShortcutButton(
              label: 'Informar Cliente',
              color: AppTheme.primary,
              icon: Icons.person_outline,
              onPressed: widget.onInformarCliente),
          SizedBox(height: 8),
          _ShortcutButton(
              label: 'Cancelar',
              shortcut: 'F12',
              color: AppTheme.error,
              icon: Icons.cancel_outlined,
              onPressed: pdv.isEmpty ? null : widget.onCancel),
        ],
          ),

          // Search results dropdown - rendered ON TOP of everything
          if (_showResults)
            Positioned(
              left: 0,
              right: 0,
              top: 56,
              child: Material(
                elevation: 8,
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 24,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final p = _searchResults[index];
                      return InkWell(
                        onTap: () {
                          context
                              .read<PdvProvider>()
                              .adicionarProduto(p);
                          _barcodeController.clear();
                          setState(() => _showResults = false);
                          widget.barcodeFocusNode.requestFocus();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: AppTheme.border))),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(p.descricao,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      AppTheme.textPrimary),
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        ),
                                        if (p.tamanho != null && p.tamanho!.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(p.tamanho!,
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.primary)),
                                          ),
                                      ],
                                    ),
                                    Text(p.codigoBarras ?? '',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      currencyFormat
                                          .format(p.precoVenda),
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              AppTheme.greenSuccess)),
                                  Text(
                                      'Est: ${p.estoqueEfetivo}${p.isCombo ? ' (combo)' : ''}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: p.estoqueEfetivo <= 0
                                              ? AppTheme.error
                                              : AppTheme.textMuted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShortcutButton extends StatefulWidget {
  final String label;
  final String? shortcut;
  final Color color;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ShortcutButton(
      {required this.label,
      this.shortcut,
      required this.color,
      required this.icon,
      this.onPressed});

  @override
  State<_ShortcutButton> createState() => _ShortcutButtonState();
}

class _ShortcutButtonState extends State<_ShortcutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered && enabled
                ? widget.color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
                color: enabled
                    ? (_hovered ? widget.color : AppTheme.border)
                    : AppTheme.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              if (widget.shortcut != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color
                        .withValues(alpha: enabled ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(widget.shortcut!,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? widget.color
                              : AppTheme.textMuted)),
                )
              else
                SizedBox(width: 8),
              SizedBox(width: 12),
              Icon(widget.icon,
                  size: 18,
                  color: enabled ? widget.color : AppTheme.textMuted),
              SizedBox(width: 8),
              Text(widget.label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? AppTheme.textPrimary
                          : AppTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
