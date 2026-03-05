import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/categoria.dart';
import '../../providers/categorias_provider.dart';

class CategoriasScreen extends StatefulWidget {
  CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoriasProvider>().carregarCategorias();
  }

  void _abrirFormulario([Categoria? categoria]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CategoriasProvider>(),
        child: _CategoriaFormDialog(categoria: categoria),
      ),
    );
    if (result == true && mounted) {
      context.read<CategoriasProvider>().carregarCategorias();
    }
  }

  void _confirmarExclusao(Categoria categoria) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Text(
          'Confirmar Exclusao',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        content: Text(
          'Deseja realmente excluir a categoria "${categoria.nome}"?\n\n'
          'Produtos vinculados a esta categoria ficarao sem categoria.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
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
        await context.read<CategoriasProvider>().excluirCategoria(categoria.id);
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
    return Consumer<CategoriasProvider>(
      builder: (context, provider, _) {
        final categorias = provider.categorias;
        final total = categorias.length;
        final ativas = categorias.where((c) => c.ativo).length;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                SizedBox(height: 20),
                _buildStatCards(total, ativas),
                SizedBox(height: 20),
                Expanded(child: _buildBody(provider, categorias)),
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
          'Categorias',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Spacer(),
        ElevatedButton.icon(
          onPressed: () => _abrirFormulario(),
          icon: Icon(Icons.add, size: 18),
          label: Text('Nova Categoria'),
        ),
      ],
    );
  }

  Widget _buildStatCards(int total, int ativas) {
    return Row(
      children: [
        _StatCard(
          label: 'Total Categorias',
          value: total.toString(),
          icon: Icons.category_outlined,
          color: AppTheme.accent,
        ),
        SizedBox(width: 16),
        _StatCard(
          label: 'Ativas',
          value: ativas.toString(),
          icon: Icons.check_circle_outline,
          color: AppTheme.greenSuccess,
        ),
        SizedBox(width: 16),
        _StatCard(
          label: 'Inativas',
          value: (total - ativas).toString(),
          icon: Icons.cancel_outlined,
          color: AppTheme.error,
        ),
      ],
    );
  }

  Widget _buildBody(CategoriasProvider provider, List<Categoria> categorias) {
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
              'Erro ao carregar categorias',
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
              onPressed: () => provider.carregarCategorias(),
              child: Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (categorias.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined,
                size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text(
              'Nenhuma categoria encontrada',
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
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Nome')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Acoes')),
          ],
          rows: categorias.map((c) => _buildRow(c)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(Categoria categoria) {
    return DataRow(cells: [
      DataCell(Text(
        categoria.id.toString(),
        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
      )),
      DataCell(Text(
        categoria.nome,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      )),
      DataCell(_StatusBadge(ativo: categoria.ativo)),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18),
            color: AppTheme.accent,
            tooltip: 'Editar',
            onPressed: () => _abrirFormulario(categoria),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18),
            color: AppTheme.error,
            tooltip: 'Excluir',
            onPressed: () => _confirmarExclusao(categoria),
          ),
        ],
      )),
    ]);
  }
}

// -- Stat Card widget --

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -- Status Badge --

class _StatusBadge extends StatelessWidget {
  final bool ativo;
  const _StatusBadge({required this.ativo});

  @override
  Widget build(BuildContext context) {
    final color = ativo ? AppTheme.greenSuccess : AppTheme.error;
    final text = ativo ? 'Ativa' : 'Inativa';

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

// -- Categoria Form Dialog --

class _CategoriaFormDialog extends StatefulWidget {
  final Categoria? categoria;
  const _CategoriaFormDialog({this.categoria});

  @override
  State<_CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<_CategoriaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  bool _saving = false;

  bool get _isEditing => widget.categoria != null;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.categoria?.nome ?? '');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'nome': _nomeCtrl.text.trim(),
    };

    try {
      final provider = context.read<CategoriasProvider>();
      if (_isEditing) {
        await provider.atualizarCategoria(widget.categoria!.id, data);
      } else {
        await provider.criarCategoria(data);
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
    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Editar Categoria' : 'Nova Categoria',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _nomeCtrl,
                  decoration: InputDecoration(labelText: 'Nome *'),
                  style:
                      TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  autofocus: true,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo obrigatorio'
                      : null,
                  onFieldSubmitted: (_) => _salvar(),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      child: Text('Cancelar'),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saving ? null : _salvar,
                      child: _saving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
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
    );
  }
}
