import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../app/theme.dart';
import '../../../providers/pdv_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/configuracoes_provider.dart';
import '../../../services/receipt_service.dart';
import '../../../config/api_config.dart';
import '../../../services/api_client.dart';

String _formaLabel(String forma) {
  return switch (forma) {
    'dinheiro' => 'Dinheiro',
    'cartao_credito' => 'Credito',
    'cartao_debito' => 'Debito',
    'pix' => 'Pix',
    'crediario' => 'Crediario',
    _ => forma,
  };
}

class PaymentDialog extends StatefulWidget {
  final int caixaId;
  PaymentDialog({super.key, required this.caixaId});
  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  // Pagamentos confirmados na lista
  final List<Map<String, dynamic>> _pagamentos = [];

  // Forma atualmente selecionada para adicionar
  String? _metodoAtual;

  // Controller do valor do pagamento atual
  final _valorPagamentoController = TextEditingController();

  // Dinheiro: valor recebido e troco
  final _valorRecebidoController = TextEditingController();
  double _troco = 0;

  // Crediario
  int _numeroParcelas = 1;
  final _clienteBuscaController = TextEditingController();
  List<Map<String, dynamic>> _clientesResultado = [];
  Map<String, dynamic>? _clienteSelecionado;
  Map<String, dynamic>? _limiteInfo;
  bool _buscandoClientes = false;
  bool _verificandoLimite = false;

  @override
  void dispose() {
    _valorPagamentoController.dispose();
    _valorRecebidoController.dispose();
    _clienteBuscaController.dispose();
    super.dispose();
  }

  double get _totalPago =>
      _pagamentos.fold(0.0, (sum, p) => sum + ((p['valor'] as num).toDouble()));

  double get _faltante {
    final pdv = context.read<PdvProvider>();
    return (pdv.total - _totalPago).clamp(0, double.infinity);
  }

  bool get _pagamentoCompleto => _faltante < 0.01;

  bool get _temCrediario =>
      _pagamentos.any((p) => p['forma_pagamento'] == 'crediario');

  void _selecionarMetodo(String forma) {
    // Se crediario ja adicionado, nao permite outro
    if (_temCrediario) return;
    // Se ja tem pagamentos e quer crediario, nao permite
    if (forma == 'crediario' && _pagamentos.isNotEmpty) return;

    setState(() {
      _metodoAtual = forma;
      _valorPagamentoController.text = _faltante.toStringAsFixed(2);
    });
  }

  void _adicionarPagamento() {
    if (_metodoAtual == null) return;

    final valor = double.tryParse(
            _valorPagamentoController.text.replaceAll(',', '.')) ??
        0;
    if (valor <= 0) return;

    // Nao permitir valor maior que o faltante (com tolerancia)
    if (valor > _faltante + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Valor excede o total restante'),
            backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() {
      _pagamentos.add({
        'forma_pagamento': _metodoAtual!,
        'valor': valor,
      });
      _metodoAtual = null;
      _valorPagamentoController.clear();
    });
  }

  void _removerPagamento(int index) {
    setState(() {
      _pagamentos.removeAt(index);
      if (_pagamentos.isEmpty) {
        _metodoAtual = null;
      }
    });
  }

  void _calcularTroco() {
    final parteDinheiro = _pagamentos
        .where((p) => p['forma_pagamento'] == 'dinheiro')
        .fold<double>(0.0, (sum, p) => sum + ((p['valor'] as num).toDouble()));
    final recebido = double.tryParse(
            _valorRecebidoController.text.replaceAll(',', '.')) ??
        0;
    setState(() => _troco = recebido - parteDinheiro);
  }

  void _addValorRapido(double valor) {
    final current = double.tryParse(
            _valorRecebidoController.text.replaceAll(',', '.')) ??
        0;
    _valorRecebidoController.text = (current + valor).toStringAsFixed(2);
    _calcularTroco();
  }

  Future<void> _buscarClientes(String busca) async {
    if (busca.length < 2) {
      setState(() => _clientesResultado = []);
      return;
    }
    setState(() => _buscandoClientes = true);
    try {
      final api = context.read<ApiClient>();
      final result =
          await api.get(ApiConfig.clientes, queryParams: {'busca': busca});
      final data = result['data'] as List? ?? [];
      setState(() {
        _clientesResultado = data.cast<Map<String, dynamic>>();
        _buscandoClientes = false;
      });
    } catch (_) {
      setState(() => _buscandoClientes = false);
    }
  }

