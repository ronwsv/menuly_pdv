import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../providers/pdv_provider.dart';

class DiscountDialog extends StatefulWidget {
  DiscountDialog({super.key});
  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  bool _isPercentual = false;
  final _valorController = TextEditingController();

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  void _aplicar() {
    final valor =
        double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0;
    if (valor <= 0) return;
    context
        .read<PdvProvider>()
        .aplicarDesconto(valor, percentual: _isPercentual);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Aplicar Desconto',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  IconButton(
                      icon: Icon(Icons.close,
                          color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              SizedBox(height: 8),
              Text('Subtotal: ${currencyFormat.format(pdv.subtotal)}',
                  style: TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center),
              SizedBox(height: 20),

              // Type toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPercentual = false),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isPercentual
                              ? AppTheme.primary
                                  .withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd),
                          border: Border.all(
                              color: !_isPercentual
                                  ? AppTheme.primary
                                  : AppTheme.border),
                        ),
                        child: Text('R\$ Valor',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: !_isPercentual
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary),
                            textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPercentual = true),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isPercentual
                              ? AppTheme.primary
                                  .withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd),
                          border: Border.all(
                              color: _isPercentual
                                  ? AppTheme.primary
                                  : AppTheme.border),
                        ),
                        child: Text('% Percentual',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _isPercentual
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary),
                            textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Value input
              TextField(
                controller: _valorController,
                autofocus: true,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: _isPercentual ? '0 %' : '0,00',
                  prefixText: _isPercentual ? null : 'R\$ ',
                  suffixText: _isPercentual ? '%' : null,
                  filled: true,
                  fillColor: AppTheme.inputFill,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      borderSide:
                          BorderSide(color: AppTheme.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      borderSide:
                          BorderSide(color: AppTheme.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(
                          color: AppTheme.primary, width: 2)),
                ),
                onSubmitted: (_) => _aplicar(),
              ),
              SizedBox(height: 20),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _aplicar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                  child: Text('Aplicar Desconto',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
