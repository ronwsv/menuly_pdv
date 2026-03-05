import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/ordem_servico.dart';
import '../../providers/ordens_servico_provider.dart';
import '../../providers/servicos_provider.dart';
import '../../providers/produtos_provider.dart';
import '../../providers/clientes_provider.dart';

class OrdensServicoScreen extends StatefulWidget {
  OrdensServicoScreen({super.key});

  @override
  State<OrdensServicoScreen> createState() => _OrdensServicoScreenState();
}

class _OrdensServicoScreenState extends State<OrdensServicoScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdensServicoProvider>().carregarOrdens();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    final provider = context.read<OrdensServicoProvider>();
    provider.setBusca(value.isEmpty ? null : value);
    provider.carregarOrdens();
  }

  void _setStatusFilter(String status) {
    setState(() => _statusFilter = status);
    final provider = context.read<OrdensServicoProvider>();
    provider.setStatusFiltro(status.isEmpty ? null : status);
    provider.carregarOrdens();
  }

  void _abrirNovaOs() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
              value: context.read<OrdensServicoProvider>()),
          ChangeNotifierProvider.value(
              value: context.read<ClientesProvider>()),
        ],
        child: const _NovaOsDialog(),
      ),
    );
    if (result == true && mounted) {
      context.read<OrdensServicoProvider>().carregarOrdens();
    }
  }

  void _abrirDetalhes(OrdemServico os) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
              value: context.read<OrdensServicoProvider>()),
          ChangeNotifierProvider.value(
              value: context.read<ServicosProvider>()),
        ],
        child: _OsDetalheDialog(osId: os.id),
      ),
    );
    if (result == true && mounted) {
      context.read<OrdensServicoProvider>().carregarOrdens();
    }
  }

  void _confirmarCancelamento(OrdemServico os) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Text('Cancelar OS',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
        content: Text('Deseja cancelar a OS #${os.numero}?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Nao')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok = await context
          .read<OrdensServicoProvider>()
          .cancelarOrdem(os.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(ok ? 'OS cancelada' : 'Erro ao cancelar OS'),
            backgroundColor: ok ? AppTheme.greenSuccess : AppTheme.error,
          ),
        );
      }
    }
  }

  void _finalizarOs(OrdemServico os) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<OrdensServicoProvider>(),
        child: _FinalizarOsDialog(os: os),
      ),
    );
    if (result == true && mounted) {
      context.read<OrdensServicoProvider>().carregarOrdens();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return _dateFormat.format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.scaffoldBackground,
      child: Consumer<OrdensServicoProvider>(
        builder: (context, provider, _) {
          final ordens = provider.ordens;
          final abertas =
              ordens.where((o) => o.isAberta || o.isEmAndamento).length;
          final finalizadas = ordens.where((o) => o.isFinalizada).length;
          final canceladas = ordens.where((o) => o.isCancelada).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment_outlined,
                        color: AppTheme.accent, size: 28),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ordens de Servico',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                          SizedBox(height: 4),
                          Text(
                              'Gerenciamento de ordens de servico',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _abrirNovaOs,
                      icon: Icon(Icons.add, size: 20),
                      label: Text('Nova OS'),
                    ),
                  ],
                ),
              ),

              // Stat cards
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    _StatCard(
                      title: 'Total',
                      value: '${provider.total}',
                      icon: Icons.assignment_outlined,
                      color: AppTheme.accent,
                    ),
                    SizedBox(width: 16),
                    _StatCard(
                      title: 'Abertas',
                      value: '$abertas',
                      icon: Icons.pending_outlined,
                      color: AppTheme.yellowWarning,
                    ),
                    SizedBox(width: 16),
                    _StatCard(
                      title: 'Finalizadas',
                      value: '$finalizadas',
                      icon: Icons.check_circle_outline,
                      color: AppTheme.greenSuccess,
                    ),
                    SizedBox(width: 16),
                    _StatCard(
                      title: 'Canceladas',
                      value: '$canceladas',
                      icon: Icons.cancel_outlined,
                      color: AppTheme.error,
                    ),
                  ],
                ),
              ),

              // Search + filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearch,
                          style: TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Buscar por numero, cliente, pedido...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    _FilterChip(
                      label: 'Todas',
                      selected: _statusFilter.isEmpty,
                      onTap: () => _setStatusFilter(''),
                    ),
                    SizedBox(width: 8),
                    _FilterChip(
                      label: 'Abertas',
                      selected: _statusFilter == 'aberta',
                      onTap: () => _setStatusFilter('aberta'),
                    ),
                    SizedBox(width: 8),
                    _FilterChip(
                      label: 'Em Andamento',
                      selected: _statusFilter == 'em_andamento',
                      onTap: () => _setStatusFilter('em_andamento'),
                    ),
                    SizedBox(width: 8),
                    _FilterChip(
                      label: 'Finalizadas',
                      selected: _statusFilter == 'finalizada',
                      onTap: () => _setStatusFilter('finalizada'),
                    ),
                    SizedBox(width: 8),
                    _FilterChip(
                      label: 'Canceladas',
                      selected: _statusFilter == 'cancelada',
                      onTap: () => _setStatusFilter('cancelada'),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Table
              Expanded(
                child: provider.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : provider.error != null
                        ? Center(
                            child: Text('Erro: ${provider.error}',
                                style: TextStyle(color: AppTheme.error)))
                        : ordens.isEmpty
                            ? Center(
                                child: Text('Nenhuma OS encontrada',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary)))
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardSurface,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd),
                                    border:
                                        Border.all(color: AppTheme.border),
                                  ),
                                  child: SingleChildScrollView(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: DataTable(
                                        headingRowHeight: 44,
                                        dataRowMinHeight: 48,
                                        dataRowMaxHeight: 48,
                                        columnSpacing: 20,
                                        columns: [
                                          DataColumn(label: Text('Numero')),
                                          DataColumn(label: Text('Cliente')),
                                          DataColumn(label: Text('Prestador')),
                                          DataColumn(label: Text('Status')),
                                          DataColumn(label: Text('Total'),
                                              numeric: true),
                                          DataColumn(label: Text('Data')),
                                          DataColumn(label: Text('Acoes')),
                                        ],
                                        rows: ordens.map((os) {
                                          return DataRow(cells: [
                                            DataCell(
                                              GestureDetector(
                                                onTap: () =>
                                                    _abrirDetalhes(os),
                                                child: Text(
                                                  '#${os.numero}',
                                                  style: TextStyle(
                                                    color: AppTheme.accent,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(
                                                os.clienteNome ?? '-',
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                            DataCell(Text(
                                                os.prestadorNome ?? '-',
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                            DataCell(
                                                _StatusBadge(status: os.status)),
                                            DataCell(Text(
                                                _currencyFormat.format(os.total))),
                                            DataCell(Text(
                                                _formatDate(os.dataInicio),
                                                style: TextStyle(
                                                    fontSize: 13))),
                                            DataCell(
                                              Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                        Icons.visibility_outlined,
                                                        size: 18,
                                                        color: AppTheme.accent),
                                                    tooltip: 'Ver Detalhes',
                                                    onPressed: () =>
                                                        _abrirDetalhes(os),
                                                  ),
                                                  if (os.isAberta ||
                                                      os.isEmAndamento) ...[
                                                    IconButton(
                                                      icon: Icon(
                                                          Icons.check_circle_outline,
                                                          size: 18,
                                                          color: AppTheme
                                                              .greenSuccess),
                                                      tooltip: 'Finalizar',
                                                      onPressed: () =>
                                                          _finalizarOs(os),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                          Icons.cancel_outlined,
                                                          size: 18,
                                                          color: AppTheme.error),
                                                      tooltip: 'Cancelar',
                                                      onPressed: () =>
                                                          _confirmarCancelamento(
                                                              os),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ]);
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
              ),

              SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.15)
              : AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
              color: selected
                  ? AppTheme.primary.withOpacity(0.5)
                  : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppTheme.accent : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'aberta':
        color = AppTheme.yellowWarning;
        label = 'Aberta';
        break;
      case 'em_andamento':
        color = AppTheme.accent;
        label = 'Em Andamento';
        break;
      case 'finalizada':
        color = AppTheme.greenSuccess;
        label = 'Finalizada';
        break;
      case 'cancelada':
        color = AppTheme.error;
        label = 'Cancelada';
        break;
      default:
        color = AppTheme.textMuted;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ── Nova OS Dialog ──────────────────────────────────────────────────

class _NovaOsDialog extends StatefulWidget {
  const _NovaOsDialog();

  @override
  State<_NovaOsDialog> createState() => _NovaOsDialogState();
}

class _NovaOsDialogState extends State<_NovaOsDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _clienteId;
  final _detalhesCtrl = TextEditingController();
  final _pedidoCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _clientes = [];
  bool _loadingClientes = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarClientes();
    });
  }

  Future<void> _carregarClientes() async {
    try {
      final provider = context.read<ClientesProvider>();
      await provider.carregarClientes();
      if (mounted) {
        setState(() {
          _clientes = provider.clientes
              .map((c) => {'id': c.id, 'nome': c.nome})
              .toList();
          _loadingClientes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingClientes = false);
    }
  }

  @override
  void dispose() {
    _detalhesCtrl.dispose();
    _pedidoCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecione um cliente'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<OrdensServicoProvider>();
    final result = await provider.criarOrdem({
      'cliente_id': _clienteId,
      'prestador_id': 1, // TODO: pegar usuario logado
      'data_inicio': DateTime.now().toIso8601String(),
      'detalhes': _detalhesCtrl.text.trim(),
      'pedido': _pedidoCtrl.text.trim(),
      'observacoes': _observacoesCtrl.text.trim(),
    });

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result != null) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Erro ao criar OS'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
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
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nova Ordem de Servico',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              SizedBox(height: 24),
              _loadingClientes
                  ? Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: _clienteId,
                      decoration:
                          InputDecoration(labelText: 'Cliente *'),
                      items: _clientes.map((c) {
                        return DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['nome'] as String),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _clienteId = v),
                      validator: (v) =>
                          v == null ? 'Selecione um cliente' : null,
                    ),
              SizedBox(height: 16),
              TextFormField(
                controller: _pedidoCtrl,
                decoration: InputDecoration(
                    labelText: 'Pedido / Referencia'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _detalhesCtrl,
                decoration:
                    InputDecoration(labelText: 'Detalhes'),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _observacoesCtrl,
                decoration:
                    InputDecoration(labelText: 'Observacoes'),
                maxLines: 2,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Criar OS'),
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

// ── OS Detalhe Dialog ────────────────────────────────────────────────

class _OsDetalheDialog extends StatefulWidget {
  final int osId;
  const _OsDetalheDialog({required this.osId});

  @override
  State<_OsDetalheDialog> createState() => _OsDetalheDialogState();
}

class _OsDetalheDialogState extends State<_OsDetalheDialog> {
  Map<String, dynamic>? _osData;
  bool _isLoading = true;
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _carregarDetalhes();
  }

  Future<void> _carregarDetalhes() async {
    final provider = context.read<OrdensServicoProvider>();
    final data = await provider.obterOrdem(widget.osId);
    if (mounted) {
      setState(() {
        _osData = data;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      return _dateFormat.format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _adicionarServico() async {
    final servicosProvider = context.read<ServicosProvider>();
    await servicosProvider.carregarServicos(ativo: '1');

    if (!mounted) return;

    final servicos = servicosProvider.servicos;
    if (servicos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nenhum servico ativo cadastrado'),
          backgroundColor: AppTheme.yellowWarning,
        ),
      );
      return;
    }

    int? servicoId;
    double quantidade = 1;
    double precoUnitario = 0;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            side: BorderSide(color: AppTheme.border),
          ),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adicionar Servico',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: servicoId,
                  decoration:
                      InputDecoration(labelText: 'Servico *'),
                  items: servicos.map((s) {
                    return DropdownMenuItem<int>(
                      value: s.id,
                      child: Text(
                          '${s.descricao} - ${_currencyFormat.format(s.preco)}'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      servicoId = v;
                      final sel = servicos.firstWhere((s) => s.id == v);
                      precoUnitario = sel.preco;
                    });
                  },
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: '1',
                        decoration:
                            InputDecoration(labelText: 'Qtd'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            quantidade = double.tryParse(v) ?? 1,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(precoUnitario),
                        initialValue: precoUnitario.toStringAsFixed(2),
                        decoration: InputDecoration(
                            labelText: 'Preco Unit.',
                            prefixText: 'R\$ '),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            precoUnitario = double.tryParse(v) ?? 0,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancelar'),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: servicoId == null
                          ? null
                          : () => Navigator.pop(ctx, true),
                      child: Text('Adicionar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && servicoId != null && mounted) {
      final provider = context.read<OrdensServicoProvider>();
      await provider.adicionarItemServico(widget.osId, {
        'servico_id': servicoId,
        'quantidade': quantidade,
        'preco_unitario': precoUnitario,
      });
      await _carregarDetalhes();
    }
  }

  Future<void> _removerItemServico(int itemId) async {
    final provider = context.read<OrdensServicoProvider>();
    await provider.removerItemServico(widget.osId, itemId);
    await _carregarDetalhes();
  }

  Future<void> _removerItemProduto(int itemId) async {
    final provider = context.read<OrdensServicoProvider>();
    await provider.removerItemProduto(widget.osId, itemId);
    await _carregarDetalhes();
  }

  Future<void> _adicionarProduto() async {
    final produtosProvider = context.read<ProdutosProvider>();
    produtosProvider.setBusca(null);
    produtosProvider.setCategoriaFiltro(null);
    await produtosProvider.carregarProdutos();

    if (!mounted) return;

    final produtos =
        produtosProvider.produtos.where((p) => p.ativo && !p.bloqueado).toList();
    if (produtos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nenhum produto ativo cadastrado'),
          backgroundColor: AppTheme.yellowWarning,
        ),
      );
      return;
    }

    int? produtoId;
    double quantidade = 1;
    double precoUnitario = 0;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            side: BorderSide(color: AppTheme.border),
          ),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adicionar Produto',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: produtoId,
                  decoration:
                      InputDecoration(labelText: 'Produto *'),
                  items: produtos.map((p) {
                    return DropdownMenuItem<int>(
                      value: p.id,
                      child: Text(
                          '${p.descricao} - ${_currencyFormat.format(p.precoVenda)}'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      produtoId = v;
                      final sel = produtos.firstWhere((p) => p.id == v);
                      precoUnitario = sel.precoVenda;
                    });
                  },
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: '1',
                        decoration:
                            InputDecoration(labelText: 'Qtd'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            quantidade = double.tryParse(v) ?? 1,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(precoUnitario),
                        initialValue: precoUnitario.toStringAsFixed(2),
                        decoration: InputDecoration(
                            labelText: 'Preco Unit.',
                            prefixText: 'R\$ '),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            precoUnitario = double.tryParse(v) ?? 0,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancelar'),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: produtoId == null
                          ? null
                          : () => Navigator.pop(ctx, true),
                      child: Text('Adicionar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && produtoId != null && mounted) {
      final provider = context.read<OrdensServicoProvider>();
      await provider.adicionarItemProduto(widget.osId, {
        'produto_id': produtoId,
        'quantidade': quantidade,
        'preco_unitario': precoUnitario,
      });
      await _carregarDetalhes();
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
      child: Container(
        width: 750,
        constraints: BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _osData == null
                ? Center(
                    child: Text('Erro ao carregar OS',
                        style: TextStyle(color: AppTheme.error)))
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final os = _osData!;
    final status = os['status']?.toString() ?? 'aberta';
    final isEditable = status == 'aberta' || status == 'em_andamento';
    final itensServico = (os['itens_servico'] as List?) ?? [];
    final itensProduto = (os['itens_produto'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Expanded(
              child: Text(
                'OS #${os['numero']}',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
            ),
            _StatusBadge(status: status),
            SizedBox(width: 12),
            IconButton(
              icon: Icon(Icons.close, color: AppTheme.textSecondary),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),

        Divider(color: AppTheme.border, height: 24),

        // Info
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _InfoCard(
                        label: 'Cliente',
                        value: os['cliente_nome']?.toString() ?? '-'),
                    SizedBox(width: 16),
                    _InfoCard(
                        label: 'Prestador',
                        value: os['prestador_nome']?.toString() ?? '-'),
                    SizedBox(width: 16),
                    _InfoCard(
                        label: 'Data Inicio',
                        value:
                            _formatDate(os['data_inicio']?.toString())),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    if (os['pedido'] != null &&
                        os['pedido'].toString().isNotEmpty)
                      _InfoCard(
                          label: 'Pedido',
                          value: os['pedido'].toString()),
                    if (os['forma_pagamento'] != null) ...[
                      SizedBox(width: 16),
                      _InfoCard(
                          label: 'Forma Pagamento',
                          value: os['forma_pagamento'].toString()),
                    ],
                    if (os['data_termino'] != null) ...[
                      SizedBox(width: 16),
                      _InfoCard(
                          label: 'Data Termino',
                          value: _formatDate(
                              os['data_termino']?.toString())),
                    ],
                  ],
                ),

                if (os['detalhes'] != null &&
                    os['detalhes'].toString().isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text('Detalhes:',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  SizedBox(height: 4),
                  Text(os['detalhes'].toString(),
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textPrimary)),
                ],

                SizedBox(height: 20),

                // Itens Servico
                Row(
                  children: [
                    Text('Servicos',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Spacer(),
                    if (isEditable)
                      TextButton.icon(
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Adicionar'),
                        onPressed: _adicionarServico,
                      ),
                  ],
                ),
                SizedBox(height: 8),
                if (itensServico.isEmpty)
                  Text('Nenhum servico adicionado',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textMuted))
                else
                  ...itensServico.map((item) {
                    final i = item as Map<String, dynamic>;
                    final qty = _parseDouble(i['quantidade']);
                    final price = _parseDouble(i['preco_unitario']);
                    final total = _parseDouble(i['total']);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBackground,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              i['servico_descricao']?.toString() ??
                                  'Servico #${i['servico_id']}',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '${qty.toStringAsFixed(0)} x ${_currencyFormat.format(price)} = ${_currencyFormat.format(total)}',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary),
                          ),
                          if (isEditable)
                            IconButton(
                              icon: Icon(Icons.close,
                                  size: 16, color: AppTheme.error),
                              onPressed: () =>
                                  _removerItemServico(i['id'] as int),
                            ),
                        ],
                      ),
                    );
                  }),

                SizedBox(height: 16),

                // Itens Produto
                Row(
                  children: [
                    Text('Produtos',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Spacer(),
                    if (isEditable)
                      TextButton.icon(
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Adicionar'),
                        onPressed: _adicionarProduto,
                      ),
                  ],
                ),
                SizedBox(height: 8),
                if (itensProduto.isEmpty)
                  Text('Nenhum produto adicionado',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textMuted))
                else
                  ...itensProduto.map((item) {
                    final i = item as Map<String, dynamic>;
                    final qty = _parseDouble(i['quantidade']);
                    final price = _parseDouble(i['preco_unitario']);
                    final total = _parseDouble(i['total']);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBackground,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              i['produto_descricao']?.toString() ??
                                  'Produto #${i['produto_id']}',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '${qty.toStringAsFixed(0)} x ${_currencyFormat.format(price)} = ${_currencyFormat.format(total)}',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary),
                          ),
                          if (isEditable)
                            IconButton(
                              icon: Icon(Icons.close,
                                  size: 16, color: AppTheme.error),
                              onPressed: () =>
                                  _removerItemProduto(i['id'] as int),
                            ),
                        ],
                      ),
                    );
                  }),

                SizedBox(height: 20),

                // Totais
                Container(
                  padding: const EdgeInsets.all(16),
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
                          value: _currencyFormat
                              .format(_parseDouble(os['subtotal']))),
                      if (_parseDouble(os['desconto']) > 0)
                        _TotalRow(
                            label: 'Desconto',
                            value:
                                '- ${_currencyFormat.format(_parseDouble(os['desconto']))}',
                            isDiscount: true),
                      Divider(color: AppTheme.border),
                      _TotalRow(
                        label: 'TOTAL',
                        value: _currencyFormat
                            .format(_parseDouble(os['total'])),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

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
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: AppTheme.textMuted)),
            SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isDiscount;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                color:
                    isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
              )),
          Text(value,
              style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                color: isDiscount
                    ? AppTheme.error
                    : isBold
                        ? AppTheme.accent
                        : AppTheme.textPrimary,
              )),
        ],
      ),
    );
  }
}

