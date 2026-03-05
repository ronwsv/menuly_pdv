import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../config/api_config.dart';
import '../../models/cliente.dart';
import '../../models/configuracao.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caixas_provider.dart';
import '../../providers/configuracoes_provider.dart';
import '../../providers/pdv_provider.dart';
import '../../services/api_client.dart';
import 'widgets/discount_dialog.dart';
import 'widgets/payment_dialog.dart';
import 'widgets/pdv_cart_table.dart';
import 'widgets/pdv_control_panel.dart';
import 'widgets/pdv_footer.dart';
import 'widgets/pdv_header.dart';
import 'widgets/troca_devolucao_dialog.dart';

class PdvScreen extends StatefulWidget {
  final VoidCallback onExit;
  PdvScreen({super.key, required this.onExit});
  @override
  State<PdvScreen> createState() => _PdvScreenState();
}

class _PdvScreenState extends State<PdvScreen> {
  final _barcodeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PdvProvider>().carregarEmitente();
      context.read<ConfiguracoesProvider>().carregarConfigs();
      // Carrega caixas e verifica se precisa abrir
      final caixasProvider = context.read<CaixasProvider>();
      caixasProvider.carregarCaixas().then((_) {
        if (!mounted) return;
        final caixa = caixasProvider.caixaSelecionada;
        if (caixa != null && caixa.isFechado) {
          _mostrarAbrirCaixaObrigatorio();
        }
      });
    });
  }

  @override
  void dispose() {
    _barcodeFocus.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final pdv = context.read<PdvProvider>();

    switch (event.logicalKey) {
      case LogicalKeyboardKey.f1:
        _showShortcutsHelp();
        break;
      case LogicalKeyboardKey.f2:
        if (!pdv.isEmpty) _showAlterarQuantidade();
        break;
      case LogicalKeyboardKey.f3:
        _showConsultarPreco();
        break;
      case LogicalKeyboardKey.f4:
        _showBalanca();
        break;
      case LogicalKeyboardKey.f5:
        _abrirGaveta();
        break;
      case LogicalKeyboardKey.f6:
        _showTrocaDevolucao();
        break;
      case LogicalKeyboardKey.f7:
        if (!pdv.isEmpty) _salvarOrcamento();
        break;
      case LogicalKeyboardKey.f8:
        _showEscolherOrcamento();
        break;
      case LogicalKeyboardKey.f9:
        if (!pdv.isEmpty) _showPaymentDialog();
        break;
      case LogicalKeyboardKey.f11:
        _showInformarVendedor();
        break;
      case LogicalKeyboardKey.f12:
        if (!pdv.isEmpty) _confirmCancelSale();
        break;
      case LogicalKeyboardKey.delete:
        if (!pdv.isEmpty) _deleteLastItem();
        break;
      case LogicalKeyboardKey.escape:
        widget.onExit();
        break;
      default:
        break;
    }
  }

  // ── F1: Ajuda ──────────────────────────────────────────────────────────────

  void _showShortcutsHelp() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.keyboard, color: AppTheme.primary, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Atalhos de Teclado',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: AppTheme.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Divider(color: AppTheme.border, height: 24),
              const _ShortcutHelpRow(shortcut: 'F1', description: 'Exibir atalhos de teclado'),
              const _ShortcutHelpRow(shortcut: 'F2', description: 'Alterar quantidade do item'),
              const _ShortcutHelpRow(shortcut: 'F3', description: 'Consultar preco'),
              const _ShortcutHelpRow(shortcut: 'F4', description: 'Balanca (peso serial)'),
              const _ShortcutHelpRow(shortcut: 'F5', description: 'Abrir gaveta de dinheiro'),
              const _ShortcutHelpRow(shortcut: 'F6', description: 'Troca / Devolucao'),
              const _ShortcutHelpRow(shortcut: 'F7', description: 'Salvar como orcamento'),
              const _ShortcutHelpRow(shortcut: 'F8', description: 'Escolher orcamento'),
              const _ShortcutHelpRow(
                  shortcut: 'F9',
                  description: 'Finalizar venda',
                  color: AppTheme.greenSuccess),
              const _ShortcutHelpRow(shortcut: 'F11', description: 'Informar vendedor'),
              const _ShortcutHelpRow(
                  shortcut: 'F12',
                  description: 'Cancelar venda',
                  color: AppTheme.error),
              SizedBox(height: 12),
              Divider(color: AppTheme.border, height: 1),
              SizedBox(height: 12),
              Text('Acoes rapidas',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showDiscountDialog();
                      },
                      icon: Icon(Icons.discount_outlined, size: 16),
                      label: Text('Desconto', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _abrirGaveta();
                      },
                      icon: Icon(Icons.inbox_outlined, size: 16),
                      label: Text('Gaveta', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.laptop, size: 16, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Em notebooks, pode ser necessario pressionar a tecla Fn junto com as teclas F1-F12.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── F2: Alterar Quantidade ─────────────────────────────────────────────────

  void _showAlterarQuantidade() {
    final pdv = context.read<PdvProvider>();
    final ultimo = pdv.itens.last;
    final idx = pdv.itens.length - 1;
    final ctrl = TextEditingController(text: ultimo.quantidade.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Text('Alterar Quantidade',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ultimo.descricao,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
                overflow: TextOverflow.ellipsis),
            SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style:
                  TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              decoration: InputDecoration(labelText: 'Quantidade'),
              onSubmitted: (_) {
                final nova = int.tryParse(ctrl.text.trim());
                if (nova != null && nova > 0) {
                  context.read<PdvProvider>().alterarQuantidade(idx, nova);
                }
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final nova = int.tryParse(ctrl.text.trim());
              if (nova != null && nova > 0) {
                context.read<PdvProvider>().alterarQuantidade(idx, nova);
              }
              Navigator.pop(ctx);
            },
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // ── F3: Consultar Preço ────────────────────────────────────────────────────

  void _showConsultarPreco() {
    showDialog(
        context: context, builder: (ctx) => const _ConsultarPrecoDialog());
  }

  // ── F5: Gaveta ─────────────────────────────────────────────────────────────

  Future<void> _abrirGaveta() async {
    try {
      await context.read<ApiClient>().post(ApiConfig.gavetaAbrir, body: {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Gaveta aberta'),
              ],
            ),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            width: 200,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Gaveta nao respondeu'),
              ],
            ),
            backgroundColor: AppTheme.error,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            width: 240,
          ),
        );
      }
    }
  }

  // ── F4: Balança ────────────────────────────────────────────────────────────

  void _showBalanca() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: [
            Icon(Icons.scale, color: AppTheme.primary, size: 22),
            SizedBox(width: 8),
            Text('Balanca',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Integracao com balanca serial nao configurada.\nConfigure a porta serial nas Configuracoes do sistema.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Fechar')),
        ],
      ),
    );
  }

  // ── F6: Troca/Devolução ────────────────────────────────────────────────────

  void _showTrocaDevolucao() {
    showDialog(
      context: context,
      builder: (_) => TrocaDevolucaoDialog(),
    );
  }

  // ── F7: Salvar Orçamento ──────────────────────────────────────────────────

  void _salvarOrcamento() async {
    final pdv = context.read<PdvProvider>();
    if (pdv.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: [
            Icon(Icons.save_outlined, color: AppTheme.primary, size: 22),
            SizedBox(width: 8),
            Text('Salvar Orcamento',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Salvar ${pdv.totalItens} iten(s) como orcamento?\n'
          'Total: R\$ ${pdv.total.toStringAsFixed(2)}\n\n'
          'O carrinho sera limpo apos salvar.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final result = await pdv.salvarOrcamento();
    if (!mounted) return;

    if (result != null) {
      final numero = result['numero']?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Orcamento $numero salvo'),
        ]),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 300,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.warning_amber_outlined,
              color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(pdv.error ?? 'Erro ao salvar orcamento'),
        ]),
        backgroundColor: AppTheme.error,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        width: 320,
      ));
    }
  }

  // ── F8: Escolher Orçamento ─────────────────────────────────────────────────

  void _showEscolherOrcamento() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _EscolherOrcamentoDialog(),
    );
    if (result == null || !mounted) return;

    final pdv = context.read<PdvProvider>();
    final itens = (result['itens'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (itens.isEmpty) return;

    // Se o carrinho já tem itens, pedir confirmação
    if (pdv.itens.isNotEmpty) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            side: BorderSide(color: AppTheme.border),
          ),
          title: Text('Substituir carrinho?',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          content: Text(
            'O carrinho atual sera substituido pelos itens do orcamento selecionado.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Confirmar'),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    }

    pdv.importarOrcamento(
      itens: itens,
      clienteId: result['cliente_id'] != null
          ? int.tryParse(result['cliente_id'].toString())
          : null,
      clienteNome: result['cliente_nome']?.toString(),
      desconto: _toDouble(result['desconto_valor']),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Orcamento ${result['numero']} importado'),
        ]),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 300,
      ));
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  // ── F10: Informar Cliente ──────────────────────────────────────────────────

  void _showInformarCliente() {
    showDialog(
        context: context,
        builder: (ctx) => const _InformarClienteDialog());
  }

  // ── F11: Informar Vendedor ─────────────────────────────────────────────────

  void _showInformarVendedor() {
    showDialog(
      context: context,
      builder: (_) => const _InformarVendedorDialog(),
    );
  }

  // ── Del: Deletar último item ───────────────────────────────────────────────

  void _deleteLastItem() {
    final auth = context.read<AuthProvider>();
    final pdv = context.read<PdvProvider>();
    final isAdmin = auth.papelUsuario == 'admin';
    final idx = pdv.itens.length - 1;

    if (isAdmin) {
      pdv.removerItem(idx);
    } else {
      showDialog<bool>(
        context: context,
        builder: (ctx) =>
            _PdvAdminAuthDialog(api: context.read<ApiClient>()),
      ).then((autorizado) {
        if (autorizado == true && mounted) {
          context.read<PdvProvider>().removerItem(idx);
        }
      });
    }
  }

  // ── F9: Finalizar / F12: Cancelar ─────────────────────────────────────────

  void _showPaymentDialog() {
    final caixasProvider = context.read<CaixasProvider>();
    final caixa = caixasProvider.caixaSelecionada;

    if (caixa == null || caixa.isFechado) {
      _mostrarAbrirCaixaObrigatorio();
      return;
    }

    showDialog(
      context: context,
      builder: (_) => PaymentDialog(caixaId: caixa.id),
    );
  }

  void _mostrarAbrirCaixaObrigatorio() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AbrirCaixaPdvDialog(
        onAberto: () {
          Navigator.of(ctx).pop();
        },
        onCancelar: () {
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showDiscountDialog() {
    showDialog(context: context, builder: (_) => DiscountDialog());
  }

  void _confirmCancelSale() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: Text('Cancelar Venda',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Deseja limpar todos os itens do carrinho?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Nao')),
          TextButton(
            onPressed: () {
              context.read<PdvProvider>().limparCarrinho();
              Navigator.pop(ctx);
            },
            child: Text('Sim, cancelar',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: _handleKeyEvent,
        child: Column(
          children: [
            PdvHeader(onMenuPressed: widget.onExit),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: PdvCartTable()),
                      SizedBox(
                        width: 320,
                        child: PdvControlPanel(
                          barcodeFocusNode: _barcodeFocus,
                          onPayment: _showPaymentDialog,
                          onDiscount: _showDiscountDialog,
                          onCancel: _confirmCancelSale,
                          onShortcutsHelp: _showShortcutsHelp,
                          onGaveta: _abrirGaveta,
                          onInformarCliente: _showInformarCliente,
                          onSalvarOrcamento: _salvarOrcamento,
                        ),
                      ),
                    ],
                  ),
                ),
                PdvFooter(),
              ],
            ),
          ),
        );
  }
}