  Future<void> _selecionarCliente(Map<String, dynamic> cliente) async {
    final clienteId = cliente['id'] is int
        ? cliente['id'] as int
        : int.parse(cliente['id'].toString());

    setState(() {
      _clienteSelecionado = cliente;
      _clienteBuscaController.text = cliente['nome']?.toString() ?? '';
      _clientesResultado = [];
      _verificandoLimite = true;
    });

    final pdv = context.read<PdvProvider>();
    pdv.setCliente(clienteId, cliente['nome']?.toString() ?? '');

    final info = await pdv.verificarLimiteCrediario(clienteId);
    if (mounted) {
      setState(() {
        _limiteInfo = info;
        _verificandoLimite = false;
      });
    }
  }

  void _limparCliente() {
    final pdv = context.read<PdvProvider>();
    pdv.limparCliente();
    setState(() {
      _clienteSelecionado = null;
      _limiteInfo = null;
      _clienteBuscaController.clear();
      _clientesResultado = [];
    });
  }

  bool get _crediarioValido {
    if (_clienteSelecionado == null) return false;
    if (_limiteInfo == null) return false;
    if (_limiteInfo!['bloqueado'] == true) return false;
    final limiteDisponivel =
        (_limiteInfo!['limite_disponivel'] as num?)?.toDouble() ?? 0;
    final pdv = context.read<PdvProvider>();
    final limiteCredito =
        (_limiteInfo!['limite_credito'] as num?)?.toDouble() ?? 0;
    if (limiteCredito > 0 && pdv.total > limiteDisponivel) return false;
    return true;
  }

