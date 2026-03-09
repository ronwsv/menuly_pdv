import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/cliente.dart';
import '../../providers/clientes_provider.dart';

class ClientesScreen extends StatefulWidget {
  ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ClientesProvider>().carregarClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    final provider = context.read<ClientesProvider>();
    provider.setBusca(value.isEmpty ? null : value);
    provider.carregarClientes();
  }

  void _abrirFormulario([Cliente? cliente]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ClientesProvider>(),
        child: _ClienteFormDialog(cliente: cliente),
      ),
    );
    if (result == true && mounted) {
      context.read<ClientesProvider>().carregarClientes();
    }
  }

  void _confirmarExclusao(Cliente cliente) async {
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
          'Deseja realmente excluir o cliente "${cliente.nome}"?',
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
        await context.read<ClientesProvider>().excluirCliente(cliente.id);
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
    return Consumer<ClientesProvider>(
      builder: (context, provider, _) {
        final clientes = provider.clientes;
        final totalClientes = provider.total;
        final pessoaFisica =
            clientes.where((c) => c.tipoPessoa == 'F').length;
        final pessoaJuridica =
            clientes.where((c) => c.tipoPessoa == 'J').length;

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
                _buildStatCards(totalClientes, pessoaFisica, pessoaJuridica),
                SizedBox(height: 20),

                // -- Table --
                Expanded(child: _buildBody(provider, clientes)),
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
          'Clientes',
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
              hintText: 'Buscar cliente...',
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
          label: Text('Novo Cliente'),
        ),
      ],
    );
  }

  Widget _buildStatCards(int total, int pf, int pj) {
    return Row(
      children: [
        _StatCard(
          label: 'Total Clientes',
          value: total.toString(),
          icon: Icons.people_outline,
          color: AppTheme.accent,
        ),
        SizedBox(width: 16),
        _StatCard(
          label: 'Pessoa Fisica',
          value: pf.toString(),
          icon: Icons.person_outline,
          color: AppTheme.greenSuccess,
        ),
        SizedBox(width: 16),
        _StatCard(
          label: 'Pessoa Juridica',
          value: pj.toString(),
          icon: Icons.business_outlined,
          color: AppTheme.yellowWarning,
        ),
      ],
    );
  }

  Widget _buildBody(ClientesProvider provider, List<Cliente> clientes) {
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
              'Erro ao carregar clientes',
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
              onPressed: () => provider.carregarClientes(),
              child: Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (clientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text(
              'Nenhum cliente encontrado',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final verticalController = ScrollController();
    final horizontalController = ScrollController();
    return Scrollbar(
      controller: verticalController,
      thumbVisibility: true,
      child: Scrollbar(
        controller: horizontalController,
        thumbVisibility: true,
        notificationPredicate: (notification) => notification.depth == 1,
        child: SingleChildScrollView(
          controller: verticalController,
          child: SingleChildScrollView(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(AppTheme.scaffoldBackground),
              dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
              border: TableBorder.all(color: AppTheme.border, width: 0.5),
              columnSpacing: 24,
              columns: [
                DataColumn(label: Text('Nome')),
                DataColumn(label: Text('CPF/CNPJ')),
                DataColumn(label: Text('Telefone')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Cidade/UF')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Acoes')),
              ],
              rows: clientes.map((c) => _buildRow(c)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(Cliente cliente) {
    final cidadeUf = [
      if (cliente.cidade != null && cliente.cidade!.isNotEmpty) cliente.cidade!,
      if (cliente.estado != null && cliente.estado!.isNotEmpty) cliente.estado!,
    ].join('/');

    return DataRow(cells: [
      DataCell(Tooltip(
        message: cliente.nome,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 200),
          child: Text(
            cliente.nome,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )),
      DataCell(Text(
        cliente.cpfCnpj ?? '-',
        style: TextStyle(color: AppTheme.textPrimary),
      )),
      DataCell(Text(
        cliente.telefone ?? '-',
        style: TextStyle(color: AppTheme.textPrimary),
      )),
      DataCell(Tooltip(
        message: cliente.email ?? '-',
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 200),
          child: Text(
            cliente.email ?? '-',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )),
      DataCell(Text(
        cidadeUf.isEmpty ? '-' : cidadeUf,
        style: TextStyle(color: AppTheme.textPrimary),
      )),
      DataCell(_StatusBadge(ativo: cliente.ativo)),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18),
            color: AppTheme.accent,
            tooltip: 'Editar',
            onPressed: () => _abrirFormulario(cliente),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18),
            color: AppTheme.error,
            tooltip: 'Excluir',
            onPressed: () => _confirmarExclusao(cliente),
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

// -- Cliente Form Dialog --

class _ClienteFormDialog extends StatefulWidget {
  final Cliente? cliente;
  const _ClienteFormDialog({this.cliente});

  @override
  State<_ClienteFormDialog> createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends State<_ClienteFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _cpfCnpjCtrl;
  late final TextEditingController _ieCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _cepCtrl;
  late final TextEditingController _enderecoCtrl;
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _bairroCtrl;
  late final TextEditingController _cidadeCtrl;
  late final TextEditingController _limiteCreditoCtrl;
  late final TextEditingController _outrosDadosCtrl;

  String _tipoPessoa = 'F';
  String? _estado;
  bool _saving = false;

  bool get _isEditing => widget.cliente != null;

  static const _estados = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nomeCtrl = TextEditingController(text: c?.nome ?? '');
    _cpfCnpjCtrl = TextEditingController(text: c?.cpfCnpj ?? '');
    _ieCtrl = TextEditingController(text: c?.inscricaoEstadual ?? '');
    _telefoneCtrl = TextEditingController(text: c?.telefone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _cepCtrl = TextEditingController(text: c?.cep ?? '');
    _enderecoCtrl = TextEditingController(text: c?.endereco ?? '');
    _numeroCtrl = TextEditingController(text: c?.numero ?? '');
    _bairroCtrl = TextEditingController(text: c?.bairro ?? '');
    _cidadeCtrl = TextEditingController(text: c?.cidade ?? '');
    _limiteCreditoCtrl = TextEditingController(
      text: c != null ? c.limiteCredito.toStringAsFixed(2) : '0.00',
    );
    _outrosDadosCtrl = TextEditingController(text: c?.outrosDados ?? '');
    _tipoPessoa = c?.tipoPessoa ?? 'F';
    _estado = c?.estado;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCnpjCtrl.dispose();
    _ieCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _cepCtrl.dispose();
    _enderecoCtrl.dispose();
    _numeroCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _limiteCreditoCtrl.dispose();
    _outrosDadosCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'nome': _nomeCtrl.text.trim(),
      'tipo_pessoa': _tipoPessoa,
      'cpf_cnpj':
          _cpfCnpjCtrl.text.trim().isEmpty ? null : _cpfCnpjCtrl.text.trim(),
      'inscricao_estadual':
          _ieCtrl.text.trim().isEmpty ? null : _ieCtrl.text.trim(),
      'telefone':
          _telefoneCtrl.text.trim().isEmpty ? null : _telefoneCtrl.text.trim(),
      'email':
          _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
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
      'limite_credito':
          double.tryParse(_limiteCreditoCtrl.text.trim()) ?? 0.0,
      'outros_dados': _outrosDadosCtrl.text.trim().isEmpty
          ? null
          : _outrosDadosCtrl.text.trim(),
    };

    try {
      final provider = context.read<ClientesProvider>();
      if (_isEditing) {
        await provider.atualizarCliente(widget.cliente!.id, data);
      } else {
        await provider.criarCliente(data);
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
                    _isEditing ? 'Editar Cliente' : 'Novo Cliente',
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
        // Nome *
        TextFormField(
          controller: _nomeCtrl,
          decoration: InputDecoration(labelText: 'Nome *'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo obrigatorio' : null,
        ),
        SizedBox(height: 12),

        // Tipo Pessoa
        DropdownButtonFormField<String>(
          value: _tipoPessoa,
          decoration: InputDecoration(labelText: 'Tipo Pessoa'),
          dropdownColor: AppTheme.cardSurface,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          items: [
            DropdownMenuItem(value: 'F', child: Text('Pessoa Fisica')),
            DropdownMenuItem(value: 'J', child: Text('Pessoa Juridica')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _tipoPessoa = v);
          },
        ),
        SizedBox(height: 12),

        // CPF/CNPJ
        TextFormField(
          controller: _cpfCnpjCtrl,
          decoration: InputDecoration(labelText: 'CPF/CNPJ'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        SizedBox(height: 12),

        // Inscricao Estadual
        TextFormField(
          controller: _ieCtrl,
          decoration: InputDecoration(labelText: 'Inscricao Estadual'),
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
            ..._estados.map(
              (uf) => DropdownMenuItem(value: uf, child: Text(uf)),
            ),
          ],
          onChanged: (v) => setState(() => _estado = v),
        ),
        SizedBox(height: 12),

        // Limite Credito
        TextFormField(
          controller: _limiteCreditoCtrl,
          decoration: InputDecoration(labelText: 'Limite Credito'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
        ),
        SizedBox(height: 12),

        // Outros Dados
        TextFormField(
          controller: _outrosDadosCtrl,
          decoration: InputDecoration(
            labelText: 'Outros Dados / Observacoes',
            alignLabelWithHint: true,
          ),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          maxLines: 3,
        ),
      ],
    );
  }
}
