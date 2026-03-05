import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/conta_receber.dart';
import '../../providers/contas_receber_provider.dart';

class ContasReceberScreen extends StatefulWidget {
  ContasReceberScreen({super.key});

  @override
  State<ContasReceberScreen> createState() => _ContasReceberScreenState();
}

class _ContasReceberScreenState extends State<ContasReceberScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    final provider = context.read<ContasReceberProvider>();
    provider.carregarContas();
    provider.carregarTotais();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    final provider = context.read<ContasReceberProvider>();
    provider.setBusca(value.isEmpty ? null : value);
    provider.carregarContas();
  }

  void _setFiltroVencimento(String? filtro) {
    final provider = context.read<ContasReceberProvider>();
    provider.setFiltroVencimento(filtro);
    provider.carregarContas();
  }

  void _setStatusFiltro(String? status) {
    final provider = context.read<ContasReceberProvider>();
    provider.setStatusFiltro(status);
    provider.carregarContas();
  }

  void _limparFiltros() {
    _searchController.clear();
    final provider = context.read<ContasReceberProvider>();
    provider.limparFiltros();
    provider.carregarContas();
  }

  void _abrirFormulario([ContaReceber? conta]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ContasReceberProvider>(),
        child: _ContaFormDialog(conta: conta),
      ),
    );
    if (result == true && mounted) {
      context.read<ContasReceberProvider>().carregarContas();
      context.read<ContasReceberProvider>().carregarTotais();
    }
  }

  void _abrirBaixa(ContaReceber conta) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ContasReceberProvider>(),
        child: _BaixaDialog(conta: conta),
      ),
    );
    if (result == true && mounted) {
      context.read<ContasReceberProvider>().carregarContas();
      context.read<ContasReceberProvider>().carregarTotais();
    }
  }

  void _confirmarCancelamento(ContaReceber conta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Text(
          'Cancelar Conta',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        content: Text(
          'Deseja cancelar a conta "${conta.descricao}"?\nValor: ${_currencyFormat.format(conta.valor)}',
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
            child: Text('Cancelar Conta'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context.read<ContasReceberProvider>().cancelarConta(conta.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Conta cancelada com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cancelar: $e')),
          );
        }
      }
    }
  }

  void _confirmarExclusao(ContaReceber conta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Text(
          'Excluir Conta',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        content: Text(
          'Deseja excluir permanentemente a conta "${conta.descricao}"?',
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
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context.read<ContasReceberProvider>().excluirConta(conta.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Conta excluida com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContasReceberProvider>(
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
          'Contas a Receber',
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
              hintText: 'Buscar por descricao ou cliente...',
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
        ElevatedButton.icon(
          onPressed: () => _abrirFormulario(),
          icon: Icon(Icons.add, size: 18),
          label: Text('Nova Conta'),
        ),
      ],
    );
  }

  Widget _buildStatCards(ContasReceberProvider provider) {
    final totais = provider.totais;
    final pendente = totais?['total_pendente'] as double? ?? 0;
    final recebido = totais?['total_recebido'] as double? ?? 0;
    final atrasado = totais?['total_atrasado'] as double? ?? 0;
    final qtdPendente = totais?['qtd_pendente'] as int? ?? 0;
    final qtdAtrasado = totais?['qtd_atrasado'] as int? ?? 0;
    final qtdVenceHoje = totais?['qtd_vencendo_hoje'] as int? ?? 0;

    return Row(
      children: [
        _StatCard(
          label: 'Pendentes',
          value: _currencyFormat.format(pendente),
          subtitle: '$qtdPendente contas',
          icon: Icons.schedule_outlined,
          color: AppTheme.yellowWarning,
        ),
        SizedBox(width: 12),
        _StatCard(
          label: 'Recebidas',
          value: _currencyFormat.format(recebido),
          subtitle: 'Total recebido',
          icon: Icons.check_circle_outline,
          color: AppTheme.greenSuccess,
        ),
        SizedBox(width: 12),
        _StatCard(
          label: 'Em Atraso',
          value: _currencyFormat.format(atrasado),
          subtitle: '$qtdAtrasado contas',
          icon: Icons.warning_amber_outlined,
          color: AppTheme.error,
        ),
        SizedBox(width: 12),
        _StatCard(
          label: 'Vencendo Hoje',
          value: qtdVenceHoje.toString(),
          subtitle: 'contas',
          icon: Icons.today_outlined,
          color: AppTheme.accent,
        ),
      ],
    );
  }

  Widget _buildFilterChips(ContasReceberProvider provider) {
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
          label: 'Recebidas',
          selected: status == 'recebido',
          onTap: () => _setStatusFiltro('recebido'),
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

  Widget _buildBody(ContasReceberProvider provider) {
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
              'Erro ao carregar contas',
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
              onPressed: () => provider.carregarContas(),
              child: Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (provider.contas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text(
              'Nenhuma conta encontrada',
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
            DataColumn(label: Text('Descricao')),
            DataColumn(label: Text('Cliente')),
            DataColumn(label: Text('Vencimento')),
            DataColumn(label: Text('Valor'), numeric: true),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Recebimento')),
            DataColumn(label: Text('Acoes')),
          ],
          rows: provider.contas.map((c) => _buildRow(c)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(ContaReceber conta) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final vencimentoStr = dateFormat.format(conta.dataVencimento);

    Color vencimentoColor = AppTheme.textPrimary;
    if (conta.isAtrasado) {
      vencimentoColor = AppTheme.error;
    } else if (conta.isVenceHoje) {
      vencimentoColor = AppTheme.yellowWarning;
    }

    return DataRow(cells: [
      DataCell(
        SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                conta.descricao,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (conta.tipo != null && conta.tipo!.isNotEmpty)
                Text(
                  conta.tipo!,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
      DataCell(Text(
        conta.clienteNome ?? '-',
        style: TextStyle(color: AppTheme.textPrimary),
      )),
      DataCell(Text(
        vencimentoStr,
        style: TextStyle(
          color: vencimentoColor,
          fontWeight:
              conta.isAtrasado || conta.isVenceHoje ? FontWeight.w600 : null,
        ),
      )),
      DataCell(Text(
        _currencyFormat.format(conta.valor),
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      )),
      DataCell(_StatusBadge(conta: conta)),
      DataCell(Text(
        conta.dataRecebimento != null
            ? '${dateFormat.format(conta.dataRecebimento!)}\n${conta.formaRecebimento ?? ''}'
            : '-',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      )),
      DataCell(_buildActions(conta)),
    ]);
  }

  Widget _buildActions(ContaReceber conta) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (conta.isPendente) ...[
          IconButton(
            icon: Icon(Icons.attach_money, size: 18),
            color: AppTheme.greenSuccess,
            tooltip: 'Dar Baixa',
            onPressed: () => _abrirBaixa(conta),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18),
            color: AppTheme.accent,
            tooltip: 'Editar',
            onPressed: () => _abrirFormulario(conta),
          ),
          IconButton(
            icon: Icon(Icons.cancel_outlined, size: 18),
            color: AppTheme.yellowWarning,
            tooltip: 'Cancelar',
            onPressed: () => _confirmarCancelamento(conta),
          ),
        ],
        IconButton(
          icon: Icon(Icons.delete_outline, size: 18),
          color: AppTheme.error,
          tooltip: 'Excluir',
          onPressed: () => _confirmarExclusao(conta),
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
  final ContaReceber conta;
  const _StatusBadge({required this.conta});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    if (conta.isRecebido) {
      color = AppTheme.greenSuccess;
      text = 'Recebido';
    } else if (conta.isCancelado) {
      color = AppTheme.textMuted;
      text = 'Cancelado';
    } else if (conta.isAtrasado) {
      color = AppTheme.error;
      text = 'Atrasado';
    } else if (conta.isVenceHoje) {
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

// -- Form Dialog --

class _ContaFormDialog extends StatefulWidget {
  final ContaReceber? conta;
  const _ContaFormDialog({this.conta});

  @override
  State<_ContaFormDialog> createState() => _ContaFormDialogState();
}

class _ContaFormDialogState extends State<_ContaFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _valorCtrl;
  late final TextEditingController _tipoCtrl;
  late final TextEditingController _informacoesCtrl;
  late final TextEditingController _clienteIdCtrl;
  late final TextEditingController _vendaIdCtrl;

  DateTime _dataVencimento = DateTime.now().add(Duration(days: 30));
  bool _saving = false;

  bool get _isEditing => widget.conta != null;

  @override
  void initState() {
    super.initState();
    final c = widget.conta;
    _descricaoCtrl = TextEditingController(text: c?.descricao ?? '');
    _valorCtrl = TextEditingController(
        text: c != null ? c.valor.toStringAsFixed(2) : '');
    _tipoCtrl = TextEditingController(text: c?.tipo ?? '');
    _informacoesCtrl = TextEditingController(text: c?.informacoes ?? '');
    _clienteIdCtrl = TextEditingController(
        text: c?.clienteId != null ? c!.clienteId.toString() : '');
    _vendaIdCtrl = TextEditingController(
        text: c?.vendaId != null ? c!.vendaId.toString() : '');
    if (c != null) {
      _dataVencimento = c.dataVencimento;
    }
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    _tipoCtrl.dispose();
    _informacoesCtrl.dispose();
    _clienteIdCtrl.dispose();
    _vendaIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataVencimento,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
      setState(() => _dataVencimento = picked);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'descricao': _descricaoCtrl.text.trim(),
      'data_vencimento':
          _dataVencimento.toIso8601String().substring(0, 10),
      'valor': double.tryParse(_valorCtrl.text.trim()) ?? 0,
    };

    if (_tipoCtrl.text.trim().isNotEmpty) {
      data['tipo'] = _tipoCtrl.text.trim();
    }
    if (_informacoesCtrl.text.trim().isNotEmpty) {
      data['informacoes'] = _informacoesCtrl.text.trim();
    }
    if (_clienteIdCtrl.text.trim().isNotEmpty) {
      data['cliente_id'] = int.tryParse(_clienteIdCtrl.text.trim());
    }
    if (_vendaIdCtrl.text.trim().isNotEmpty) {
      data['venda_id'] = int.tryParse(_vendaIdCtrl.text.trim());
    }

    try {
      final provider = context.read<ContasReceberProvider>();
      if (_isEditing) {
        await provider.atualizarConta(widget.conta!.id, data);
      } else {
        await provider.criarConta(data);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing ? 'Editar Conta' : 'Nova Conta a Receber',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Descricao
                  TextFormField(
                    controller: _descricaoCtrl,
                    decoration:
                        InputDecoration(labelText: 'Descricao *'),
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatorio'
                        : null,
                  ),
                  SizedBox(height: 12),

                  // Valor + Data
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _valorCtrl,
                          decoration:
                              InputDecoration(labelText: 'Valor *'),
                          style: TextStyle(
                              color: AppTheme.textPrimary, fontSize: 14),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]')),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Campo obrigatorio';
                            }
                            final val = double.tryParse(v.trim());
                            if (val == null || val <= 0) {
                              return 'Valor invalido';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _selecionarData,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Vencimento *',
                              suffixIcon: Icon(Icons.calendar_today,
                                  size: 18, color: AppTheme.textSecondary),
                            ),
                            child: Text(
                              dateFormat.format(_dataVencimento),
                              style: TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Tipo
                  TextFormField(
                    controller: _tipoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      hintText: 'Ex: boleto, duplicata, crediario',
                    ),
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                  ),
                  SizedBox(height: 12),

                  // Cliente ID + Venda ID
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _clienteIdCtrl,
                          decoration: InputDecoration(
                              labelText: 'ID Cliente'),
                          style: TextStyle(
                              color: AppTheme.textPrimary, fontSize: 14),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _vendaIdCtrl,
                          decoration:
                              InputDecoration(labelText: 'ID Venda'),
                          style: TextStyle(
                              color: AppTheme.textPrimary, fontSize: 14),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Informacoes
                  TextFormField(
                    controller: _informacoesCtrl,
                    decoration: InputDecoration(
                      labelText: 'Informacoes / Observacoes',
                      alignLabelWithHint: true,
                    ),
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    maxLines: 3,
                  ),
                  SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text('Cancelar'),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saving ? null : _salvar,
                        child: _saving
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : Text('Salvar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -- Baixa Dialog --

class _BaixaDialog extends StatefulWidget {
  final ContaReceber conta;
  const _BaixaDialog({required this.conta});

  @override
  State<_BaixaDialog> createState() => _BaixaDialogState();
}

class _BaixaDialogState extends State<_BaixaDialog> {
  String _formaRecebimento = 'dinheiro';
  DateTime _dataRecebimento = DateTime.now();
  bool _saving = false;

  final _formas = [
    'dinheiro',
    'pix',
    'cartao_credito',
    'cartao_debito',
    'boleto',
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
      case 'boleto':
        return 'Boleto';
      case 'transferencia':
        return 'Transferencia';
      default:
        return 'Outros';
    }
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataRecebimento,
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
      setState(() => _dataRecebimento = picked);
    }
  }

  Future<void> _confirmarBaixa() async {
    setState(() => _saving = true);

    try {
      await context.read<ContasReceberProvider>().darBaixa(
            widget.conta.id,
            _formaRecebimento,
            _dataRecebimento.toIso8601String().substring(0, 10),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Baixa realizada com sucesso!')),
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
                'Dar Baixa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 20),

              // Info da conta
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
                      widget.conta.descricao,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Valor: ${currencyFormat.format(widget.conta.valor)}',
                          style: TextStyle(
                            color: AppTheme.greenSuccess,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Venc: ${dateFormat.format(widget.conta.dataVencimento)}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (widget.conta.clienteNome != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Cliente: ${widget.conta.clienteNome}',
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

              // Forma de recebimento
              DropdownButtonFormField<String>(
                value: _formaRecebimento,
                decoration: InputDecoration(
                    labelText: 'Forma de Recebimento'),
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
                  if (v != null) setState(() => _formaRecebimento = v);
                },
              ),
              SizedBox(height: 12),

              // Data de recebimento
              InkWell(
                onTap: _selecionarData,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Data de Recebimento',
                    suffixIcon: Icon(Icons.calendar_today,
                        size: 18, color: AppTheme.textSecondary),
                  ),
                  child: Text(
                    dateFormat.format(_dataRecebimento),
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
                    onPressed: _saving ? null : _confirmarBaixa,
                    icon: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.check, size: 18),
                    label: Text('Confirmar Baixa'),
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