  Future<void> _confirmar() async {
    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();
    final configProvider = context.read<ConfiguracoesProvider>();
    final operador = auth.nomeUsuario;
    final emitente = pdv.emitente;
    final impressaoCupom =
        configProvider.getConfig('impressao_cupom', 'perguntar');

    if (!_pagamentoCompleto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Pagamento incompleto'),
            backgroundColor: AppTheme.error),
      );
      return;
    }

    // Validar dinheiro: valor recebido
    final temDinheiro =
        _pagamentos.any((p) => p['forma_pagamento'] == 'dinheiro');
    double? valorRecebido;
    if (temDinheiro) {
      final parteDinheiro = _pagamentos
          .where((p) => p['forma_pagamento'] == 'dinheiro')
          .fold<double>(
              0.0, (sum, p) => sum + ((p['valor'] as num).toDouble()));
      valorRecebido = double.tryParse(
          _valorRecebidoController.text.replaceAll(',', '.'));
      // Se campo vazio ou zero, assume valor exato (sem troco)
      if (valorRecebido == null || valorRecebido <= 0) {
        valorRecebido = parteDinheiro;
      }
      if (valorRecebido < parteDinheiro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Valor recebido insuficiente'),
              backgroundColor: AppTheme.error),
        );
        return;
      }
    }

    // Validar crediario
    if (_temCrediario) {
      if (_clienteSelecionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Selecione um cliente para o crediario'),
              backgroundColor: AppTheme.error),
        );
        return;
      }
      if (!_crediarioValido) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Cliente sem limite disponivel ou bloqueado'),
              backgroundColor: AppTheme.error),
        );
        return;
      }
    }

    final result = await pdv.finalizarVenda(
      pagamentos: _pagamentos,
      valorRecebido: valorRecebido,
      caixaId: widget.caixaId,
      crediarioParcelas: _temCrediario ? _numeroParcelas : null,
    );

    if (!mounted) return;

    if (result == null) {
      // Mostrar erro — manter dialog aberto para o usuario tentar novamente
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(pdv.error ?? 'Erro ao finalizar venda'),
            backgroundColor: AppTheme.error),
      );
      return;
    }

    // Abrir gaveta automaticamente se houver pagamento em dinheiro
    if (temDinheiro) {
      try {
        await context.read<ApiClient>().post(ApiConfig.gavetaAbrir, body: {});
      } catch (_) {
        // falha silenciosa — gaveta pode não estar configurada
      }
    }

    if (mounted) {
      Navigator.pop(context);
      if (impressaoCupom == 'automatico') {
        _visualizarCupom(context, result, operador, emitente);
      } else {
        _showSuccess(result, operador, emitente, impressaoCupom);
      }
    }
  }

  void _showSuccess(
    Map<String, dynamic> data,
    String operador,
    Map<String, dynamic>? emitente,
    String impressaoCupom,
  ) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final mostrarBotaoCupom = impressaoCupom != 'desativado';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.greenSuccess,
                child: Icon(Icons.check, color: Colors.white, size: 36)),
            SizedBox(height: 16),
            Text('Venda Finalizada!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            SizedBox(height: 8),
            Text('Total: ${currencyFormat.format(data['total'] ?? 0)}',
                style: TextStyle(
                    fontSize: 16, color: AppTheme.textSecondary)),
            if (_troco > 0)
              Text('Troco: ${currencyFormat.format(_troco)}',
                  style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.greenSuccess,
                      fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK')),
          if (mostrarBotaoCupom)
            ElevatedButton.icon(
              onPressed: () =>
                  _visualizarCupom(ctx, data, operador, emitente),
              icon: Icon(Icons.receipt_long, size: 18),
              label: Text('Ver Cupom'),
            ),
        ],
      ),
    );
  }

  void _visualizarCupom(
    BuildContext parentCtx,
    Map<String, dynamic> data,
    String operador,
    Map<String, dynamic>? emitente,
  ) {
    showDialog(
      context: parentCtx,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        child: SizedBox(
          width: 420,
          height: 600,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long,
                            color: AppTheme.accent, size: 20),
                        SizedBox(width: 8),
                        Text('Cupom da Venda',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                      ],
                    ),
                    IconButton(
                        icon: Icon(Icons.close,
                            color: AppTheme.textSecondary, size: 20),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              Divider(color: AppTheme.border, height: 1),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppTheme.radiusLg),
                    bottomRight: Radius.circular(AppTheme.radiusLg),
                  ),
                  child: PdfPreview(
                    build: (_) => ReceiptService.generateReceipt(
                      vendaData: data,
                      operador: operador,
                      emitente: emitente,
                    ),
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    pdfFileName: 'Cupom_${data['numero'] ?? 'venda'}',
                    allowPrinting: true,
                    allowSharing: false,
                    loadingWidget: Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.accent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Finalizar Venda',
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
                SizedBox(height: 16),

                // Total
                Text(currencyFormat.format(pdv.total),
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.greenSuccess),
                    textAlign: TextAlign.center),
                SizedBox(height: 20),

                // Lista de pagamentos ja adicionados
                if (_pagamentos.isNotEmpty) ...[
                  ..._pagamentos.asMap().entries.map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.greenSuccess.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                            color:
                                AppTheme.greenSuccess.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: AppTheme.greenSuccess, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formaLabel(p['forma_pagamento'] as String),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary),
                            ),
                          ),
                          Text(
                            currencyFormat
                                .format((p['valor'] as num).toDouble()),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.greenSuccess),
                          ),
                          SizedBox(width: 8),
                          InkWell(
                            onTap: () => _removerPagamento(i),
                            child: Icon(Icons.close,
                                color: AppTheme.textMuted, size: 18),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Indicador de faltante
                  if (!_pagamentoCompleto)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Falta: ${currencyFormat.format(_faltante)}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.yellowWarning),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_pagamentoCompleto && !_temDinheiroNaLista)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Pagamento completo',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.greenSuccess),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(height: 4),
                ],

                // Botoes de metodo - so mostra se pagamento incompleto
                if (!_pagamentoCompleto && !_temCrediario) ...[
                  // Row 1: Dinheiro, Credito, Debito
                  Row(
                    children: [
                      _MetodoButton(
                          label: 'Dinheiro',
                          icon: Icons.payments_outlined,
                          selected: _metodoAtual == 'dinheiro',
                          onTap: () => _selecionarMetodo('dinheiro')),
                      SizedBox(width: 8),
                      _MetodoButton(
                          label: 'Credito',
                          icon: Icons.credit_card,
                          selected: _metodoAtual == 'cartao_credito',
                          onTap: () => _selecionarMetodo('cartao_credito')),
                      SizedBox(width: 8),
                      _MetodoButton(
                          label: 'Debito',
                          icon: Icons.credit_card_outlined,
                          selected: _metodoAtual == 'cartao_debito',
                          onTap: () => _selecionarMetodo('cartao_debito')),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Row 2: Pix, Crediario
                  Row(
                    children: [
                      _MetodoButton(
                          label: 'Pix',
                          icon: Icons.qr_code,
                          selected: _metodoAtual == 'pix',
                          onTap: () => _selecionarMetodo('pix')),
                      SizedBox(width: 8),
                      _MetodoButton(
                          label: 'Crediario',
                          icon: Icons.calendar_month,
                          selected: _metodoAtual == 'crediario',
                          enabled: _pagamentos.isEmpty,
                          onTap: () => _selecionarMetodo('crediario')),
                      SizedBox(width: 8),
                      // Spacer to keep layout balanced
                      Expanded(child: SizedBox()),
                    ],
                  ),
                  SizedBox(height: 16),
                ],

                // Se nao tem pagamentos e nenhum metodo selecionado, mostra instrucao
                if (_pagamentos.isEmpty &&
                    _metodoAtual == null &&
                    !_temCrediario)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('Selecione a forma de pagamento',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textMuted),
                        textAlign: TextAlign.center),
                  ),

                // Secao do metodo selecionado (para adicionar valor)
                if (_metodoAtual != null &&
                    _metodoAtual != 'crediario') ...[
                  _buildValorSection(currencyFormat),
                ],

                // Crediario section
                if (_metodoAtual == 'crediario' || _temCrediario) ...[
                  _buildCrediarioSection(pdv, currencyFormat),
                  SizedBox(height: 20),
                ],

                // Secao de valor recebido (dinheiro) - mostra apos pagamento completo
                if (_pagamentoCompleto && _temDinheiroNaLista) ...[
                  _buildValorRecebidoSection(currencyFormat),
                  SizedBox(height: 16),
                ],

                // Confirm button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        pdv.isLoading || !_pagamentoCompleto
                            ? null
                            : _confirmar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.greenSuccess,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd)),
                    ),
                    child: pdv.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            _pagamentoCompleto
                                ? 'Confirmar Pagamento'
                                : 'Pagamento Incompleto',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _temDinheiroNaLista =>
      _pagamentos.any((p) => p['forma_pagamento'] == 'dinheiro');

  Widget _buildValorSection(NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Valor em ${_formaLabel(_metodoAtual!)}',
          style:
              TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _valorPagamentoController,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0,00',
                  prefixText: r'R$ ',
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
                autofocus: true,
              ),
            ),
            SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _adicionarPagamento,
                icon: Icon(Icons.add, size: 20),
                label: Text('Adicionar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd)),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildValorRecebidoSection(NumberFormat currencyFormat) {
    final parteDinheiro = _pagamentos
        .where((p) => p['forma_pagamento'] == 'dinheiro')
        .fold<double>(
            0.0, (sum, p) => sum + ((p['valor'] as num).toDouble()));

    // Pre-fill with dinheiro amount if empty
    if (_valorRecebidoController.text.isEmpty) {
      _valorRecebidoController.text = parteDinheiro.toStringAsFixed(2);
      _calcularTroco();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Valor Recebido (Dinheiro: ${currencyFormat.format(parteDinheiro)})',
          style:
              TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _valorRecebidoController,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0,00',
            prefixText: r'R$ ',
            filled: true,
            fillColor: AppTheme.inputFill,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide:
                    BorderSide(color: AppTheme.primary, width: 2)),
          ),
          onChanged: (_) => _calcularTroco(),
          autofocus: true,
        ),
        SizedBox(height: 12),
        Text(
          'Troco: ${currencyFormat.format(_troco.clamp(0, double.infinity))}',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color:
                  _troco >= 0 ? AppTheme.greenSuccess : AppTheme.error),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [10, 20, 50, 100, 200]
              .map((v) => OutlinedButton(
                    onPressed: () => _addValorRapido(v.toDouble()),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.border),
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: Text('R\$ $v'),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCrediarioSection(
      PdvProvider pdv, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cliente search
        Text('Cliente',
            style:
                TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        SizedBox(height: 8),
        if (_clienteSelecionado != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.primary),
            ),
            child: Row(
              children: [
                Icon(Icons.person,
                    color: AppTheme.accent, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _clienteSelecionado!['nome']?.toString() ?? '',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                ),
                InkWell(
                  onTap: _limparCliente,
                  child: Icon(Icons.close,
                      color: AppTheme.textSecondary, size: 18),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              TextField(
                controller: _clienteBuscaController,
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar cliente por nome...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  suffixIcon: _buscandoClientes
                      ? Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.accent)))
                      : null,
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                onChanged: _buscarClientes,
                autofocus: true,
              ),
              if (_clientesResultado.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _clientesResultado.length,
                    itemBuilder: (ctx, i) {
                      final c = _clientesResultado[i];
                      return InkWell(
                        onTap: () => _selecionarCliente(c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 16,
                                  color: AppTheme.textSecondary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c['nome']?.toString() ?? '',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary),
                                ),
                              ),
                              if (c['cpf_cnpj'] != null)
                                Text(
                                  c['cpf_cnpj'].toString(),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        SizedBox(height: 16),

        // Limite info
        if (_verificandoLimite)
          Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.accent)),
            ),
          ),

        if (_limiteInfo != null && !_verificandoLimite) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _limiteInfo!['bloqueado'] == true
                  ? AppTheme.error.withValues(alpha: 0.1)
                  : AppTheme.greenSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: _limiteInfo!['bloqueado'] == true
                    ? AppTheme.error
                    : AppTheme.greenSuccess,
              ),
            ),
            child: Column(
              children: [
                if (_limiteInfo!['bloqueado'] == true)
                  Row(
                    children: [
                      Icon(Icons.block,
                          color: AppTheme.error, size: 16),
                      SizedBox(width: 6),
                      Text('Cliente bloqueado - parcelas em atraso',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600)),
                    ],
                  )
                else ...[
                  _LimiteRow(
                    label: 'Limite de credito',
                    value: currencyFormat.format(
                        (_limiteInfo!['limite_credito'] as num?)
                                ?.toDouble() ??
                            0),
                  ),
                  SizedBox(height: 4),
                  _LimiteRow(
                    label: 'Saldo devedor',
                    value: currencyFormat.format(
                        (_limiteInfo!['saldo_devedor'] as num?)
                                ?.toDouble() ??
                            0),
                    valueColor: AppTheme.yellowWarning,
                  ),
                  SizedBox(height: 4),
                  _LimiteRow(
                    label: 'Disponivel',
                    value: currencyFormat.format(
                        (_limiteInfo!['limite_disponivel'] as num?)
                                ?.toDouble() ??
                            0),
                    valueColor: AppTheme.greenSuccess,
                    bold: true,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16),
        ],

        // Parcelas
        if (_clienteSelecionado != null) ...[
          Text('Numero de Parcelas',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 3, 4, 5, 6, 8, 10, 12].map((n) {
              final selected = _numeroParcelas == n;
              return InkWell(
                onTap: () => setState(() => _numeroParcelas = n),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusSm),
                child: Container(
                  width: 48,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.border),
                  ),
                  child: Text(
                    '${n}x',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.scaffoldBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_numeroParcelas x',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary),
                ),
                Text(
                  currencyFormat
                      .format(pdv.total / _numeroParcelas),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accent),
                ),
              ],
            ),
          ),

          // Botao para adicionar crediario como pagamento
          if (!_temCrediario && _crediarioValido) ...[
            SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _pagamentos.add({
                      'forma_pagamento': 'crediario',
                      'valor': pdv.total,
                    });
                    _metodoAtual = null;
                  });
                },
                icon: Icon(Icons.add, size: 18),
                label: Text('Confirmar Crediario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd)),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _MetodoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _MetodoButton({
    required this.label,
    required this.icon,
    required this.selected,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.border),
            ),
            child: Column(
              children: [
                Icon(icon,
                    size: 24,
                    color: selected
                        ? AppTheme.accent
                        : AppTheme.textSecondary),
                SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LimiteRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _LimiteRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                color: valueColor ?? AppTheme.textPrimary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}