// ─── Consultar Preço Dialog ───────────────────────────────────────────────────

class _ConsultarPrecoDialog extends StatefulWidget {
  const _ConsultarPrecoDialog();

  @override
  State<_ConsultarPrecoDialog> createState() => _ConsultarPrecoDialogState();
}

class _ConsultarPrecoDialogState extends State<_ConsultarPrecoDialog> {
  final _ctrl = TextEditingController();
  List<dynamic> _resultados = [];
  bool _buscando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _buscar(String valor) async {
    if (valor.trim().isEmpty) {
      setState(() => _resultados = []);
      return;
    }
    setState(() => _buscando = true);
    final pdv = context.read<PdvProvider>();
    final produto = await pdv.buscarProdutoPorBarcode(valor.trim());
    if (produto != null) {
      setState(() {
        _resultados = [produto];
        _buscando = false;
      });
      return;
    }
    final lista = await pdv.buscarProdutos(valor.trim());
    if (mounted) {
      setState(() {
        _resultados = lista;
        _buscando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: AppTheme.primary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Consultar Preco',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: AppTheme.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(color: AppTheme.border, height: 24),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style:
                  TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Codigo de barras ou nome do produto',
                prefixIcon:
                    Icon(Icons.qr_code_scanner, color: AppTheme.primary),
              ),
              onSubmitted: _buscar,
              onChanged: (v) {
                if (v.length >= 2) _buscar(v);
              },
            ),
            if (_buscando)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_resultados.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _resultados.length,
                  itemBuilder: (context, index) {
                    final p = _resultados[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: AppTheme.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.descricao,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500)),
                                if (p.codigoBarras != null &&
                                    p.codigoBarras!.isNotEmpty)
                                  Text(p.codigoBarras!,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          Text(fmt.format(p.precoVenda),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.greenSuccess)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 12),
            Text(
              'Somente consulta o preco. Para adicionar ao carrinho, use o campo de codigo de barras.',
              style:
                  TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Escolher Orçamento Dialog ────────────────────────────────────────────────

class _EscolherOrcamentoDialog extends StatefulWidget {
  const _EscolherOrcamentoDialog();

  @override
  State<_EscolherOrcamentoDialog> createState() =>
      _EscolherOrcamentoDialogState();
}

class _EscolherOrcamentoDialogState extends State<_EscolherOrcamentoDialog> {
  List<Map<String, dynamic>> _orcamentos = [];
  bool _carregando = true;
  bool _importando = false;
  String? _erro;

  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final api = context.read<ApiClient>();
      final result = await api.get(ApiConfig.vendas, queryParams: {
        'tipo': 'Orcamento',
        'status': 'orcamento',
        'limit': '50',
        'offset': '0',
      });
      final data = (result['data'] as List?) ?? [];
      if (mounted) {
        setState(() {
          _orcamentos = data.cast<Map<String, dynamic>>();
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Erro ao carregar orcamentos';
          _carregando = false;
        });
      }
    }
  }

  Future<void> _selecionar(Map<String, dynamic> orcamento) async {
    final id = orcamento['id'];
    if (id == null) return;

    setState(() => _importando = true);
    try {
      final api = context.read<ApiClient>();
      final result = await api.get(ApiConfig.vendaById(id is int ? id : int.parse(id.toString())));
      final data = result['data'] as Map<String, dynamic>?;
      if (data != null && mounted) {
        Navigator.pop(context, data);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _importando = false;
          _erro = 'Erro ao carregar itens do orcamento';
        });
      }
    }
  }

