import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../providers/pdv_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/api_client.dart';
import '../../../config/api_config.dart';

class PdvCartTable extends StatelessWidget {
  PdvCartTable({super.key});

  Widget _buildWatermark(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    if (!tp.showWatermark || tp.logoPath == null) return SizedBox.shrink();

    Widget image;
    final path = tp.logoPath!;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      image = Image.network(path, width: 300, height: 300, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => SizedBox.shrink());
    } else {
      final file = File(path);
      if (!file.existsSync()) return SizedBox.shrink();
      image = Image.file(file, width: 300, height: 300, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => SizedBox.shrink());
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Opacity(opacity: tp.watermarkOpacity, child: image),
        ),
      ),
    );
  }

  Future<void> _tentarRemoverItem(BuildContext context, int index) async {
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.papelUsuario == 'admin';

    if (isAdmin) {
      context.read<PdvProvider>().removerItem(index);
    } else {
      final autorizado = await showDialog<bool>(
        context: context,
        builder: (_) => const _AdminAuthDialog(),
      );
      if (autorizado == true && context.mounted) {
        context.read<PdvProvider>().removerItem(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      color: AppTheme.scaffoldBackground,
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.isDark
                  ? const Color(0xFF1a2a3e)
                  : AppTheme.primary.withValues(alpha: 0.08),
              border: Border(
                  bottom: BorderSide(color: AppTheme.primary, width: 2)),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text('PRODUTO',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 1,
                            fontFamily: 'Consolas'))),
                SizedBox(
                    width: 80,
                    child: Text('QTD',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 1,
                            fontFamily: 'Consolas'),
                        textAlign: TextAlign.center)),
                SizedBox(
                    width: 120,
                    child: Text('PRECO',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 1,
                            fontFamily: 'Consolas'),
                        textAlign: TextAlign.right)),
                SizedBox(
                    width: 120,
                    child: Text('TOTAL',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 1,
                            fontFamily: 'Consolas'),
                        textAlign: TextAlign.right)),
                SizedBox(width: 40),
              ],
            ),
          ),
          // Table body
          Expanded(
            child: Stack(
              children: [
                // Watermark logo
                _buildWatermark(context),
                // Content
                if (pdv.isEmpty)
                  Center(
                    child: Text('Nenhum item adicionado',
                        style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textMuted,
                            fontFamily: 'Consolas')),
                  )
                else
                  ListView.builder(
                    itemCount: pdv.itens.length,
                    itemBuilder: (context, index) {
                      final item = pdv.itens[index];
                      final isLast = index == pdv.itens.length - 1;
                      final isOdd = index.isOdd;

                      final rowColor = isLast
                          ? (AppTheme.isDark
                              ? const Color(0xFF0d3b66)
                              : AppTheme.primary.withValues(alpha: 0.08))
                          : isOdd
                              ? (AppTheme.isDark
                                  ? const Color(0xFF121e2b)
                                  : const Color(0xFFF0F4F8))
                              : AppTheme.scaffoldBackground;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: rowColor,
                          border: Border(
                              bottom: BorderSide(
                                  color: AppTheme.border.withValues(alpha: 0.5))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 4,
                                child: Text(item.descricao,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.textPrimary,
                                        fontFamily: 'Consolas'),
                                    overflow: TextOverflow.ellipsis)),
                            SizedBox(
                                width: 80,
                                child: Text(item.quantidade.toString(),
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.textPrimary,
                                        fontFamily: 'Consolas'),
                                    textAlign: TextAlign.center)),
                            SizedBox(
                                width: 120,
                                child: Text(
                                    currencyFormat
                                        .format(item.precoUnitario),
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.textPrimary,
                                        fontFamily: 'Consolas'),
                                    textAlign: TextAlign.right)),
                            SizedBox(
                                width: 120,
                                child: Text(
                                    currencyFormat.format(item.subtotal),
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.greenSuccess,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Consolas'),
                                    textAlign: TextAlign.right)),
                            SizedBox(
                              width: 40,
                              child: IconButton(
                                icon: Icon(Icons.close,
                                    size: 18, color: AppTheme.error),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                tooltip: 'Remover item',
                                onPressed: () =>
                                    _tentarRemoverItem(context, index),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminAuthDialog extends StatefulWidget {
  const _AdminAuthDialog();

  @override
  State<_AdminAuthDialog> createState() => _AdminAuthDialogState();
}

class _AdminAuthDialogState extends State<_AdminAuthDialog> {
  final _loginCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _validar() async {
    final login = _loginCtrl.text.trim();
    final senha = _senhaCtrl.text.trim();

    if (login.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Preencha login e senha');
      return;
    }

    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final api = context.read<ApiClient>();
      await api.post(ApiConfig.validarAdmin, body: {
        'login': login,
        'senha': senha,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _loading = false;
        _erro = 'Login ou senha de administrador invalidos';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: AppTheme.yellowWarning, size: 22),
          SizedBox(width: 8),
          Text('Autorizacao do Administrador',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Para remover um item, informe as credenciais de um administrador.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _loginCtrl,
            autofocus: true,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Login do admin',
              prefixIcon:
                  Icon(Icons.person_outline, color: AppTheme.textSecondary, size: 20),
            ),
            onSubmitted: (_) => _validar(),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _senhaCtrl,
            obscureText: true,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon:
                  Icon(Icons.lock_outline, color: AppTheme.textSecondary, size: 20),
            ),
            onSubmitted: (_) => _validar(),
          ),
          if (_erro != null) ...[
            SizedBox(height: 12),
            Text(_erro!,
                style: TextStyle(fontSize: 13, color: AppTheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _validar,
          child: _loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Autorizar'),
        ),
      ],
    );
  }
}
