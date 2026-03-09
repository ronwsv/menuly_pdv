import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../config/api_config.dart';
import '../../models/produto.dart';
import '../../models/servico.dart';
import '../../models/venda.dart';
import '../../providers/auth_provider.dart';
import '../../providers/configuracoes_provider.dart';
import '../../providers/vendas_provider.dart';
import '../../services/api_client.dart';
import '../../services/receipt_service.dart';

String _formatFormaPgto(String forma) {
  if (forma.contains('+')) {
    return forma
        .split('+')
        .map((f) => _formatFormaPgtoSingle(f.trim()))
        .join(' + ');
  }
  return _formatFormaPgtoSingle(forma);
}

String _formatFormaPgtoSingle(String forma) {
  return switch (forma) {
    'dinheiro' => 'Dinheiro',
    'pix' => 'PIX',
    'cartao' => 'Cartao',
    'cartao_credito' => 'Credito',
    'cartao_debito' => 'Debito',
    'crediario' => 'Crediario',
    _ => forma,
  };
}

class VendasScreen extends StatefulWidget {
  VendasScreen({super.key});

  @override
  State<VendasScreen> createState() => _VendasScreenState();
}

class _VendasScreenState extends State<VendasScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  String? _tipoFiltro;
  String? _statusFiltro;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    context.read<VendasProvider>().carregarVendas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _aplicarFiltros() {
    final provider = context.read<VendasProvider>();
    provider.limparFiltros();
    provider.setTipoFiltro(_tipoFiltro);
    provider.setStatusFiltro(_statusFiltro);
    if (_dateRange != null) {
      provider.setDataRange(
        _dateRange!.start.toIso8601String().substring(0, 10),
        '${_dateRange!.end.toIso8601String().substring(0, 10)} 23:59:59',
      );
    }
    provider.setBusca(_searchController.text.isEmpty
        ? null
        : _searchController.text);
    provider.carregarVendas();
  }

  void _limparFiltros() {
    setState(() {
      _tipoFiltro = null;
      _statusFiltro = null;
      _dateRange = null;
      _searchController.clear();
    });
    final provider = context.read<VendasProvider>();
    provider.limparFiltros();
    provider.carregarVendas();
  }

  Future<void> _selecionarPeriodo() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 1)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.cardSurface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _aplicarFiltros();
    }
  }

  void _abrirDetalhe(Venda venda) async {
    final provider = context.read<VendasProvider>();
    final vendaData = await provider.obterVenda(venda.id);
    if (vendaData == null || !mounted) return;

    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _VendaDetalheDialog(vendaData: vendaData),
      ),
    );
  }

  void _cancelarVenda(Venda venda) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Text(
          'Cancelar Venda',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        content: Text(
          'Deseja cancelar a venda #${venda.numero}?\n'
          'Valor: ${_currencyFormat.format(venda.total)}\n\n'
          'O estoque sera devolvido e o movimento de caixa revertido.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Voltar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Cancelar Venda'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok = await context.read<VendasProvider>().cancelarVenda(venda.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? 'Venda cancelada com sucesso'
                : 'Erro ao cancelar venda'),
          ),
        );
      }
    }
  }

  void _converterOrcamento(Venda venda) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<VendasProvider>(),
        child: _ConverterOrcamentoDialog(venda: venda),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Orcamento convertido em venda!')),
      );
    }
  }

  void _novoOrcamento() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<VendasProvider>(),
        child: const _NovoOrcamentoDialog(),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Orcamento criado com sucesso!')),
      );
    }
  }

  void _imprimirRecibo(Venda venda) async {
    final provider = context.read<VendasProvider>();
    final vendaData = await provider.obterVenda(venda.id);
    if (vendaData == null || !mounted) return;

    final operador = context.read<AuthProvider>().nomeUsuario;

    showDialog(
      context: context,
      builder: (_) => Dialog(
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Recibo - Venda #${venda.numero}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: AppTheme.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PdfPreview(
                  build: (_) => ReceiptService.generateReceipt(
                    vendaData: vendaData,
                    operador: operador,
                    paperWidthMm: int.tryParse(context.read<ConfiguracoesProvider>().getConfig('largura_cupom', '80')) ?? 80,
                  ),
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName: 'Recibo_${venda.numero}',
                  allowPrinting: true,
                  allowSharing: false,
                  loadingWidget: Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.accent),
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
    return Consumer<VendasProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                SizedBox(height: 16),
                _buildStatCards(provider),
                SizedBox(height: 16),
                _buildFilters(),
                SizedBox(height: 16),
                Expanded(child: _buildBody(provider)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Text(
          'Orcamentos e Vendas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(width: 24),
        SizedBox(
          width: 220,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por numero...',
              prefixIcon:
                  Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
              isDense: true,
            ),
            style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            onSubmitted: (_) => _aplicarFiltros(),
            onChanged: (v) {
              if (v.isEmpty) _aplicarFiltros();
            },
          ),
        ),
        Spacer(),
        ElevatedButton.icon(
          onPressed: _novoOrcamento,
          icon: Icon(Icons.add, size: 18),
          label: Text('Novo Orcamento', style: TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        SizedBox(width: 8),
        IconButton(
          onPressed: _aplicarFiltros,
          icon: Icon(Icons.refresh, color: AppTheme.textSecondary),
          tooltip: 'Atualizar',
        ),
      ],
    );
  }

  Widget _buildStatCards(VendasProvider provider) {
    final vendas = provider.vendas;
    final finalizadas =
        vendas.where((v) => v.status == 'finalizada').toList();
    final orcamentos =
        vendas.where((v) => v.status == 'orcamento').toList();
    final canceladas =
        vendas.where((v) => v.status == 'cancelada').toList();
    final totalVendas =
        finalizadas.fold<double>(0, (sum, v) => sum + v.total);

    return Row(
      children: [
        _StatCard(
          label: 'Vendas Finalizadas',
          value: finalizadas.length.toString(),
          subtitle: _currencyFormat.format(totalVendas),
          icon: Icons.check_circle_outline,
          color: AppTheme.greenSuccess,
        ),
        SizedBox(width: 12),
        _StatCard(
          label: 'Orcamentos',
          value: orcamentos.length.toString(),
          subtitle: 'Pendentes',
          icon: Icons.description_outlined,
          color: AppTheme.yellowWarning,
        ),
        SizedBox(width: 12),
        _StatCard(
          label: 'Canceladas',
          value: canceladas.length.toString(),
          subtitle: 'Vendas',
          icon: Icons.cancel_outlined,
          color: AppTheme.error,
        ),
        SizedBox(width: 12),
        _StatCard(
          label: 'Total Registros',
          value: provider.total.toString(),
          subtitle: 'Vendas + Orcamentos',
          icon: Icons.receipt_long_outlined,
          color: AppTheme.accent,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final hasDateRange = _dateRange != null;

    return Row(
      children: [
        // Tipo filter
        _buildFilterDropdown<String?>(
          value: _tipoFiltro,
          hint: 'Tipo',
          items: [
            DropdownMenuItem(value: null, child: Text('Todos')),
            DropdownMenuItem(value: 'Venda', child: Text('Venda')),
            DropdownMenuItem(value: 'Orcamento', child: Text('Orcamento')),
          ],
          onChanged: (v) {
            setState(() => _tipoFiltro = v);
            _aplicarFiltros();
          },
        ),
        SizedBox(width: 12),

        // Status filter
        _buildFilterDropdown<String?>(
          value: _statusFiltro,
          hint: 'Status',
          items: [
            DropdownMenuItem(value: null, child: Text('Todos')),
            DropdownMenuItem(
                value: 'finalizada', child: Text('Finalizada')),
            DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
            DropdownMenuItem(value: 'orcamento', child: Text('Orcamento')),
          ],
          onChanged: (v) {
            setState(() => _statusFiltro = v);
            _aplicarFiltros();
          },
        ),
        SizedBox(width: 12),

        // Date range
        OutlinedButton.icon(
          onPressed: _selecionarPeriodo,
          icon: Icon(Icons.date_range, size: 18),
          label: Text(
            hasDateRange
                ? '${dateFormat.format(_dateRange!.start)} - ${dateFormat.format(_dateRange!.end)}'
                : 'Periodo',
            style: TextStyle(fontSize: 13),
          ),
        ),

        if (_tipoFiltro != null ||
            _statusFiltro != null ||
            _dateRange != null) ...[
          SizedBox(width: 8),
          TextButton(
            onPressed: _limparFiltros,
            child: Text(
              'Limpar filtros',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style:
                TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          dropdownColor: AppTheme.cardSurface,
          style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          icon: Icon(Icons.arrow_drop_down,
              color: AppTheme.textSecondary),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBody(VendasProvider provider) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            SizedBox(height: 12),
            Text(
              'Erro ao carregar vendas',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              provider.error!,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 16),
            OutlinedButton(
              onPressed: _aplicarFiltros,
              child: Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (provider.vendas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text(
              'Nenhuma venda encontrada',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(AppTheme.scaffoldBackground),
            dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
            border: TableBorder.all(color: AppTheme.border, width: 0.5),
            columnSpacing: 16,
            columns: [
              DataColumn(label: Text('Numero')),
              DataColumn(label: Text('Tipo')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Forma Pgto')),
              DataColumn(label: Text('Itens'), numeric: true),
              DataColumn(label: Text('Total'), numeric: true),
              DataColumn(label: Text('Data')),
              DataColumn(label: Text('Acoes')),
            ],
            rows: provider.vendas.map((v) => _buildRow(v)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(Venda venda) {
    String formattedDate = '';
    if (venda.criadoEm.isNotEmpty) {
      try {
        formattedDate =
            _dateFormat.format(DateTime.parse(venda.criadoEm));
      } catch (_) {
        formattedDate = venda.criadoEm;
      }
    }

    final formaPgto = _formatFormaPgto(venda.formaPagamento ?? '-');

    return DataRow(
      cells: [
        DataCell(
          InkWell(
            onTap: () => _abrirDetalhe(venda),
            child: Text(
              venda.numero,
              style: TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        DataCell(_TipoBadge(tipo: venda.tipo)),
        DataCell(_StatusBadge(status: venda.status)),
        DataCell(
          Tooltip(
            message: formaPgto,
            child: SizedBox(
              width: 110,
              child: Text(
                formaPgto,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ),
          ),
        ),
        DataCell(Text(
          '${venda.totalItens}',
          style: TextStyle(color: AppTheme.textSecondary),
        )),
        DataCell(Text(
          _currencyFormat.format(venda.total),
          style: TextStyle(
            color: AppTheme.greenSuccess,
            fontWeight: FontWeight.w600,
          ),
        )),
        DataCell(Text(
          formattedDate,
          style:
              TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        )),
        DataCell(_buildActions(venda)),
      ],
    );
  }

  Widget _buildActions(Venda venda) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ver detalhes
        IconButton(
          icon: Icon(Icons.visibility_outlined, size: 18),
          color: AppTheme.accent,
          tooltip: 'Ver Detalhes',
          onPressed: () => _abrirDetalhe(venda),
        ),
        // Imprimir recibo (apenas finalizadas)
        if (venda.status == 'finalizada')
          IconButton(
            icon: Icon(Icons.print_outlined, size: 18),
            color: AppTheme.textSecondary,
            tooltip: 'Imprimir Recibo',
            onPressed: () => _imprimirRecibo(venda),
          ),
        // Converter orcamento
        if (venda.status == 'orcamento')
          IconButton(
            icon: Icon(Icons.swap_horiz, size: 18),
            color: AppTheme.greenSuccess,
            tooltip: 'Converter em Venda',
            onPressed: () => _converterOrcamento(venda),
          ),
        // Cancelar (apenas finalizadas ou orcamentos)
        if (venda.status == 'finalizada' || venda.status == 'orcamento')
          IconButton(
            icon: Icon(Icons.cancel_outlined, size: 18),
            color: AppTheme.error,
            tooltip: 'Cancelar',
            onPressed: () => _cancelarVenda(venda),
          ),
      ],
    );
  }
}

// -- Stat Card --

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Tipo Badge --

class _TipoBadge extends StatelessWidget {
  final String tipo;
  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final isOrcamento = tipo.toLowerCase() == 'orcamento';
    final color = isOrcamento ? AppTheme.yellowWarning : AppTheme.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        isOrcamento ? 'Orcamento' : 'Venda',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// -- Status Badge --

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'finalizada':
        color = AppTheme.greenSuccess;
        text = 'Finalizada';
        break;
      case 'cancelada':
        color = AppTheme.error;
        text = 'Cancelada';
        break;
      case 'orcamento':
        color = AppTheme.yellowWarning;
        text = 'Orcamento';
        break;
      default:
        color = AppTheme.textMuted;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// -- Venda Detalhe Dialog --

class _VendaDetalheDialog extends StatelessWidget {
  final Map<String, dynamic> vendaData;
  const _VendaDetalheDialog({required this.vendaData});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final numero = vendaData['numero']?.toString() ?? '';
    final tipo = vendaData['tipo']?.toString() ?? 'Venda';
    final status = vendaData['status']?.toString() ?? '';
    final formaPagamento =
        vendaData['forma_pagamento']?.toString() ?? '-';
    final subtotal = _parseDouble(vendaData['subtotal']);
    final descontoValor = _parseDouble(vendaData['desconto_valor']);
    final total = _parseDouble(vendaData['total']);
    final valorRecebido = _parseDouble(vendaData['valor_recebido']);
    final troco = _parseDouble(vendaData['troco']);
    final observacoes = vendaData['observacoes']?.toString();
    final itens = (vendaData['itens'] as List?) ?? [];
    final pagamentos = (vendaData['pagamentos'] as List?) ?? [];

    String criadoEm = '';
    if (vendaData['criado_em'] != null) {
      try {
        criadoEm = dateFormat
            .format(DateTime.parse(vendaData['criado_em'].toString()));
      } catch (_) {
        criadoEm = vendaData['criado_em'].toString();
      }
    }

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      '$tipo #$numero',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(width: 12),
                    _StatusBadge(status: status),
                    Spacer(),
                    Text(
                      criadoEm,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Info cards
                Row(
                  children: [
                    _InfoCard(
                      label: 'Forma Pagamento',
                      value: _formatFormaPgto(formaPagamento),
                    ),
                    SizedBox(width: 12),
                    _InfoCard(
                      label: 'Valor Recebido',
                      value: currencyFormat.format(valorRecebido),
                    ),
                    SizedBox(width: 12),
                    _InfoCard(label: 'Troco', value: currencyFormat.format(troco)),
                  ],
                ),
                SizedBox(height: 16),

                // Detalhamento de pagamentos (se multiplos)
                if (pagamentos.length > 1) ...[
                  Text(
                    'Pagamentos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...pagamentos.map((p) {
                    final forma = p['forma_pagamento']?.toString() ?? '-';
                    final valor = _parseDouble(p['valor']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.payment, size: 16, color: AppTheme.textSecondary),
                          SizedBox(width: 8),
                          Text(
                            _formatFormaPgtoSingle(forma),
                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          Spacer(),
                          Text(
                            currencyFormat.format(valor),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 16),
                ],

                // Itens table
                Text(
                  'Itens da Venda',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        AppTheme.scaffoldBackground),
                    dataRowColor:
                        WidgetStateProperty.all(AppTheme.cardSurface),
                    border:
                        TableBorder.all(color: AppTheme.border, width: 0.5),
                    columnSpacing: 20,
                    columns: [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Produto')),
                      DataColumn(label: Text('Qtd'), numeric: true),
                      DataColumn(label: Text('Preco Unit.'), numeric: true),
                      DataColumn(label: Text('Desconto'), numeric: true),
                      DataColumn(label: Text('Total'), numeric: true),
                    ],
                    rows: List.generate(itens.length, (i) {
                      final item = itens[i] as Map<String, dynamic>;
                      return DataRow(cells: [
                        DataCell(Text(
                          '${i + 1}',
                          style: TextStyle(
                              color: AppTheme.textSecondary),
                        )),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                item['produto_descricao']?.toString() ?? '-',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item['is_atacado'] == true)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text('ATACADO',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.accent)),
                              ),
                          ],
                        )),
                        DataCell(Text(
                          _parseDouble(item['quantidade'])
                              .toStringAsFixed(0),
                          style: TextStyle(
                              color: AppTheme.textPrimary),
                        )),
                        DataCell(Text(
                          currencyFormat
                              .format(_parseDouble(item['preco_unitario'])),
                          style: TextStyle(
                              color: item['is_atacado'] == true
                                  ? AppTheme.accent
                                  : AppTheme.textPrimary,
                              fontWeight: item['is_atacado'] == true
                                  ? FontWeight.w600
                                  : null),
                        )),
                        DataCell(Text(
                          currencyFormat
                              .format(_parseDouble(item['desconto'])),
                          style: TextStyle(
                              color: AppTheme.textSecondary),
                        )),
                        DataCell(Text(
                          currencyFormat
                              .format(_parseDouble(item['total'])),
                          style: TextStyle(
                            color: AppTheme.greenSuccess,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                      ]);
                    }),
                  ),
                ),
                SizedBox(height: 16),

                // Totals
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBackground,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      _TotalRow(
                        label: 'Subtotal',
                        value: currencyFormat.format(subtotal),
                      ),
                      if (descontoValor > 0)
                        _TotalRow(
                          label: 'Desconto',
                          value: '- ${currencyFormat.format(descontoValor)}',
                          valueColor: AppTheme.error,
                        ),
                      Divider(color: AppTheme.border, height: 16),
                      _TotalRow(
                        label: 'TOTAL',
                        value: currencyFormat.format(total),
                        isBold: true,
                        valueColor: AppTheme.greenSuccess,
                      ),
                    ],
                  ),
                ),

                if (observacoes != null && observacoes.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text(
                    'Obs: $observacoes',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Fechar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// -- Info Card --

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.scaffoldBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Total Row --

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: isBold ? 16 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// -- Converter Orcamento Dialog --

class _ConverterOrcamentoDialog extends StatefulWidget {
  final Venda venda;
  const _ConverterOrcamentoDialog({required this.venda});

  @override
  State<_ConverterOrcamentoDialog> createState() =>
      _ConverterOrcamentoDialogState();
}

class _ConverterOrcamentoDialogState
    extends State<_ConverterOrcamentoDialog> {
  String _formaPagamento = 'dinheiro';
  final _valorRecebidoCtrl = TextEditingController();
  bool _converting = false;

  final _formas = [
    'dinheiro',
    'pix',
    'cartao_credito',
    'cartao_debito',
    'crediario',
  ];

  String _formaLabel(String forma) {
    switch (forma) {
      case 'dinheiro':
        return 'Dinheiro';
      case 'pix':
        return 'PIX';
      case 'cartao_credito':
        return 'Cartao Credito';
      case 'cartao_debito':
        return 'Cartao Debito';
      case 'crediario':
        return 'Crediario';
      default:
        return forma;
    }
  }

  @override
  void initState() {
    super.initState();
    _valorRecebidoCtrl.text = widget.venda.total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _valorRecebidoCtrl.dispose();
    super.dispose();
  }

  Future<void> _converter() async {
    setState(() => _converting = true);

    final provider = context.read<VendasProvider>();
    final valorRecebido =
        double.tryParse(_valorRecebidoCtrl.text) ?? widget.venda.total;

    final result = await provider.converterOrcamento(
      widget.venda.id,
      formaPagamento: _formaPagamento,
      valorRecebido: valorRecebido,
    );

    if (mounted) {
      if (result != null) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erro ao converter: ${provider.error ?? "desconhecido"}')),
        );
        setState(() => _converting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Converter Orcamento em Venda',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 16),

              // Info do orcamento
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBackground,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orcamento #${widget.venda.numero}',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Total: ${currencyFormat.format(widget.venda.total)}',
                      style: TextStyle(
                        color: AppTheme.greenSuccess,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Forma de pagamento
              DropdownButtonFormField<String>(
                value: _formaPagamento,
                decoration: InputDecoration(
                    labelText: 'Forma de Pagamento'),
                dropdownColor: AppTheme.cardSurface,
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14),
                items: _formas
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(_formaLabel(f)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _formaPagamento = v);
                },
              ),
              SizedBox(height: 12),

              // Valor recebido (para dinheiro)
              if (_formaPagamento == 'dinheiro')
                TextFormField(
                  controller: _valorRecebidoCtrl,
                  decoration: InputDecoration(
                      labelText: 'Valor Recebido'),
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                ),
              SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _converting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _converting ? null : _converter,
                    icon: _converting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : Icon(Icons.swap_horiz, size: 18),
                    label: Text('Converter em Venda'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.greenSuccess,
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

// ── Dialog: Novo Orcamento ──────────────────────────────────────────────────

class _OrcamentoItem {
  final Produto? produto;
  final Servico? servico;
  int quantidade;

  _OrcamentoItem({this.produto, this.servico, required this.quantidade});

  bool get isProduto => produto != null;
  int get id => produto?.id ?? servico!.id;
  String get descricao => produto?.descricao ?? servico!.descricao;
  double get preco => produto?.precoVenda ?? servico!.preco;
  double get subtotal => preco * quantidade;
  String get tipo => isProduto ? 'produto' : 'servico';
}

class _NovoOrcamentoDialog extends StatefulWidget {
  const _NovoOrcamentoDialog();

  @override
  State<_NovoOrcamentoDialog> createState() => _NovoOrcamentoDialogState();
}

class _NovoOrcamentoDialogState extends State<_NovoOrcamentoDialog> {
  final _buscaCtrl = TextEditingController();
  final _buscaFocus = FocusNode();
  final List<_OrcamentoItem> _itens = [];
  List<Produto> _resultadosProdutos = [];
  List<Servico> _resultadosServicos = [];
  bool _buscando = false;
  bool _salvando = false;

  double get _total =>
      _itens.fold<double>(0, (sum, i) => sum + i.subtotal);

  bool get _temResultados =>
      _resultadosProdutos.isNotEmpty || _resultadosServicos.isNotEmpty;

  @override
  void dispose() {
    _buscaCtrl.dispose();
    _buscaFocus.dispose();
    super.dispose();
  }

  Future<void> _buscar(String busca) async {
    if (busca.trim().isEmpty) {
      setState(() {
        _resultadosProdutos = [];
        _resultadosServicos = [];
      });
      return;
    }
    setState(() => _buscando = true);
    try {
      final api = context.read<ApiClient>();
      final results = await Future.wait([
        api.get(ApiConfig.produtos,
            queryParams: {'busca': busca.trim(), 'ativo': '1'}),
        api.get(ApiConfig.servicos,
            queryParams: {'busca': busca.trim(), 'ativo': '1'}),
      ]);
      final prodData = results[0]['data'] as List;
      final servData = results[1]['data'] as List;
      setState(() {
        _resultadosProdutos = prodData
            .map((e) => Produto.fromJson(e as Map<String, dynamic>))
            .toList();
        _resultadosServicos = servData
            .map((e) => Servico.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      setState(() {
        _resultadosProdutos = [];
        _resultadosServicos = [];
      });
    }
    setState(() => _buscando = false);
  }

  void _adicionarProduto(Produto produto) {
    final idx = _itens.indexWhere(
        (i) => i.isProduto && i.id == produto.id);
    if (idx >= 0) {
      _itens[idx].quantidade++;
    } else {
      _itens.add(_OrcamentoItem(produto: produto, quantidade: 1));
    }
    _limparBusca();
  }

  void _adicionarServico(Servico servico) {
    final idx = _itens.indexWhere(
        (i) => !i.isProduto && i.id == servico.id);
    if (idx >= 0) {
      _itens[idx].quantidade++;
    } else {
      _itens.add(_OrcamentoItem(servico: servico, quantidade: 1));
    }
    _limparBusca();
  }

  void _limparBusca() {
    _buscaCtrl.clear();
    _resultadosProdutos = [];
    _resultadosServicos = [];
    _buscaFocus.requestFocus();
    setState(() {});
  }

  void _removerItem(int index) {
    _itens.removeAt(index);
    setState(() {});
  }

  void _alterarQuantidade(int index, int novaQtd) {
    if (novaQtd <= 0) {
      _removerItem(index);
    } else {
      _itens[index].quantidade = novaQtd;
      setState(() {});
    }
  }

  Future<void> _salvar() async {
    if (_itens.isEmpty) return;
    setState(() => _salvando = true);

    final provider = context.read<VendasProvider>();
    final itens = _itens
        .map((i) => <String, dynamic>{
              if (i.isProduto) 'produto_id': i.id,
              if (!i.isProduto) 'servico_id': i.id,
              'quantidade': i.quantidade,
              'preco_unitario': i.preco,
            })
        .toList();

    final result = await provider.criarOrcamento(itens: itens);
    if (!mounted) return;

    setState(() => _salvando = false);

    if (result != null) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erro ao criar orcamento'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: SizedBox(
        width: 600,
        height: 560,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.description_outlined,
                      color: AppTheme.accent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Novo Orcamento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: AppTheme.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Search field
              TextField(
                controller: _buscaCtrl,
                focusNode: _buscaFocus,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar produto ou servico...',
                  prefixIcon: Icon(Icons.search,
                      size: 20, color: AppTheme.textSecondary),
                  suffixIcon: _buscando
                      ? Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.accent),
                          ),
                        )
                      : null,
                  isDense: true,
                ),
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textPrimary),
                onChanged: (v) => _buscar(v),
              ),

              // Search results dropdown
              if (_temResultados)
                Container(
                  constraints: BoxConstraints(maxHeight: 180),
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBackground,
                    border: Border.all(color: AppTheme.border),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ..._resultadosProdutos.map((p) => ListTile(
                            dense: true,
                            leading: Icon(Icons.inventory_2_outlined,
                                size: 18, color: AppTheme.primary),
                            title: Text(
                              p.descricao,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary),
                            ),
                            subtitle: Text(
                              '${p.codigoBarras ?? p.codigoInterno ?? ''} - ${currFmt.format(p.precoVenda)}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary),
                            ),
                            trailing: Icon(Icons.add_circle_outline,
                                color: AppTheme.accent, size: 20),
                            onTap: () => _adicionarProduto(p),
                          )),
                      ..._resultadosServicos.map((s) => ListTile(
                            dense: true,
                            leading: Icon(Icons.build_outlined,
                                size: 18, color: AppTheme.accent),
                            title: Text(
                              s.descricao,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary),
                            ),
                            subtitle: Text(
                              'Servico - ${currFmt.format(s.preco)}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary),
                            ),
                            trailing: Icon(Icons.add_circle_outline,
                                color: AppTheme.accent, size: 20),
                            onTap: () => _adicionarServico(s),
                          )),
                    ],
                  ),
                ),

              SizedBox(height: 12),

              // Items header
              Row(
                children: [
                  Text(
                    'Itens do Orcamento',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${_itens.length} ${_itens.length == 1 ? 'item' : 'itens'}',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Items list
              Expanded(
                child: _itens.isEmpty
                    ? Center(
                        child: Text(
                          'Busque e adicione produtos ou servicos acima',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _itens.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: AppTheme.border),
                        itemBuilder: (_, i) {
                          final item = _itens[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            item.isProduto
                                                ? Icons.inventory_2_outlined
                                                : Icons.build_outlined,
                                            size: 14,
                                            color: item.isProduto
                                                ? AppTheme.primary
                                                : AppTheme.accent,
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item.descricao,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textPrimary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${currFmt.format(item.preco)} x ${item.quantidade}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline,
                                      size: 18, color: AppTheme.textSecondary),
                                  onPressed: () =>
                                      _alterarQuantidade(i, item.quantidade - 1),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                ),
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${item.quantidade}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline,
                                      size: 18, color: AppTheme.accent),
                                  onPressed: () =>
                                      _alterarQuantidade(i, item.quantidade + 1),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                ),
                                SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    currFmt.format(item.subtotal),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      size: 18, color: Colors.redAccent),
                                  onPressed: () => _removerItem(i),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Footer: total + actions
              Divider(color: AppTheme.border),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    currFmt.format(_total),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent,
                    ),
                  ),
                  Spacer(),
                  OutlinedButton(
                    onPressed: _salvando
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed:
                        _itens.isEmpty || _salvando ? null : _salvar,
                    icon: _salvando
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(Icons.save, size: 18),
                    label: Text(_salvando
                        ? 'Salvando...'
                        : 'Salvar Orcamento'),
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