  double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.description_outlined,
                    color: AppTheme.primary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Escolher Orcamento',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: AppTheme.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(color: AppTheme.border, height: 24),

            // Content
            if (_carregando)
              SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_erro != null)
              SizedBox(
                height: 120,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.error, size: 32),
                      SizedBox(height: 8),
                      Text(_erro!,
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14)),
                      SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _carregar,
                        child: Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_orcamentos.isEmpty)
              SizedBox(
                height: 120,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined,
                          color: AppTheme.textMuted, size: 40),
                      SizedBox(height: 8),
                      Text('Nenhum orcamento pendente',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
              )
            else ...[
              // Table header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  children: [
                    SizedBox(
                        width: 80,
                        child: Text('Numero',
                            style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600))),
                    SizedBox(
                        width: 120,
                        child: Text('Data',
                            style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600))),
                    SizedBox(
                        width: 60,
                        child: Text('Itens',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600))),
                    Expanded(
                        child: Text('Total',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              SizedBox(height: 4),

              // List
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 320),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _orcamentos.length,
                    itemBuilder: (context, index) {
                      final o = _orcamentos[index];
                      final numero = o['numero']?.toString() ?? '-';
                      final criadoEm = o['criado_em']?.toString() ?? '';
                      String dataStr = '-';
                      try {
                        dataStr = _dateFmt.format(DateTime.parse(criadoEm));
                      } catch (_) {}
                      final totalItens = _parseInt(o['total_itens']);
                      final total = _parseDouble(o['total']);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _importando ? null : () => _selecionar(o),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom:
                                      BorderSide(color: AppTheme.border)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(numero,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600)),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text(dataStr,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary)),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Text('$totalItens',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary)),
                                ),
                                Expanded(
                                  child: Text(_fmt.format(total),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.greenSuccess)),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios,
                                    size: 14, color: AppTheme.textMuted),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Loading overlay for import
            if (_importando)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Carregando itens...',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 12),
            Text(
              'Selecione um orcamento para importar os itens para o carrinho.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Informar Cliente Dialog ──────────────────────────────────────────────────

class _InformarClienteDialog extends StatefulWidget {
  const _InformarClienteDialog();

  @override
  State<_InformarClienteDialog> createState() =>
      _InformarClienteDialogState();
}

class _InformarClienteDialogState extends State<_InformarClienteDialog> {
  final _ctrl = TextEditingController();
  List<Cliente> _resultados = [];
  bool _buscando = false;
  String? _erro;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _buscar(String valor) async {
    if (valor.trim().length < 2) {
      setState(() => _resultados = []);
      return;
    }
    setState(() {
      _buscando = true;
      _erro = null;
    });
    try {
      final api = context.read<ApiClient>();
      final result = await api.get(ApiConfig.clientes,
          queryParams: {'busca': valor.trim(), 'ativo': '1'});
      final data = result['data'] as List;
      if (mounted) {
        setState(() {
          _resultados = data
              .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
              .toList();
          _buscando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _buscando = false;
          _erro = 'Erro ao buscar clientes';
        });
      }
    }
  }

  void _selecionarCliente(Cliente c) {
    context.read<PdvProvider>().setCliente(c.id, c.nome);
    Navigator.pop(context);
  }

  void _limparCliente() {
    context.read<PdvProvider>().limparCliente();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline,
                    color: AppTheme.primary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Informar Cliente',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: AppTheme.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (pdv.clienteNome != null) ...[
              SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.greenSuccess.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                      color:
                          AppTheme.greenSuccess.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: AppTheme.greenSuccess, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Cliente atual: ${pdv.clienteNome}',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.greenSuccess,
                              fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                        onPressed: _limparCliente,
                        child: Text('Remover',
                            style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ],
            Divider(color: AppTheme.border, height: 24),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style:
                  TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nome, CPF ou CNPJ',
                prefixIcon: Icon(Icons.search, color: AppTheme.primary),
              ),
              onSubmitted: _buscar,
              onChanged: (v) {
                if (v.length >= 2) _buscar(v);
              },
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_erro!,
                    style: TextStyle(
                        color: AppTheme.error, fontSize: 13)),
              ),
            if (_buscando)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_resultados.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _resultados.length,
                  itemBuilder: (context, index) {
                    final c = _resultados[index];
                    return InkWell(
                      onTap: () => _selecionarCliente(c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom:
                                  BorderSide(color: AppTheme.border)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person,
                                size: 16,
                                color: AppTheme.textSecondary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(c.nome,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w500)),
                                  if (c.cpfCnpj != null &&
                                      c.cpfCnpj!.isNotEmpty)
                                    Text(c.cpfCnpj!,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 18, color: AppTheme.textMuted),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Informar Vendedor Dialog ─────────────────────────────────────────────────

class _InformarVendedorDialog extends StatefulWidget {
  const _InformarVendedorDialog();

  @override
  State<_InformarVendedorDialog> createState() =>
      _InformarVendedorDialogState();
}

class _InformarVendedorDialogState extends State<_InformarVendedorDialog> {
  List<Usuario> _vendedores = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final api = context.read<ApiClient>();
      final result = await api.get(ApiConfig.usuarios);
      final data = (result['data'] as List?) ?? [];
      if (mounted) {
        setState(() {
          _vendedores = data
              .map((e) => Usuario.fromJson(e as Map<String, dynamic>))
              .where((u) => u.ativo)
              .toList();
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = 'Erro ao carregar vendedores';
        });
      }
    }
  }

  void _selecionar(Usuario u) {
    context.read<PdvProvider>().setVendedor(u.id, u.nome);
    Navigator.pop(context);
  }

  void _limpar() {
    context.read<PdvProvider>().limparVendedor();
    Navigator.pop(context);
  }

  String _formatPapel(String papel) {
    switch (papel) {
      case 'admin':
        return 'Admin';
      case 'gerente':
        return 'Gerente';
      case 'operador':
        return 'Operador';
      case 'vendedor':
        return 'Vendedor';
      default:
        return papel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.person_pin_outlined,
                    color: AppTheme.primary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Informar Vendedor',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: AppTheme.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            // Vendedor atual
            if (pdv.vendedorNome != null) ...[
              SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.greenSuccess.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                      color: AppTheme.greenSuccess.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: AppTheme.greenSuccess, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Vendedor: ${pdv.vendedorNome}',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.greenSuccess,
                              fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                        onPressed: _limpar,
                        child: Text('Remover',
                            style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ],
            Divider(color: AppTheme.border, height: 24),

            // Content
            if (_carregando)
              SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_erro != null)
              SizedBox(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_erro!,
                          style: TextStyle(
                              color: AppTheme.error, fontSize: 13)),
                      SizedBox(height: 8),
                      OutlinedButton(
                          onPressed: _carregar,
                          child: Text('Tentar novamente')),
                    ],
                  ),
                ),
              )
            else if (_vendedores.isEmpty)
              SizedBox(
                height: 100,
                child: Center(
                  child: Text('Nenhum usuario ativo encontrado',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14)),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _vendedores.length,
                  itemBuilder: (context, index) {
                    final u = _vendedores[index];
                    final selecionado = pdv.vendedorId == u.id;
                    return InkWell(
                      onTap: () => _selecionar(u),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: selecionado
                              ? AppTheme.primary.withValues(alpha: 0.08)
                              : null,
                          border: Border(
                              bottom: BorderSide(color: AppTheme.border)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selecionado
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 18,
                              color: selecionado
                                  ? AppTheme.primary
                                  : AppTheme.textMuted,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(u.nome,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                      fontWeight: selecionado
                                          ? FontWeight.w600
                                          : FontWeight.w400)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.scaffoldBackground,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm),
                              ),
                              child: Text(_formatPapel(u.papel),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            SizedBox(height: 12),
            Text(
              'Vincule um vendedor para controle de comissao.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Admin Auth Dialog (Del key) ──────────────────────────────────────────────

class _PdvAdminAuthDialog extends StatefulWidget {
  final ApiClient api;
  const _PdvAdminAuthDialog({required this.api});

  @override
  State<_PdvAdminAuthDialog> createState() => _PdvAdminAuthDialogState();
}

class _PdvAdminAuthDialogState extends State<_PdvAdminAuthDialog> {
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
      await widget.api.post(ApiConfig.validarAdmin,
          body: {'login': login, 'senha': senha});
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = 'Login ou senha de administrador invalidos';
        });
      }
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
            style:
                TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _loginCtrl,
            autofocus: true,
            style:
                TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Login do admin',
              prefixIcon: Icon(Icons.person_outline,
                  color: AppTheme.textSecondary, size: 20),
            ),
            onSubmitted: (_) => _validar(),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _senhaCtrl,
            obscureText: true,
            style:
                TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: Icon(Icons.lock_outline,
                  color: AppTheme.textSecondary, size: 20),
            ),
            onSubmitted: (_) => _validar(),
          ),
          if (_erro != null) ...[
            SizedBox(height: 12),
            Text(_erro!,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.error)),
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

