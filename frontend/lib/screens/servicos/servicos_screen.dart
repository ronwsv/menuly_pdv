import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/servico.dart';
import '../../providers/servicos_provider.dart';

class ServicosScreen extends StatefulWidget {
  ServicosScreen({super.key});

  @override
  State<ServicosScreen> createState() => _ServicosScreenState();
}

class _ServicosScreenState extends State<ServicosScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  String _filtroAtivo = 'todos';

  @override
  void initState() {
    super.initState();
    context.read<ServicosProvider>().carregarServicos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    final provider = context.read<ServicosProvider>();
    provider.setBusca(value.isEmpty ? null : value);
    provider.carregarServicos();
  }

  void _setFiltroAtivo(String filtro) {
    setState(() => _filtroAtivo = filtro);
    final provider = context.read<ServicosProvider>();
    if (filtro == 'ativos') {
      provider.setAtivoFiltro('1');
    } else if (filtro == 'inativos') {
      provider.setAtivoFiltro('0');
    } else {
      provider.setAtivoFiltro(null);
    }
    provider.carregarServicos();
  }

  void _abrirFormulario([Servico? servico]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ServicosProvider>(),
        child: _ServicoFormDialog(servico: servico),
      ),
    );
    if (result == true && mounted) {
      context.read<ServicosProvider>().carregarServicos();
    }
  }

  void _confirmarExclusao(Servico servico) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Text('Excluir Servico',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
        content: Text(
          'Deseja excluir o servico "${servico.descricao}"?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok = await context.read<ServicosProvider>().excluirServico(servico.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Servico excluido' : 'Erro ao excluir servico'),
            backgroundColor: ok ? AppTheme.greenSuccess : AppTheme.error,
          ),
        );
      }
    }
  }

  void _confirmarInativacao(Servico servico) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Text('Inativar Servico',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
        content: Text(
          'Deseja inativar o servico "${servico.descricao}"?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.yellowWarning),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Inativar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok =
          await context.read<ServicosProvider>().inativarServico(servico.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(ok ? 'Servico inativado' : 'Erro ao inativar servico'),
            backgroundColor: ok ? AppTheme.greenSuccess : AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.scaffoldBackground,
      child: Consumer<ServicosProvider>(
        builder: (context, provider, _) {
          final servicos = provider.servicos;
          final ativos = servicos.where((s) => s.ativo).length;
          final inativos = servicos.where((s) => !s.ativo).length;

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
                    Icon(Icons.build_outlined,
                        color: AppTheme.accent, size: 28),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Servicos',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                          SizedBox(height: 4),
                          Text('Cadastro e gerenciamento de servicos',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _abrirFormulario(),
                      icon: Icon(Icons.add, size: 20),
                      label: Text('Novo Servico'),
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
                      icon: Icons.build_outlined,
                      color: AppTheme.accent,
                    ),
                    SizedBox(width: 16),
                    _StatCard(
                      title: 'Ativos',
                      value: '$ativos',
                      icon: Icons.check_circle_outline,
                      color: AppTheme.greenSuccess,
                    ),
                    SizedBox(width: 16),
                    _StatCard(
                      title: 'Inativos',
                      value: '$inativos',
                      icon: Icons.cancel_outlined,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
              ),

              // Search + filter
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
                            hintText: 'Buscar servico...',
                            prefixIcon:
                                Icon(Icons.search, size: 20),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    _FilterChip(
                      label: 'Todos',
                      selected: _filtroAtivo == 'todos',
                      onTap: () => _setFiltroAtivo('todos'),
                    ),
                    SizedBox(width: 8),
                    _FilterChip(
                      label: 'Ativos',
                      selected: _filtroAtivo == 'ativos',
                      onTap: () => _setFiltroAtivo('ativos'),
                    ),
                    SizedBox(width: 8),
                    _FilterChip(
                      label: 'Inativos',
                      selected: _filtroAtivo == 'inativos',
                      onTap: () => _setFiltroAtivo('inativos'),
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
                                style: TextStyle(
                                    color: AppTheme.error)))
                        : servicos.isEmpty
                            ? Center(
                                child: Text(
                                    'Nenhum servico encontrado',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary)))
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardSurface,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd),
                                    border: Border.all(
                                        color: AppTheme.border),
                                  ),
                                  child: SingleChildScrollView(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: DataTable(
                                        headingRowHeight: 44,
                                        dataRowMinHeight: 48,
                                        dataRowMaxHeight: 48,
                                        columnSpacing: 24,
                                        columns: [
                                          DataColumn(label: Text('ID')),
                                          DataColumn(
                                              label: Text('Descricao')),
                                          DataColumn(
                                              label: Text('Preco'),
                                              numeric: true),
                                          DataColumn(
                                              label: Text('Comissao'),
                                              numeric: true),
                                          DataColumn(
                                              label: Text('Status')),
                                          DataColumn(
                                              label: Text('Acoes')),
                                        ],
                                        rows: servicos.map((s) {
                                          return DataRow(cells: [
                                            DataCell(Text('${s.id}')),
                                            DataCell(
                                              Text(s.descricao,
                                                  overflow: TextOverflow
                                                      .ellipsis),
                                            ),
                                            DataCell(Text(
                                                _currencyFormat
                                                    .format(s.preco))),
                                            DataCell(Text(
                                                _currencyFormat.format(
                                                    s.comissaoFixa))),
                                            DataCell(_StatusBadge(
                                                ativo: s.ativo)),
                                            DataCell(
                                              Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                        Icons.edit_outlined,
                                                        size: 18,
                                                        color: AppTheme
                                                            .accent),
                                                    tooltip: 'Editar',
                                                    onPressed: () =>
                                                        _abrirFormulario(
                                                            s),
                                                  ),
                                                  if (s.ativo)
                                                    IconButton(
                                                      icon: Icon(
                                                          Icons.block,
                                                          size: 18,
                                                          color: AppTheme
                                                              .yellowWarning),
                                                      tooltip:
                                                          'Inativar',
                                                      onPressed: () =>
                                                          _confirmarInativacao(
                                                              s),
                                                    ),
                                                  IconButton(
                                                    icon: Icon(
                                                        Icons
                                                            .delete_outline,
                                                        size: 18,
                                                        color: AppTheme
                                                            .error),
                                                    tooltip: 'Excluir',
                                                    onPressed: () =>
                                                        _confirmarExclusao(
                                                            s),
                                                  ),
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
                : AppTheme.border,
          ),
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
  final bool ativo;
  const _StatusBadge({required this.ativo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ativo
            ? AppTheme.greenSuccess.withOpacity(0.15)
            : AppTheme.textMuted.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        ativo ? 'Ativo' : 'Inativo',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ativo ? AppTheme.greenSuccess : AppTheme.textMuted,
        ),
      ),
    );
  }
}

// ── Form Dialog ──────────────────────────────────────────────────────

class _ServicoFormDialog extends StatefulWidget {
  final Servico? servico;
  const _ServicoFormDialog({this.servico});

  @override
  State<_ServicoFormDialog> createState() => _ServicoFormDialogState();
}

class _ServicoFormDialogState extends State<_ServicoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descricaoCtrl;
  late TextEditingController _precoCtrl;
  late TextEditingController _comissaoCtrl;
  late TextEditingController _outrosDadosCtrl;
  bool _ativo = true;
  bool _isSubmitting = false;

  bool get isEditing => widget.servico != null;

  @override
  void initState() {
    super.initState();
    _descricaoCtrl =
        TextEditingController(text: widget.servico?.descricao ?? '');
    _precoCtrl = TextEditingController(
        text: widget.servico?.preco.toStringAsFixed(2) ?? '');
    _comissaoCtrl = TextEditingController(
        text: widget.servico?.comissaoFixa.toStringAsFixed(2) ?? '0.00');
    _outrosDadosCtrl =
        TextEditingController(text: widget.servico?.outrosDados ?? '');
    _ativo = widget.servico?.ativo ?? true;
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _precoCtrl.dispose();
    _comissaoCtrl.dispose();
    _outrosDadosCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final provider = context.read<ServicosProvider>();
    final data = {
      'descricao': _descricaoCtrl.text.trim(),
      'preco': double.tryParse(_precoCtrl.text) ?? 0,
      'comissao_fixa': double.tryParse(_comissaoCtrl.text) ?? 0,
      'outros_dados': _outrosDadosCtrl.text.trim(),
      'ativo': _ativo,
    };

    bool ok;
    if (isEditing) {
      ok = await provider.atualizarServico(widget.servico!.id, data);
    } else {
      ok = await provider.criarServico(data);
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (ok) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Erro ao salvar'),
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
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Editar Servico' : 'Novo Servico',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _descricaoCtrl,
                decoration: InputDecoration(labelText: 'Descricao *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Obrigatorio' : null,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precoCtrl,
                      decoration: InputDecoration(
                          labelText: 'Preco *', prefixText: 'R\$ '),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.,]')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obrigatorio';
                        final num = double.tryParse(v.replaceAll(',', '.'));
                        if (num == null || num < 0) return 'Valor invalido';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _comissaoCtrl,
                      decoration: InputDecoration(
                          labelText: 'Comissao Fixa',
                          prefixText: 'R\$ '),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.,]')),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _outrosDadosCtrl,
                decoration:
                    InputDecoration(labelText: 'Outros dados'),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              if (isEditing)
                SwitchListTile(
                  title: Text('Ativo',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  value: _ativo,
                  onChanged: (v) => setState(() => _ativo = v),
                  contentPadding: EdgeInsets.zero,
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
                        : Text(isEditing ? 'Salvar' : 'Criar'),
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