// ── Finalizar OS Dialog ──────────────────────────────────────────────

class _FinalizarOsDialog extends StatefulWidget {
  final OrdemServico os;
  const _FinalizarOsDialog({required this.os});

  @override
  State<_FinalizarOsDialog> createState() => _FinalizarOsDialogState();
}

class _FinalizarOsDialogState extends State<_FinalizarOsDialog> {
  String _formaPagamento = 'Dinheiro';
  bool _isSubmitting = false;
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  final _formas = [
    'Dinheiro',
    'Cartao Credito',
    'Cartao Debito',
    'PIX',
    'Boleto',
    'Transferencia',
  ];

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final provider = context.read<OrdensServicoProvider>();
    final ok = await provider.finalizarOrdem(widget.os.id, {
      'forma_pagamento': _formaPagamento,
    });

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (ok) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OS finalizada com sucesso'),
            backgroundColor: AppTheme.greenSuccess,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Erro ao finalizar'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
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
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Finalizar Ordem de Servico',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            SizedBox(height: 8),
            Text('OS #${widget.os.numero}',
                style:
                    TextStyle(color: AppTheme.textSecondary)),
            SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBackground,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(
                    _currencyFormat.format(widget.os.total),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _formaPagamento,
              decoration: InputDecoration(
                  labelText: 'Forma de Pagamento *'),
              items: _formas.map((f) {
                return DropdownMenuItem(value: f, child: Text(f));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _formaPagamento = v);
              },
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.greenSuccess),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Finalizar OS'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
