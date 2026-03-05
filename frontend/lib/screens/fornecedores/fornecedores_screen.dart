import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/fornecedor.dart';
import '../../providers/fornecedores_provider.dart';

class FornecedoresScreen extends StatefulWidget {
  FornecedoresScreen({super.key});

  @override
  State<FornecedoresScreen> createState() => _FornecedoresScreenState();
}

class _FornecedoresScreenState extends State<FornecedoresScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<FornecedoresProvider>().carregarFornecedores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    final provider = context.read<FornecedoresProvider>();
    provider.setBusca(value.isEmpty ? null : value);
    provider.carregarFornecedores();
  }

  void _abrirFormulario([Fornecedor? fornecedor]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<FornecedoresProvider>(),
        child: _FornecedorFormDialog(fornecedor: fornecedor),
      ),
    );
    if (result == true && mounted) {
      context.read<FornecedoresProvider>().carregarFornecedores();
    }
  }

  void _confirmarExclusao(Fornecedor fornecedor) async {
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
          'Deseja realmente excluir o fornecedor "${fornecedor.razaoSocial}"?',
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
        await context
            .read<FornecedoresProvider>()
            .excluirFornecedor(fornecedor.id);
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
    return Consumer<FornecedoresProvider>(
      builder: (context, provider, _) {
        final fornecedores = provider.fornecedores;
        final totalFornecedores = provider.total;
        final ativos = fornecedores.where((f) => f.ativo).length;
        final inativos = fornecedores.where((f) => !f.ativo).length;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -- Top bar --
                _buildTopBar(),
                SizedBox(height: 20),

                // -- Stat cards --
                _buildStatCards(totalFornecedores, ativos, inativos),
                SizedBox(height: 20),

                // -- Table --
                Expanded(child: _buildBody(provider, fornecedores)),
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
          'Fornecedores',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(width: 24),
        SizedBox(
          width: 260,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar fornecedor...',
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
          label: Text('Novo Fornecedor'),
        ),
      ],
    );
  }

  Widget _buildStatCards(int total, int ativos, int inativos) {
    return Row(
      children: [
        _StatCard(
          label: 'Total Fornecedores',
          value: total.toString(),
          icon: Icons.local_shipping_outlined,
          color: AppTheme.accent,
        ),
        SizedBox(width: 16),
        _StatCard(
          label: 'Ativos',
          value: ativos.toString(),
          icon: Icons.check_circle_outline,
          color: AppTheme.greenSuccess,
        ),
        SizedBox(width: 16),
        _StatCard(
          label: 'Inativos',
          value: inativos.toString(),
          icon: Icons.cancel_outlined,
          color: AppTheme.error,
        ),
      ],
    );
  }

  Widget _buildBody(
      FornecedoresProvider provider, List<Fornecedor> fornecedores) {
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
              'Erro ao carregar fornecedores',
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
              onPressed: () => provider.carregarFornecedores(),
              child: Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (fornecedores.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping_outlined,
                size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text(
              'Nenhum fornecedor encontrado',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(AppTheme.scaffoldBackground),
          dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
          border: TableBorder.all(color: AppTheme.border, width: 0.5),
          columnSpacing: 24,
          columns: [
            DataColumn(label: Text('Razao Social')),
            DataColumn(label: Text('Nome Fantasia')),
            DataColumn(label: Text('CNPJ')),
            DataColumn(label: Text('Telefone')),
            DataColumn(label: Text('Contato')),
            DataColumn(label: Text('Cidade/UF')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Acoes')),
          ],
          rows: fornecedores.map((f) => _buildRow(f)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(Fornecedor fornecedor) {
    final cidadeUf = [
      if (fornecedor.cidade != null && fornecedor.cidade!.isNotEmpty)
        fornecedor.cidade!,
      if (fornecedor.estado != null && fornecedor.estado!.isNotEmpty)
        fornecedor.estado!,
    ].join('/');

    return DataRow(cells: [
      DataCell(Text(
        fornecedor.razaoSocial,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      )),
      DataCell(Text(
        fornecedor.nomeFantasia ?? '-',
        style: TextStyle(color: AppTheme.textPrimary),
      )),
      DataCell(Text(
        fornecedor.cnpj ?? '-',
        style: TextStyle(color: AppTheme.textPrimary),
      )),
      DataCell(Text(
        fornecedor.telefone ?? '-',
        style: TextStyle(color: AppTheme.textPrimary),
      )),
      DataCell(Text(
        fornecedor.contato ?? '-',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      )),
      DataCell(Text(
        cidadeUf.isEmpty ? '-' : cidadeUf,
        style: TextStyle(color: AppTheme.textPrimary),
      )),
      DataCell(_StatusBadge(ativo: fornecedor.ativo)),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18),
            color: AppTheme.accent,
            tooltip: 'Editar',
            onPressed: () => _abrirFormulario(fornecedor),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18),
            color: AppTheme.error,
            tooltip: 'Excluir',
            onPressed: () => _confirmarExclusao(fornecedor),
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
    final text = ativo ? 'Ativo' : 'Inativo';

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

// -- Fornecedor Form Dialog --

class _FornecedorFormDialog extends StatefulWidget {
  final Fornecedor? fornecedor;
  const _FornecedorFormDialog({this.fornecedor});

  @override
  State<_FornecedorFormDialog> createState() => _FornecedorFormDialogState();
}

class _FornecedorFormDialogState extends State<_FornecedorFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _razaoSocialCtrl;
  late final TextEditingController _nomeFantasiaCtrl;
  late final TextEditingController _cnpjCtrl;
  late final TextEditingController _ieCtrl;
  late final TextEditingController _imCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _contatoCtrl;
  late final TextEditingController _cepCtrl;
  late final TextEditingController _enderecoCtrl;
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _bairroCtrl;
  late final TextEditingController _cidadeCtrl;
  late final TextEditingController _observacoesCtrl;

  String? _estado;
  bool _saving = false;

  bool get _isEditing => widget.fornecedor != null;

  static const _estados = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.fornecedor;
    _razaoSocialCtrl = TextEditingController(text: f?.razaoSocial ?? '');
    _nomeFantasiaCtrl = TextEditingController(text: f?.nomeFantasia ?? '');
    _cnpjCtrl = TextEditingController(text: f?.cnpj ?? '');
    _ieCtrl = TextEditingController(text: f?.inscricaoEstadual ?? '');
    _imCtrl = TextEditingController(text: f?.inscricaoMunicipal ?? '');
    _telefoneCtrl = TextEditingController(text: f?.telefone ?? '');
    _emailCtrl = TextEditingController(text: f?.email ?? '');
    _contatoCtrl = TextEditingController(text: f?.contato ?? '');
    _cepCtrl = TextEditingController(text: f?.cep ?? '');
    _enderecoCtrl = TextEditingController(text: f?.endereco ?? '');
    _numeroCtrl = TextEditingController(text: f?.numero ?? '');
    _bairroCtrl = TextEditingController(text: f?.bairro ?? '');
    _cidadeCtrl = TextEditingController(text: f?.cidade ?? '');
    _observacoesCtrl = TextEditingController(text: f?.observacoes ?? '');
    _estado = f?.estado;
  }

  @override
  void dispose() {
    _razaoSocialCtrl.dispose();
    _nomeFantasiaCtrl.dispose();
    _cnpjCtrl.dispose();
    _ieCtrl.dispose();
    _imCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _contatoCtrl.dispose();
    _cepCtrl.dispose();
    _enderecoCtrl.dispose();
    _numeroCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'razao_social': _razaoSocialCtrl.text.trim(),
      'nome_fantasia': _nomeFantasiaCtrl.text.trim().isEmpty
          ? null
          : _nomeFantasiaCtrl.text.trim(),
      'cnpj': _cnpjCtrl.text.trim().isEmpty ? null : _cnpjCtrl.text.trim(),
      'inscricao_estadual':
          _ieCtrl.text.trim().isEmpty ? null : _ieCtrl.text.trim(),
      'inscricao_municipal':
          _imCtrl.text.trim().isEmpty ? null : _imCtrl.text.trim(),
      'telefone':
          _telefoneCtrl.text.trim().isEmpty ? null : _telefoneCtrl.text.trim(),
      'email':
          _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'contato':
          _contatoCtrl.text.trim().isEmpty ? null : _contatoCtrl.text.trim(),
      'cep': _cepCtrl.text.trim().isEmpty ? null : _cepCtrl.text.trim(),
      'endereco':
          _enderecoCtrl.text.trim().isEmpty ? null : _enderecoCtrl.text.trim(),
      'numero':
          _numeroCtrl.text.trim().isEmpty ? null : _numeroCtrl.text.trim(),
      'bairro':
          _bairroCtrl.text.trim().isEmpty ? null : _bairroCtrl.text.trim(),
      'cidade':
          _cidadeCtrl.text.trim().isEmpty ? null : _cidadeCtrl.text.trim(),
      'estado': _estado,
      'observacoes': _observacoesCtrl.text.trim().isEmpty
          ? null
          : _observacoesCtrl.text.trim(),
    };

    try {
      final provider = context.read<FornecedoresProvider>();
      if (_isEditing) {
        await provider.atualizarFornecedor(widget.fornecedor!.id, data);
      } else {
        await provider.criarFornecedor(data);
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
        width: 780,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -- Title --
                  Text(
                    _isEditing ? 'Editar Fornecedor' : 'Novo Fornecedor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 20),

                  // -- Two-column layout --
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column
                      Expanded(child: _buildLeftColumn()),
                      SizedBox(width: 20),
                      // Right column
                      Expanded(child: _buildRightColumn()),
                    ],
                  ),
                  SizedBox(height: 24),

                  // -- Action buttons --
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
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Razao Social *
        TextFormField(
          controller: _razaoSocialCtrl,
          decoration: InputDecoration(labelText: 'Razao Social *'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo obrigatorio' : null,
        ),
        SizedBox(height: 12),

        // Nome Fantasia
        TextFormField(
          controller: _nomeFantasiaCtrl,
          decoration: InputDecoration(labelText: 'Nome Fantasia'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        SizedBox(height: 12),

        // CNPJ
        TextFormField(
          controller: _cnpjCtrl,
          decoration: InputDecoration(labelText: 'CNPJ'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        SizedBox(height: 12),

        // IE
        TextFormField(
          controller: _ieCtrl,
          decoration: InputDecoration(labelText: 'Inscricao Estadual'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        SizedBox(height: 12),

        // IM
        TextFormField(
          controller: _imCtrl,
          decoration: InputDecoration(labelText: 'Inscricao Municipal'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        SizedBox(height: 12),

        // Telefone
        TextFormField(
          controller: _telefoneCtrl,
          decoration: InputDecoration(labelText: 'Telefone'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        SizedBox(height: 12),

        // Email
        TextFormField(
          controller: _emailCtrl,
          decoration: InputDecoration(labelText: 'Email'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        SizedBox(height: 12),

        // Contato
        TextFormField(
          controller: _contatoCtrl,
          decoration: InputDecoration(labelText: 'Contato'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // CEP
        TextFormField(
          controller: _cepCtrl,
          decoration: InputDecoration(labelText: 'CEP'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        SizedBox(height: 12),

        // Endereco
        TextFormField(
          controller: _enderecoCtrl,
          decoration: InputDecoration(labelText: 'Endereco'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        SizedBox(height: 12),

        // Numero
        TextFormField(
          controller: _numeroCtrl,
          decoration: InputDecoration(labelText: 'Numero'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        SizedBox(height: 12),

        // Bairro
        TextFormField(
          controller: _bairroCtrl,
          decoration: InputDecoration(labelText: 'Bairro'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        SizedBox(height: 12),

        // Cidade
        TextFormField(
          controller: _cidadeCtrl,
          decoration: InputDecoration(labelText: 'Cidade'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        SizedBox(height: 12),

        // Estado
        DropdownButtonFormField<String?>(
          value: _estado,
          decoration: InputDecoration(labelText: 'Estado'),
          dropdownColor: AppTheme.cardSurface,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Selecione'),
            ),
            ..._estados
                .map((uf) => DropdownMenuItem(value: uf, child: Text(uf))),
          ],
          onChanged: (v) => setState(() => _estado = v),
        ),
        SizedBox(height: 12),

        // Observacoes (multiline)
        TextFormField(
          controller: _observacoesCtrl,
          decoration: InputDecoration(
            labelText: 'Observacoes',
            alignLabelWithHint: true,
          ),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          maxLines: 4,
          minLines: 3,
        ),
      ],
    );
  }
}