// ─── Shortcut Help Row ────────────────────────────────────────────────────────

class _ShortcutHelpRow extends StatelessWidget {
  final String shortcut;
  final String description;
  final Color? color;

  const _ShortcutHelpRow({
    required this.shortcut,
    required this.description,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 52,
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (color ?? AppTheme.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color:
                      (color ?? AppTheme.primary).withValues(alpha: 0.3)),
            ),
            child: Text(shortcut,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color ?? AppTheme.primary)),
          ),
          SizedBox(width: 16),
          Text(description,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ── Dialog para abrir caixa no PDV ─────────────────────────────────────────

class _AbrirCaixaPdvDialog extends StatefulWidget {
  final VoidCallback onAberto;
  final VoidCallback onCancelar;

  const _AbrirCaixaPdvDialog({
    required this.onAberto,
    required this.onCancelar,
  });

  @override
  State<_AbrirCaixaPdvDialog> createState() => _AbrirCaixaPdvDialogState();
}

class _AbrirCaixaPdvDialogState extends State<_AbrirCaixaPdvDialog> {
  final _valorCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final raw = _valorCtrl.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final valor = double.tryParse(raw);
    if (valor == null || valor < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Informe um valor valido')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final caixasProvider = context.read<CaixasProvider>();
      final caixa = caixasProvider.caixaSelecionada;
      if (caixa == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nenhum caixa disponivel')),
        );
        setState(() => _saving = false);
        return;
      }

      final ok = await caixasProvider.abrirCaixa(
        caixaId: caixa.id,
        valorInicial: valor,
      );

      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Caixa "${caixa.nome}" aberto com sucesso'),
            backgroundColor: AppTheme.greenSuccess,
          ),
        );
        widget.onAberto();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro: ${caixasProvider.error ?? "Falha ao abrir caixa"}',
            ),
          ),
        );
        setState(() => _saving = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final caixasProvider = context.watch<CaixasProvider>();
    final caixaNome = caixasProvider.caixaSelecionada?.nome ?? 'Caixa';

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.greenSuccess.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(Icons.lock_open,
                        color: AppTheme.greenSuccess, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Abertura de Caixa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          caixaNome,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppTheme.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'O caixa esta fechado. Informe o valor do fundo de troco para iniciar as vendas.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _valorCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Valor Inicial (Fundo de Troco)',
                  hintText: '0,00',
                  prefixText: r'R$ ',
                ),
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 18),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                onSubmitted: (_) => _confirmar(),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : widget.onCancelar,
                    child: Text('Voltar'),
                  ),
                  Spacer(),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _confirmar,
                    icon: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : Icon(Icons.lock_open, size: 18),
                    label: Text(_saving ? 'Abrindo...' : 'Abrir Caixa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.greenSuccess,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
