import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/crediario_parcela.dart';
import '../../providers/crediario_provider.dart';

class CrediarioScreen extends StatefulWidget {
  CrediarioScreen({super.key});

  @override
  State<CrediarioScreen> createState() => _CrediarioScreenState();
}

class _CrediarioScreenState extends State<CrediarioScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    final provider = context.read<CrediarioProvider>();
    provider.carregarParcelas();
    provider.carregarTotais();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    final provider = context.read<CrediarioProvider>();
    provider.setBusca(value.isEmpty ? null : value);
    provider.carregarParcelas();
  }

  void _setFiltroVencimento(String? filtro) {
    final provider = context.read<CrediarioProvider>();
    provider.setFiltroVencimento(filtro);
    provider.carregarParcelas();
  }

  void _setStatusFiltro(String? status) {
    final provider = context.read<CrediarioProvider>();
    provider.setStatusFiltro(status);
    provider.carregarParcelas();
  }

  void _limparFiltros() {
    _searchController.clear();
    final provider = context.read<CrediarioProvider>();
    provider.limparFiltros();
    provider.carregarParcelas();
  }

  void _abrirPagamento(CrediarioParcela parcela) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CrediarioProvider>(),
        child: _PagamentoDialog(parcela: parcela),
      ),
    );
    if (result == true && mounted) {
      context.read<CrediarioProvider>().carregarParcelas();
      context.read<CrediarioProvider>().carregarTotais();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrediarioProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                SizedBox(height: 20),
                _buildStatCards(provider),
                SizedBox(height: 16),
                _buildFilterChips(provider),
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
          'Crediario',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(width: 24),
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por cliente ou venda...',
              prefixIcon:
                  Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
              isDense: true,
            ),
            style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            onSubmitted: _onSearch,
            onChanged: (v) {
              if (v.isEmpty) _onSearch(v);
            },
          ),
        ),
        Spacer(),
      ],
    );
  }

  Widget _buildStatCards(CrediarioProvider provider) {
    final totais = provider.totais;
    final pendente = totais?['total_pendente'] as double? ?? 0;
    final pago = totais?['total_pago'] as double? ?? 0;
    final atrasado = totais?['total_atrasado'] as double? ?? 0;
    final qtdPendente = totais?['qtd_pendente'] as int? ?? 0;
    final qtdPago = totais?['qtd_pago'] as int? ?? 0;
    final qtdAtrasado = totais?['qtd_atrasado'] as int? ?? 0;

    return Row(
      children: [
        _StatCard(
          label: 'Pendentes',
          value: _currencyFormat.format(pendente),
          subtitle: '$qtdPendente parcelas',
          icon: Icons.schedule_outlined,
          color: AppTheme.yellowWarning,
        ),
        SizedBox(width: 12),
        _StatCard(
          label: 'Pagas',
          value: _currencyFormat.format(pago),
          subtitle: '$qtdPago parcelas',
          icon: Icons.check_circle_outline,
          color: AppTheme.greenSuccess,
        ),
        SizedBox(width: 12),
        _StatCard(
          label: 'Em Atraso',
          value: _currencyFormat.format(atrasado),
          subtitle: '$qtdAtrasado parcelas',
          icon: Icons.warning_amber_outlined,
          color: AppTheme.error,
        ),
        SizedBox(width: 12),
        _StatCard(
          label: 'Total Geral',
          value: _currencyFormat.format(pendente + pago),
          subtitle: '${qtdPendente + qtdPago} parcelas',
          icon: Icons.account_balance_wallet_outlined,
          color: AppTheme.accent,
        ),
      ],
    );
  }

  Widget _buildFilterChips(CrediarioProvider provider) {
    final status = provider.statusFiltro;
    final vencimento = provider.filtroVencimento;
    final hasFilter = status != null || vencimento != null;

    return Row(
      children: [
        Text(
          'Filtrar:',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        SizedBox(width: 8),
        _FilterChip(
          label: 'Todas',
          selected: !hasFilter,
          onTap: () => _limparFiltros(),
        ),
        SizedBox(width: 6),
        _FilterChip(
          label: 'Pendentes',
          selected: status == 'pendente',
          onTap: () => _setStatusFiltro('pendente'),
        ),
        SizedBox(width: 6),
        _FilterChip(
          label: 'Vencendo Hoje',
          selected: vencimento == 'hoje',
          onTap: () => _setFiltroVencimento('hoje'),
          color: AppTheme.yellowWarning,
        ),
        SizedBox(width: 6),
        _FilterChip(
          label: 'Em Atraso',
          selected: vencimento == 'atrasado',
          onTap: () => _setFiltroVencimento('atrasado'),
          color: AppTheme.error,
        ),
        SizedBox(width: 6),
        _FilterChip(
          label: 'Proximos 7 dias',
          selected: vencimento == 'semana',
          onTap: () => _setFiltroVencimento('semana'),
        ),
        SizedBox(width: 6),
        _FilterChip(
          label: 'Pagas',
          selected: status == 'pago',
          onTap: () => _setStatusFiltro('pago'),
          color: AppTheme.greenSuccess,
        ),
        SizedBox(width: 6),
        _FilterChip(
          label: 'Canceladas',
          selected: status == 'cancelado',
          onTap: () => _setStatusFiltro('cancelado'),
        ),
      ],
    );
  }

  Widget _buildBody(CrediarioProvider provider) {
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
              'Erro ao carregar parcelas',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              provider.error!,
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => provider.carregarParcelas(),
              child: Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (provider.parcelas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card_off_outlined,
                size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text(
              'Nenhuma parcela encontrada',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(AppTheme.scaffoldBackground),
          dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
          border: TableBorder.all(color: AppTheme.border, width: 0.5),
          columns: [
            DataColumn(label: Text('Parcela')),
            DataColumn(label: Text('Cliente')),
            DataColumn(label: Text('Venda')),
            DataColumn(label: Text('Vencimento')),
            DataColumn(label: Text('Valor'), numeric: true),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Pagamento')),
            DataColumn(label: Text('Acoes')),
          ],
          rows: provider.parcelas.map((p) => _buildRow(p)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(CrediarioParcela parcela) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final vencimentoStr = dateFormat.format(parcela.dataVencimento);

    Color vencimentoColor = AppTheme.textPrimary;
    if (parcela.isAtrasado) {
      vencimentoColor = AppTheme.error;
    } else if (parcela.isVenceHoje) {
      vencimentoColor = AppTheme.yellowWarning;
    }

    return DataRow(cells: [
      DataCell(Text(
        parcela.parcelaLabel,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      )),
      DataCell(Text(
        parcela.clienteNome ?? '-',
        style: TextStyle(color: AppTheme.textPrimary),
      )),
      DataCell(Text(
        parcela.vendaNumero ?? '#${parcela.vendaId}',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      )),
      DataCell(Text(
        vencimentoStr,
        style: TextStyle(
          color: vencimentoColor,
          fontWeight:
              parcela.isAtrasado || parcela.isVenceHoje ? FontWeight.w600 : null,
        ),
      )),
      DataCell(Text(
        _currencyFormat.format(parcela.valor),
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      )),
      DataCell(_StatusBadge(parcela: parcela)),
      DataCell(Text(
        parcela.dataPagamento != null
            ? '${dateFormat.format(parcela.dataPagamento!)}\n${parcela.formaPagamento ?? ''}'
            : '-',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      )),
      DataCell(
        parcela.isPendente
            ? IconButton(
                icon: Icon(Icons.attach_money, size: 18),
                color: AppTheme.greenSuccess,
                tooltip: 'Registrar Pagamento',
                onPressed: () => _abrirPagamento(parcela),
              )
            : const SizedBox.shrink(),
      ),
    ]);
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
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

// -- Filter Chip --

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: selected ? c : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? c : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// -- Status Badge --

class _StatusBadge extends StatelessWidget {
  final CrediarioParcela parcela;
  const _StatusBadge({required this.parcela});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    if (parcela.isPago) {
      color = AppTheme.greenSuccess;
      text = 'Pago';
    } else if (parcela.isCancelado) {
      color = AppTheme.textMuted;
      text = 'Cancelado';
    } else if (parcela.isAtrasado) {
      color = AppTheme.error;
      text = 'Atrasado';
    } else if (parcela.isVenceHoje) {
      color = AppTheme.yellowWarning;
      text = 'Vence Hoje';
    } else {
      color = AppTheme.accent;
      text = 'Pendente';
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

// -- Pagamento Dialog --

class _PagamentoDialog extends StatefulWidget {
  final CrediarioParcela parcela;
  const _PagamentoDialog({required this.parcela});

  @override
  State<_PagamentoDialog> createState() => _PagamentoDialogState();
}

class _PagamentoDialogState extends State<_PagamentoDialog> {
  String _formaPagamento = 'dinheiro';
  DateTime _dataPagamento = DateTime.now();
  bool _saving = false;

  final _formas = [
    'dinheiro',
    'pix',
    'cartao_credito',
    'cartao_debito',
    'transferencia',
    'outros',
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
      case 'transferencia':
        return 'Transferencia';
      default:
        return 'Outros';
    }
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataPagamento,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
      setState(() => _dataPagamento = picked);
    }
  }

  Future<void> _confirmarPagamento() async {
    setState(() => _saving = true);

    try {
      await context.read<CrediarioProvider>().pagarParcela(
            widget.parcela.id,
            _formaPagamento,
            _dataPagamento.toIso8601String().substring(0, 10),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Parcela paga com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

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
                'Registrar Pagamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 20),

              // Info da parcela
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parcela ${widget.parcela.parcelaLabel}',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Valor: ${currencyFormat.format(widget.parcela.valor)}',
                          style: TextStyle(
                            color: AppTheme.greenSuccess,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Venc: ${dateFormat.format(widget.parcela.dataVencimento)}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (widget.parcela.clienteNome != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Cliente: ${widget.parcela.clienteNome}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (widget.parcela.vendaNumero != null) ...[
                      SizedBox(height: 2),
                      Text(
                        'Venda: ${widget.parcela.vendaNumero}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
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

              // Data de pagamento
              InkWell(
                onTap: _selecionarData,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Data de Pagamento',
                    suffixIcon: Icon(Icons.calendar_today,
                        size: 18, color: AppTheme.textSecondary),
                  ),
                  child: Text(
                    dateFormat.format(_dataPagamento),
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _confirmarPagamento,
                    icon: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.check, size: 18),
                    label: Text('Confirmar Pagamento'),
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
