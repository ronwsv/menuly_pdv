import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../providers/devolucoes_provider.dart';

class TrocaDevolucaoDialog extends StatefulWidget {
  const TrocaDevolucaoDialog({super.key});

  @override
  State<TrocaDevolucaoDialog> createState() => _TrocaDevolucaoDialogState();
}

class _TrocaDevolucaoDialogState extends State<TrocaDevolucaoDialog> {
  final _vendaCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Estado
  bool _buscaPorValor = false;
  bool _buscando = false;
  bool _processando = false;
  String? _erro;
  Map<String, dynamic>? _venda;
  List<_ItemDevolucao> _itens = [];
  List<Map<String, dynamic>>? _vendasEncontradas;

  // Configuração da devolução
  String _tipo = 'devolucao';
  String _formaRestituicao = 'dinheiro';
  String _motivoSelecionado = 'Defeito';

  static const _motivosComuns = [
    'Defeito',
    'Insatisfacao',
    'Tamanho errado',
    'Produto errado',
    'Arrependimento',
    'Outro',
  ];

  @override
  void dispose() {
    _vendaCtrl.dispose();
    _valorCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  double get _valorTotalDevolucao {
    double total = 0;
    for (final item in _itens) {
      if (item.selecionado) {
        total += item.quantidade * item.precoUnitario;
      }
    }
    return total;
  }

  int get _itensSelecionados =>
      _itens.where((i) => i.selecionado).length;

  Future<void> _buscarVenda() async {
    final numero = _vendaCtrl.text.trim();
    if (numero.isEmpty) return;
    await _carregarVenda(numero);
  }

  Future<void> _buscarPorValor() async {
    final valorStr = _valorCtrl.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(valorStr);
    if (valor == null || valor <= 0) {
      setState(() => _erro = 'Informe um valor valido');
      return;
    }

    setState(() {
      _buscando = true;
      _erro = null;
      _venda = null;
      _itens = [];
      _vendasEncontradas = null;
    });

    final provider = context.read<DevolucoesProvider>();
    final vendas = await provider.buscarVendasPorValor(valor);

    if (!mounted) return;

    if (vendas == null || vendas.isEmpty) {
      setState(() {
        _buscando = false;
        _erro = 'Nenhuma venda encontrada com valor ${_fmt.format(valor)}';
      });
      return;
    }

    if (vendas.length == 1) {
      // Uma única venda encontrada, carregar direto
      final numero = vendas.first['numero']?.toString() ?? '';
      setState(() => _buscando = false);
      await _carregarVenda(numero);
      return;
    }

    setState(() {
      _buscando = false;
      _vendasEncontradas = vendas;
    });
  }

  Future<void> _carregarVenda(String numero) async {
    setState(() {
      _buscando = true;
      _erro = null;
      _venda = null;
      _itens = [];
      _vendasEncontradas = null;
    });

    final provider = context.read<DevolucoesProvider>();
    final result = await provider.buscarVenda(numero);

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _buscando = false;
        _erro = provider.error ?? 'Venda nao encontrada';
      });
      return;
    }

    final itensRaw = result['itens'] as List<dynamic>? ?? [];
    final itens = itensRaw.map((item) {
      final m = item as Map<String, dynamic>;
      final qtdDisponivel = _toDouble(m['quantidade_disponivel']);
      return _ItemDevolucao(
        produtoId: _toInt(m['produto_id']),
        descricao: m['produto_descricao']?.toString() ?? 'Produto',
        precoUnitario: _toDouble(m['preco_unitario']),
        quantidadeOriginal: _toDouble(m['quantidade']),
        quantidadeDevolvida: _toDouble(m['quantidade_devolvida']),
        quantidadeDisponivel: qtdDisponivel,
        quantidade: qtdDisponivel,
        selecionado: false,
        estadoProduto: 'novo',
        retornaEstoque: true,
      );
    }).toList();

    setState(() {
      _buscando = false;
      _venda = result;
      _itens = itens;
    });
  }

  Future<void> _confirmar() async {
    // Validações
    final itensSel = _itens.where((i) => i.selecionado).toList();
    if (itensSel.isEmpty) {
      setState(() => _erro = 'Selecione pelo menos um item para devolver');
      return;
    }

    final motivo = _motivoSelecionado == 'Outro'
        ? _motivoCtrl.text.trim()
        : _motivoSelecionado;
    if (motivo.isEmpty) {
      setState(() => _erro = 'Informe o motivo da devolucao');
      return;
    }

    setState(() {
      _processando = true;
      _erro = null;
    });

    final vendaId = _toInt(_venda!['id']);
    final data = <String, dynamic>{
      'venda_id': vendaId,
      'tipo': _tipo,
      'motivo': motivo,
      'forma_restituicao': _formaRestituicao,
      'itens': itensSel.map((i) => {
        'produto_id': i.produtoId,
        'quantidade': i.quantidade,
        'estado_produto': i.estadoProduto,
        'retorna_estoque': i.retornaEstoque,
      }).toList(),
    };

    final provider = context.read<DevolucoesProvider>();
    final result = await provider.criarDevolucao(data);

    if (!mounted) return;

    if (result != null) {
      final id = result['id'] ?? '';
      final valor = _toDouble(result['valor_total']);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Devolucao #$id processada — ${_fmt.format(valor)}'),
        ]),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        width: 400,
      ));
    } else {
      setState(() {
        _processando = false;
        _erro = provider.error ?? 'Erro ao processar devolucao';
      });
      // Re-buscar a venda para atualizar quantidades disponíveis
      final numero = _venda?['numero']?.toString();
      if (numero != null) _carregarVenda(numero);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: SizedBox(
        width: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            _buildHeader(),
            Divider(color: AppTheme.border, height: 1),

            // ── Content ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Busca da venda
                    _buildBuscaVenda(),

                    // Erro
                    if (_erro != null) ...[
                      SizedBox(height: 12),
                      _buildErro(),
                    ],

                    // Dados da venda + itens
                    if (_venda != null) ...[
                      SizedBox(height: 20),
                      _buildDadosVenda(),
                      SizedBox(height: 16),
                      _buildTabelaItens(),
                      SizedBox(height: 20),
                      _buildConfigDevolucao(),
                      SizedBox(height: 20),
                      _buildResumo(),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer ──
            if (_venda != null) ...[
              Divider(color: AppTheme.border, height: 1),
              _buildFooter(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.swap_horiz, color: AppTheme.yellowWarning, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text('Troca / Devolucao',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.yellowWarning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('F6',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.yellowWarning)),
          ),
          SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBuscaVenda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle: por número / por valor
        Row(
          children: [
            _buildToggleChip(
              label: 'Por numero',
              icon: Icons.receipt_long,
              selected: !_buscaPorValor,
              onTap: () => setState(() {
                _buscaPorValor = false;
                _vendasEncontradas = null;
                _erro = null;
              }),
            ),
            SizedBox(width: 8),
            _buildToggleChip(
              label: 'Por valor',
              icon: Icons.attach_money,
              selected: _buscaPorValor,
              onTap: () => setState(() {
                _buscaPorValor = true;
                _vendasEncontradas = null;
                _erro = null;
              }),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Campo de busca
        Row(
          children: [
            Expanded(
              child: _buscaPorValor
                  ? TextField(
                      controller: _valorCtrl,
                      autofocus: true,
                      style: TextStyle(
                          color: AppTheme.textPrimary, fontSize: 14),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Valor da venda (ex: 129.90)',
                        prefixIcon:
                            Icon(Icons.attach_money, color: AppTheme.primary),
                      ),
                      onSubmitted: (_) => _buscarPorValor(),
                    )
                  : TextField(
                      controller: _vendaCtrl,
                      autofocus: true,
                      style: TextStyle(
                          color: AppTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Numero da venda',
                        prefixIcon: Icon(Icons.receipt_long,
                            color: AppTheme.primary),
                      ),
                      onSubmitted: (_) => _buscarVenda(),
                    ),
            ),
            SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _buscando
                  ? null
                  : (_buscaPorValor ? _buscarPorValor : _buscarVenda),
              icon: _buscando
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.search, size: 18),
              label: Text('Buscar'),
            ),
          ],
        ),
        // Lista de vendas encontradas por valor
        if (_vendasEncontradas != null) ...[
          SizedBox(height: 12),
          _buildVendasEncontradas(),
        ],
      ],
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? AppTheme.primary : AppTheme.textMuted),
            SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color:
                        selected ? AppTheme.primary : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildVendasEncontradas() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      constraints: BoxConstraints(maxHeight: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMd),
                topRight: Radius.circular(AppTheme.radiusMd),
              ),
            ),
            child: Text(
                '${_vendasEncontradas!.length} vendas encontradas — selecione:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary)),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _vendasEncontradas!.length,
              itemBuilder: (context, index) {
                final v = _vendasEncontradas![index];
                final numero = v['numero']?.toString() ?? '';
                final valor = _toDouble(v['valor_total']);
                final data = v['criado_em']?.toString() ?? '';
                final cliente = v['cliente_nome']?.toString() ?? 'Consumidor';
                final qtdItens = v['qtd_itens']?.toString() ?? '?';

                String dataFmt = data;
                try {
                  final dt = DateTime.parse(data);
                  dataFmt = DateFormat('dd/MM/yy HH:mm').format(dt);
                } catch (_) {}

                return InkWell(
                  onTap: () => _carregarVenda(numero),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border:
                          Border(top: BorderSide(color: AppTheme.border)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt,
                            size: 16, color: AppTheme.textMuted),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('#$numero',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary)),
                              Text('$dataFmt  •  $cliente  •  $qtdItens itens',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                        Text(_fmt.format(valor),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.greenSuccess)),
                        SizedBox(width: 8),
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
    );
  }

  Widget _buildErro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(_erro!,
                style: TextStyle(color: AppTheme.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildDadosVenda() {
    final numero = _venda!['numero']?.toString() ?? '';
    final data = _venda!['criado_em']?.toString() ?? '';
    final cliente = _venda!['cliente_nome']?.toString() ?? 'Consumidor';
    final total = _toDouble(_venda!['total']);

    String dataFormatada = data;
    try {
      final dt = DateTime.parse(data);
      dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {}

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt, color: AppTheme.primary, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Venda #$numero',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                SizedBox(height: 4),
                Text('$dataFormatada  •  $cliente',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Text(_fmt.format(total),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary)),
        ],
      ),
    );
  }

  Widget _buildTabelaItens() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Itens da Venda',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusMd),
                    topRight: Radius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 40), // checkbox space
                    Expanded(
                        flex: 3,
                        child: Text('Produto',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary))),
                    SizedBox(
                        width: 80,
                        child: Text('Preco',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary),
                            textAlign: TextAlign.right)),
                    SizedBox(
                        width: 50,
                        child: Text('Orig.',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary),
                            textAlign: TextAlign.center)),
                    SizedBox(
                        width: 50,
                        child: Text('Disp.',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary),
                            textAlign: TextAlign.center)),
                    SizedBox(
                        width: 70,
                        child: Text('Devolver',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary),
                            textAlign: TextAlign.center)),
                  ],
                ),
              ),
              // Items
              ...List.generate(_itens.length, (i) {
                final item = _itens[i];
                final desabilitado = item.quantidadeDisponivel <= 0;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.border)),
                    color: desabilitado
                        ? AppTheme.scaffoldBackground.withValues(alpha: 0.5)
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Checkbox(
                          value: item.selecionado,
                          onChanged: desabilitado
                              ? null
                              : (v) => setState(() =>
                                  _itens[i] = item.copyWith(selecionado: v!)),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.descricao,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: desabilitado
                                        ? AppTheme.textMuted
                                        : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                            if (desabilitado)
                              Text('Ja devolvido',
                                  style: TextStyle(
                                      fontSize: 11, color: AppTheme.error)),
                          ],
                        ),
                      ),
                      SizedBox(
                          width: 80,
                          child: Text(_fmt.format(item.precoUnitario),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary),
                              textAlign: TextAlign.right)),
                      SizedBox(
                          width: 50,
                          child: Text(
                              _fmtQtd(item.quantidadeOriginal),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                              textAlign: TextAlign.center)),
                      SizedBox(
                          width: 50,
                          child: Text(
                              _fmtQtd(item.quantidadeDisponivel),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: desabilitado
                                      ? AppTheme.error
                                      : AppTheme.greenSuccess),
                              textAlign: TextAlign.center)),
                      SizedBox(
                        width: 70,
                        child: item.selecionado
                            ? SizedBox(
                                height: 32,
                                child: TextField(
                                  controller: TextEditingController(
                                      text: _fmtQtd(item.quantidade)),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary),
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 4),
                                    isDense: true,
                                  ),
                                  onChanged: (v) {
                                    final qty = double.tryParse(v) ?? 0;
                                    final clamped = qty.clamp(
                                        0.0, item.quantidadeDisponivel);
                                    _itens[i] =
                                        item.copyWith(quantidade: clamped);
                                    // Don't setState during onChanged to avoid losing focus
                                  },
                                  onSubmitted: (_) => setState(() {}),
                                ),
                              )
                            : Text('-',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted),
                                textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigDevolucao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tipo
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipo',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  SizedBox(height: 8),
                  _buildRadioOption('devolucao', 'Devolucao', _tipo,
                      (v) => setState(() => _tipo = v!)),
                  _buildRadioOption('troca', 'Troca', _tipo,
                      (v) => setState(() => _tipo = v!)),
                ],
              ),
            ),
            SizedBox(width: 24),
            // Forma de restituição
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Restituicao',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  SizedBox(height: 8),
                  _buildRadioOption(
                      'dinheiro',
                      'Dinheiro',
                      _formaRestituicao,
                      (v) => setState(() => _formaRestituicao = v!)),
                  _buildRadioOption(
                      'credito',
                      'Credito na loja',
                      _formaRestituicao,
                      (v) => setState(() => _formaRestituicao = v!)),
                  _buildRadioOption(
                      'troca',
                      'Troca por produtos',
                      _formaRestituicao,
                      (v) => setState(() => _formaRestituicao = v!)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Motivo
        Text('Motivo',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _motivoSelecionado,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          dropdownColor: AppTheme.cardSurface,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          items: _motivosComuns
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _motivoSelecionado = v);
          },
        ),
        if (_motivoSelecionado == 'Outro') ...[
          SizedBox(height: 8),
          TextField(
            controller: _motivoCtrl,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Descreva o motivo',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRadioOption(
      String value, String label, String groupValue, ValueChanged<String?> onChanged) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildResumo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.yellowWarning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border:
            Border.all(color: AppTheme.yellowWarning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.yellowWarning, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
                '$_itensSelecionados ${_itensSelecionados == 1 ? "item selecionado" : "itens selecionados"}',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary)),
          ),
          Text('Total: ${_fmt.format(_valorTotalDevolucao)}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.yellowWarning)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _processando ? null : () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _processando || _itensSelecionados == 0
                ? null
                : _confirmar,
            icon: _processando
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(Icons.check, size: 18),
            label: Text('Confirmar Devolucao'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.greenSuccess,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static String _fmtQtd(double v) {
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  }
}

// ── Item model ──

class _ItemDevolucao {
  final int produtoId;
  final String descricao;
  final double precoUnitario;
  final double quantidadeOriginal;
  final double quantidadeDevolvida;
  final double quantidadeDisponivel;
  final double quantidade;
  final bool selecionado;
  final String estadoProduto;
  final bool retornaEstoque;

  _ItemDevolucao({
    required this.produtoId,
    required this.descricao,
    required this.precoUnitario,
    required this.quantidadeOriginal,
    required this.quantidadeDevolvida,
    required this.quantidadeDisponivel,
    required this.quantidade,
    required this.selecionado,
    required this.estadoProduto,
    required this.retornaEstoque,
  });

  _ItemDevolucao copyWith({
    double? quantidade,
    bool? selecionado,
    String? estadoProduto,
    bool? retornaEstoque,
  }) {
    return _ItemDevolucao(
      produtoId: produtoId,
      descricao: descricao,
      precoUnitario: precoUnitario,
      quantidadeOriginal: quantidadeOriginal,
      quantidadeDevolvida: quantidadeDevolvida,
      quantidadeDisponivel: quantidadeDisponivel,
      quantidade: quantidade ?? this.quantidade,
      selecionado: selecionado ?? this.selecionado,
      estadoProduto: estadoProduto ?? this.estadoProduto,
      retornaEstoque: retornaEstoque ?? this.retornaEstoque,
    );
  }
}
