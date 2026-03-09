import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../providers/configuracoes_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/backup_provider.dart';
import '../../models/configuracao.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';

/// Converts [List<Configuracao>] to a Map keyed by [Configuracao.chave].
Map<String, String> _configsToMap(List<Configuracao> configs) {
  return {for (final c in configs) c.chave: c.valor ?? ''};
}

class ConfiguracoesScreen extends StatefulWidget {
  ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    _loadData();
  }

  void _loadData() {
    final provider = context.read<ConfiguracoesProvider>();
    provider.carregarConfigs();
    provider.carregarUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Header --
            Row(
              children: [
                Text(
                  'Configuracoes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: _loadData,
                  icon: Icon(Icons.refresh, color: AppTheme.textSecondary),
                  tooltip: 'Atualizar',
                ),
              ],
            ),
            SizedBox(height: 16),

            // -- Tab bar --
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppTheme.textPrimary,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                dividerHeight: 0,
                tabs: [
                  Tab(text: 'Empresa'),
                  Tab(text: 'Usuarios'),
                  Tab(text: 'Sistema'),
                  Tab(text: 'Aparencia'),
                  Tab(text: 'Backup'),
                ],
              ),
            ),
            SizedBox(height: 16),

            // -- Tab content --
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _EmpresaTab(),
                  _UsuariosTab(),
                  _SistemaTab(),
                  _AparenciaTab(),
                  _BackupTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// EMPRESA TAB
// =============================================================================

class _EmpresaTab extends StatefulWidget {
  const _EmpresaTab();

  @override
  State<_EmpresaTab> createState() => _EmpresaTabState();
}

class _EmpresaTabState extends State<_EmpresaTab> {
  final _formKey = GlobalKey<FormState>();
  final _razaoSocialCtrl = TextEditingController();
  final _nomeFantasiaCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _inscEstadualCtrl = TextEditingController();
  final _inscMunicipalCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarEmitente();
  }

  Future<void> _carregarEmitente() async {
    try {
      final api = context.read<ApiClient>();
      final resp = await api.get(ApiConfig.emitente);
      final data = resp['data'] as Map<String, dynamic>?;
      if (data != null) {
        _razaoSocialCtrl.text = data['razao_social'] ?? '';
        _nomeFantasiaCtrl.text = data['nome_fantasia'] ?? '';
        _cnpjCtrl.text = data['cnpj'] ?? '';
        _inscEstadualCtrl.text = data['inscricao_estadual'] ?? '';
        _inscMunicipalCtrl.text = data['inscricao_municipal'] ?? '';
        _enderecoCtrl.text = data['endereco'] ?? '';
        _numeroCtrl.text = data['numero'] ?? '';
        _complementoCtrl.text = data['complemento'] ?? '';
        _bairroCtrl.text = data['bairro'] ?? '';
        _cidadeCtrl.text = data['cidade'] ?? '';
        _estadoCtrl.text = data['estado'] ?? '';
        _cepCtrl.text = data['cep'] ?? '';
        _telefoneCtrl.text = data['telefone'] ?? '';
        _emailCtrl.text = data['email'] ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _razaoSocialCtrl.dispose();
    _nomeFantasiaCtrl.dispose();
    _cnpjCtrl.dispose();
    _inscEstadualCtrl.dispose();
    _inscMunicipalCtrl.dispose();
    _enderecoCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    _cepCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final api = context.read<ApiClient>();
      await api.put(ApiConfig.emitente, body: {
        'razao_social': _razaoSocialCtrl.text.trim(),
        'nome_fantasia': _nomeFantasiaCtrl.text.trim(),
        'cnpj': _cnpjCtrl.text.trim(),
        'inscricao_estadual': _inscEstadualCtrl.text.trim(),
        'inscricao_municipal': _inscMunicipalCtrl.text.trim(),
        'endereco': _enderecoCtrl.text.trim(),
        'numero': _numeroCtrl.text.trim(),
        'complemento': _complementoCtrl.text.trim(),
        'bairro': _bairroCtrl.text.trim(),
        'cidade': _cidadeCtrl.text.trim(),
        'estado': _estadoCtrl.text.trim(),
        'cep': _cepCtrl.text.trim(),
        'telefone': _telefoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dados da empresa salvos com sucesso')),
        );
      }
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
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    final fieldStyle = TextStyle(color: AppTheme.textPrimary, fontSize: 14);

    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dados da Empresa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 20),

              TextFormField(
                controller: _razaoSocialCtrl,
                decoration: InputDecoration(labelText: 'Razao Social'),
                style: fieldStyle,
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _nomeFantasiaCtrl,
                decoration: InputDecoration(labelText: 'Nome Fantasia'),
                style: fieldStyle,
              ),
              SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cnpjCtrl,
                      decoration: InputDecoration(labelText: 'CNPJ'),
                      style: fieldStyle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _inscEstadualCtrl,
                      decoration: InputDecoration(labelText: 'Inscricao Estadual'),
                      style: fieldStyle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _inscMunicipalCtrl,
                decoration: InputDecoration(labelText: 'Inscricao Municipal'),
                style: fieldStyle,
              ),
              SizedBox(height: 20),

              Text(
                'Endereco',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _enderecoCtrl,
                      decoration: InputDecoration(labelText: 'Logradouro'),
                      style: fieldStyle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _numeroCtrl,
                      decoration: InputDecoration(labelText: 'Numero'),
                      style: fieldStyle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _complementoCtrl,
                decoration: InputDecoration(labelText: 'Complemento'),
                style: fieldStyle,
              ),
              SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _bairroCtrl,
                      decoration: InputDecoration(labelText: 'Bairro'),
                      style: fieldStyle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cidadeCtrl,
                      decoration: InputDecoration(labelText: 'Cidade'),
                      style: fieldStyle,
                    ),
                  ),
                  SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _estadoCtrl,
                      decoration: InputDecoration(labelText: 'UF'),
                      style: fieldStyle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: _cepCtrl,
                  decoration: InputDecoration(labelText: 'CEP'),
                  style: fieldStyle,
                ),
              ),
              SizedBox(height: 20),

              Text(
                'Contato',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _telefoneCtrl,
                      decoration: InputDecoration(labelText: 'Telefone'),
                      style: fieldStyle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(labelText: 'Email'),
                      style: fieldStyle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _saving ? null : _salvar,
                  child: _saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// USUARIOS TAB
// =============================================================================

class _UsuariosTab extends StatelessWidget {
  const _UsuariosTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfiguracoesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppTheme.error),
                SizedBox(height: 12),
                Text(
                  'Erro ao carregar usuarios',
                  style:
                      TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
                SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => provider.carregarUsuarios(),
                  child: Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        final usuarios = provider.usuarios;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(
                  'Gerenciar Usuarios',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _abrirFormularioUsuario(context),
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Novo Usuario'),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Table
            Expanded(
              child: usuarios.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 48, color: AppTheme.textSecondary),
                          SizedBox(height: 12),
                          Text(
                            'Nenhum usuario cadastrado',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                              AppTheme.scaffoldBackground),
                          dataRowColor:
                              WidgetStateProperty.all(AppTheme.cardSurface),
                          border: TableBorder.all(
                              color: AppTheme.border, width: 0.5),
                          columns: [
                            DataColumn(label: Text('Nome')),
                            DataColumn(label: Text('Login')),
                            DataColumn(label: Text('Papel')),
                            DataColumn(label: Text('Permissoes')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Acoes')),
                          ],
                          rows: usuarios.map((u) {
                            final permissoes = <String>[];
                            if (u.permPdv) permissoes.add('PDV');
                            if (u.permProdutos) permissoes.add('Produtos');
                            if (u.permEstoque) permissoes.add('Estoque');
                            if (u.permVendas) permissoes.add('Vendas');
                            if (u.permCompras) permissoes.add('Compras');
                            if (u.permClientes) permissoes.add('Clientes');
                            if (u.permFornecedores) permissoes.add('Fornecedores');
                            if (u.permCategorias) permissoes.add('Categorias');
                            if (u.permCaixa) permissoes.add('Caixas');
                            if (u.permContasReceber) permissoes.add('Contas Rec.');
                            if (u.permContasPagar) permissoes.add('Contas Pag.');
                            if (u.permCrediario) permissoes.add('Crediario');
                            if (u.permServicos) permissoes.add('Servicos');
                            if (u.permOrdensServico) permissoes.add('OS');
                            if (u.permDevolucoes) permissoes.add('Devolucoes');
                            if (u.permConsignacoes) permissoes.add('Consignacoes');
                            if (u.permRelatorios) permissoes.add('Relatorios');

                            return DataRow(cells: [
                              DataCell(Text(
                                u.nome,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              )),
                              DataCell(Text(
                                u.login,
                                style: TextStyle(
                                    color: AppTheme.textPrimary),
                              )),
                              DataCell(_PapelBadge(papel: u.papel)),
                              DataCell(Text(
                                permissoes.isEmpty
                                    ? '-'
                                    : permissoes.join(', '),
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                              DataCell(_StatusBadge(ativo: u.ativo)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined,
                                        size: 18),
                                    color: AppTheme.accent,
                                    tooltip: 'Editar',
                                    onPressed: () =>
                                        _abrirFormularioUsuario(context, u),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                        Icons.delete_outline,
                                        size: 18),
                                    color: AppTheme.error,
                                    tooltip: 'Excluir',
                                    onPressed: () =>
                                        _confirmarExclusao(context, u),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _abrirFormularioUsuario(BuildContext context,
      [Usuario? usuario]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ConfiguracoesProvider>(),
        child: _UserFormDialog(usuario: usuario),
      ),
    );
    if (result == true) {
      // ignore: use_build_context_synchronously
      context.read<ConfiguracoesProvider>().carregarUsuarios();
    }
  }

  void _confirmarExclusao(
      BuildContext context, Usuario usuario) async {
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
          'Deseja realmente excluir o usuario "${usuario.nome}"?',
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

    if (confirm == true) {
      try {
        // Provider has no excluirUsuario; deactivate the user instead.
        // ignore: use_build_context_synchronously
        await context.read<ConfiguracoesProvider>().atualizarUsuario(
              usuario.id,
              {'ativo': false},
            );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
  }
}

// =============================================================================
// SISTEMA TAB
// =============================================================================

class _SistemaTab extends StatefulWidget {
  const _SistemaTab();

  @override
  State<_SistemaTab> createState() => _SistemaTabState();
}

class _SistemaTabState extends State<_SistemaTab> {
  final _impressoraCtrl = TextEditingController();
  final _casasDecimaisCtrl = TextEditingController();
  final _moedaCtrl = TextEditingController();
  final _comissaoPadraoCtrl = TextEditingController();
  String _impressaoCupom = 'perguntar';
  String _larguraCupom = '80';
  bool _saving = false;

  static const _opcoesImpressao = {
    'automatico': 'Imprimir automaticamente',
    'perguntar': 'Perguntar ao finalizar venda',
    'desativado': 'Nao imprimir cupom',
  };

  static const _opcoesLargura = {
    '58': '58mm (Mini impressora)',
    '80': '80mm (Padrao)',
  };

  @override
  void initState() {
    super.initState();
    _loadConfigValues();
  }

  void _loadConfigValues() {
    final provider = context.read<ConfiguracoesProvider>();
    final configs = _configsToMap(provider.configs);
    _impressoraCtrl.text = configs['impressora_padrao'] ?? '';
    _casasDecimaisCtrl.text = configs['casas_decimais'] ?? '2';
    _moedaCtrl.text = configs['moeda'] ?? 'BRL';
    _comissaoPadraoCtrl.text = configs['comissao_percentual_padrao'] ?? '0';
    _impressaoCupom = configs['impressao_cupom'] ?? 'perguntar';
    _larguraCupom = configs['largura_cupom'] ?? '80';
  }

  @override
  void dispose() {
    _impressoraCtrl.dispose();
    _casasDecimaisCtrl.dispose();
    _moedaCtrl.dispose();
    _comissaoPadraoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);

    try {
      final provider = context.read<ConfiguracoesProvider>();
      await provider.salvarConfig(
          'impressora_padrao', _impressoraCtrl.text.trim());
      await provider.salvarConfig(
          'casas_decimais', _casasDecimaisCtrl.text.trim());
      await provider.salvarConfig('moeda', _moedaCtrl.text.trim());
      await provider.salvarConfig('impressao_cupom', _impressaoCupom);
      await provider.salvarConfig('largura_cupom', _larguraCupom);
      await provider.salvarConfig(
          'comissao_percentual_padrao', _comissaoPadraoCtrl.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Configuracoes salvas com sucesso')),
        );
      }
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
    return Consumer<ConfiguracoesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        // Sync controllers when config reloads
        final configs = _configsToMap(provider.configs);
        if (_impressoraCtrl.text.isEmpty &&
            (configs['impressora_padrao'] ?? '').isNotEmpty) {
          _impressoraCtrl.text = configs['impressora_padrao'] ?? '';
          _casasDecimaisCtrl.text = configs['casas_decimais'] ?? '2';
          _moedaCtrl.text = configs['moeda'] ?? 'BRL';
          _comissaoPadraoCtrl.text = configs['comissao_percentual_padrao'] ?? '0';
          _impressaoCupom = configs['impressao_cupom'] ?? 'perguntar';
          _larguraCupom = configs['largura_cupom'] ?? '80';
        }

        return SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuracoes do Sistema',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 20),

                TextFormField(
                  controller: _impressoraCtrl,
                  decoration:
                      InputDecoration(labelText: 'Impressora Padrao'),
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                ),
                SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _casasDecimaisCtrl,
                        decoration: InputDecoration(
                            labelText: 'Casas Decimais'),
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _moedaCtrl,
                        decoration:
                            InputDecoration(labelText: 'Moeda'),
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Comissão section
                Text(
                  'Vendas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Percentual padrao de comissao para vendedores sem valor individual',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _comissaoPadraoCtrl,
                  decoration: InputDecoration(
                    labelText: 'Comissao Padrao (%)',
                    prefixIcon: Icon(Icons.percent,
                        color: AppTheme.textSecondary, size: 20),
                  ),
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                ),

                SizedBox(height: 20),

                // Impressao section
                Text(
                  'Impressao de Cupom',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Configure o comportamento ao finalizar uma venda',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _impressaoCupom,
                        decoration: InputDecoration(
                          labelText: 'Ao finalizar venda',
                          prefixIcon: Icon(Icons.receipt_long,
                              color: AppTheme.textSecondary, size: 20),
                        ),
                        dropdownColor: AppTheme.cardSurface,
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        items: _opcoesImpressao.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _impressaoCupom = v);
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _larguraCupom,
                        decoration: InputDecoration(
                          labelText: 'Largura do Cupom',
                          prefixIcon: Icon(Icons.straighten,
                              color: AppTheme.textSecondary, size: 20),
                        ),
                        dropdownColor: AppTheme.cardSurface,
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        items: _opcoesLargura.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _larguraCupom = v);
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// USER FORM DIALOG
// =============================================================================

class _UserFormDialog extends StatefulWidget {
  final Usuario? usuario;
  const _UserFormDialog({this.usuario});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _loginCtrl;
  late final TextEditingController _senhaCtrl;
  late final TextEditingController _maxDescontoCtrl;

  String _papel = 'operador';
  bool _permPdv = true;
  bool _permProdutos = false;
  bool _permEstoque = false;
  bool _permVendas = false;
  bool _permCompras = false;
  bool _permClientes = true;
  bool _permFornecedores = false;
  bool _permCategorias = false;
  bool _permCaixa = false;
  bool _permContasReceber = false;
  bool _permContasPagar = false;
  bool _permCrediario = false;
  bool _permServicos = false;
  bool _permOrdensServico = false;
  bool _permDevolucoes = false;
  bool _permConsignacoes = false;
  bool _permRelatorios = false;
  late TextEditingController _comissaoCtrl;
  bool _ativo = true;
  bool _saving = false;

  bool get _isEditing => widget.usuario != null;

  static const _papeis = ['admin', 'gerente', 'operador', 'vendedor'];

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nomeCtrl = TextEditingController(text: u?.nome ?? '');
    _loginCtrl = TextEditingController(text: u?.login ?? '');
    _senhaCtrl = TextEditingController();
    _maxDescontoCtrl = TextEditingController(
      text: u?.maxDesconto.toString() ?? '0',
    );
    _papel = u?.papel ?? 'operador';
    _permPdv = u?.permPdv ?? true;
    _permProdutos = u?.permProdutos ?? false;
    _permEstoque = u?.permEstoque ?? false;
    _permVendas = u?.permVendas ?? false;
    _permCompras = u?.permCompras ?? false;
    _permClientes = u?.permClientes ?? true;
    _permFornecedores = u?.permFornecedores ?? false;
    _permCategorias = u?.permCategorias ?? false;
    _permCaixa = u?.permCaixa ?? false;
    _permContasReceber = u?.permContasReceber ?? false;
    _permContasPagar = u?.permContasPagar ?? false;
    _permCrediario = u?.permCrediario ?? false;
    _permServicos = u?.permServicos ?? false;
    _permOrdensServico = u?.permOrdensServico ?? false;
    _permDevolucoes = u?.permDevolucoes ?? false;
    _permConsignacoes = u?.permConsignacoes ?? false;
    _permRelatorios = u?.permRelatorios ?? false;
    _comissaoCtrl = TextEditingController(
      text: u?.comissaoPercentual != null ? u!.comissaoPercentual!.toString() : '',
    );
    _ativo = u?.ativo ?? true;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _loginCtrl.dispose();
    _senhaCtrl.dispose();
    _maxDescontoCtrl.dispose();
    _comissaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'nome': _nomeCtrl.text.trim(),
      'login': _loginCtrl.text.trim(),
      'papel': _papel,
      'perm_pdv': _permPdv,
      'perm_produtos': _permProdutos,
      'perm_estoque': _permEstoque,
      'perm_vendas': _permVendas,
      'perm_compras': _permCompras,
      'perm_clientes': _permClientes,
      'perm_fornecedores': _permFornecedores,
      'perm_categorias': _permCategorias,
      'perm_caixa': _permCaixa,
      'perm_contas_receber': _permContasReceber,
      'perm_contas_pagar': _permContasPagar,
      'perm_crediario': _permCrediario,
      'perm_servicos': _permServicos,
      'perm_ordens_servico': _permOrdensServico,
      'perm_devolucoes': _permDevolucoes,
      'perm_consignacoes': _permConsignacoes,
      'perm_relatorios': _permRelatorios,
      'max_desconto': double.tryParse(_maxDescontoCtrl.text.trim()) ?? 0,
      'ativo': _ativo,
    };

    final comissaoText = _comissaoCtrl.text.trim();
    if (comissaoText.isNotEmpty) {
      data['comissao_percentual'] = double.tryParse(comissaoText) ?? 0;
    } else {
      data['comissao_percentual'] = null;
    }

    if (_senhaCtrl.text.isNotEmpty) {
      data['senha'] = _senhaCtrl.text;
    }

    try {
      final provider = context.read<ConfiguracoesProvider>();
      if (_isEditing) {
        await provider.atualizarUsuario(widget.usuario!.id, data);
      } else {
        await provider.criarUsuario(data);
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
                  // -- Title --
                  Text(
                    _isEditing ? 'Editar Usuario' : 'Novo Usuario',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Nome *
                  TextFormField(
                    controller: _nomeCtrl,
                    decoration: InputDecoration(labelText: 'Nome *'),
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatorio'
                        : null,
                  ),
                  SizedBox(height: 12),

                  // Login *
                  TextFormField(
                    controller: _loginCtrl,
                    decoration: InputDecoration(labelText: 'Login *'),
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatorio'
                        : null,
                  ),
                  SizedBox(height: 12),

                  // Senha (required only on create)
                  TextFormField(
                    controller: _senhaCtrl,
                    decoration: InputDecoration(
                      labelText:
                          _isEditing ? 'Senha (deixe vazio para manter)' : 'Senha *',
                    ),
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    obscureText: true,
                    validator: (v) {
                      if (!_isEditing && (v == null || v.trim().isEmpty)) {
                        return 'Campo obrigatorio';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),

                  // Papel
                  DropdownButtonFormField<String>(
                    value: _papel,
                    decoration: InputDecoration(labelText: 'Papel'),
                    dropdownColor: AppTheme.cardSurface,
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    items: _papeis
                        .map((p) =>
                            DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _papel = v);
                    },
                  ),
                  SizedBox(height: 12),

                  // Max Desconto
                  TextFormField(
                    controller: _maxDescontoCtrl,
                    decoration:
                        InputDecoration(labelText: 'Max Desconto (%)'),
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Comissão
                  TextFormField(
                    controller: _comissaoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Comissao (%)',
                      hintText: 'Vazio = usar padrao global',
                    ),
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Permissions
                  Text(
                    'Permissoes de Modulos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Selecione os modulos que este usuario pode acessar',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),

                  Wrap(
                    spacing: 12,
                    runSpacing: 2,
                    children: [
                      _buildCheckbox('PDV', _permPdv,
                          (v) => setState(() => _permPdv = v ?? false)),
                      _buildCheckbox('Produtos', _permProdutos,
                          (v) => setState(() => _permProdutos = v ?? false)),
                      _buildCheckbox('Estoque', _permEstoque,
                          (v) => setState(() => _permEstoque = v ?? false)),
                      _buildCheckbox('Vendas', _permVendas,
                          (v) => setState(() => _permVendas = v ?? false)),
                      _buildCheckbox('Compras', _permCompras,
                          (v) => setState(() => _permCompras = v ?? false)),
                      _buildCheckbox('Clientes', _permClientes,
                          (v) => setState(() => _permClientes = v ?? false)),
                      _buildCheckbox('Fornecedores', _permFornecedores,
                          (v) => setState(() => _permFornecedores = v ?? false)),
                      _buildCheckbox('Categorias', _permCategorias,
                          (v) => setState(() => _permCategorias = v ?? false)),
                      _buildCheckbox('Caixas', _permCaixa,
                          (v) => setState(() => _permCaixa = v ?? false)),
                      _buildCheckbox('Contas a Receber', _permContasReceber,
                          (v) => setState(() => _permContasReceber = v ?? false)),
                      _buildCheckbox('Contas a Pagar', _permContasPagar,
                          (v) => setState(() => _permContasPagar = v ?? false)),
                      _buildCheckbox('Crediario', _permCrediario,
                          (v) => setState(() => _permCrediario = v ?? false)),
                      _buildCheckbox('Servicos', _permServicos,
                          (v) => setState(() => _permServicos = v ?? false)),
                      _buildCheckbox('Ordens de Servico', _permOrdensServico,
                          (v) => setState(() => _permOrdensServico = v ?? false)),
                      _buildCheckbox('Trocas e Devolucoes', _permDevolucoes,
                          (v) => setState(() => _permDevolucoes = v ?? false)),
                      _buildCheckbox('Consignacoes', _permConsignacoes,
                          (v) => setState(() => _permConsignacoes = v ?? false)),
                      _buildCheckbox('Relatorios', _permRelatorios,
                          (v) => setState(() => _permRelatorios = v ?? false)),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Ativo toggle
                  Row(
                    children: [
                      Text(
                        'Ativo',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(width: 12),
                      Switch(
                        value: _ativo,
                        onChanged: (v) => setState(() => _ativo = v),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // -- Action buttons --
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

  Widget _buildCheckbox(
      String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

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

class _PapelBadge extends StatelessWidget {
  final String papel;
  const _PapelBadge({required this.papel});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (papel.toLowerCase()) {
      case 'admin':
        color = AppTheme.error;
        break;
      case 'gerente':
        color = AppTheme.yellowWarning;
        break;
      case 'operador':
        color = AppTheme.accent;
        break;
      case 'vendedor':
        color = AppTheme.greenSuccess;
        break;
      default:
        color = AppTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        papel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// =============================================================================
// APARENCIA TAB
// =============================================================================

class _AparenciaTab extends StatefulWidget {
  const _AparenciaTab();

  @override
  State<_AparenciaTab> createState() => _AparenciaTabState();
}

class _AparenciaTabState extends State<_AparenciaTab> {
  static const _presetColors = <Color>[
    Color(0xFF1565c0), // Azul (default)
    Color(0xFF2e7d32), // Verde
    Color(0xFFc62828), // Vermelho
    Color(0xFF6a1b9a), // Roxo
    Color(0xFFe65100), // Laranja
    Color(0xFF00838f), // Teal
    Color(0xFF283593), // Indigo
    Color(0xFFad1457), // Rosa
  ];

  static const _colorLabels = [
    'Azul',
    'Verde',
    'Vermelho',
    'Roxo',
    'Laranja',
    'Teal',
    'Indigo',
    'Rosa',
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final configProvider = context.read<ConfiguracoesProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Modo do Tema ──
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo do Tema',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Alterne entre tema escuro e claro para a retaguarda',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _ThemeOptionCard(
                      label: 'Escuro',
                      icon: Icons.dark_mode,
                      isSelected: themeProvider.isDark,
                      onTap: () {
                        if (themeProvider.isDark) return;
                        themeProvider.toggleTheme(configProvider);
                      },
                    ),
                    SizedBox(width: 16),
                    _ThemeOptionCard(
                      label: 'Claro',
                      icon: Icons.light_mode,
                      isSelected: !themeProvider.isDark,
                      onTap: () {
                        if (!themeProvider.isDark) return;
                        themeProvider.toggleTheme(configProvider);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // ── Cor Primaria ──
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cor Primaria',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Escolha a cor principal dos botoes e destaques',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(_presetColors.length, (i) {
                    final color = _presetColors[i];
                    final isSelected =
                        themeProvider.primaryColor.value == color.value;
                    return Tooltip(
                      message: _colorLabels[i],
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd),
                        onTap: () => themeProvider.setPrimaryColor(
                            color, configProvider),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                          child: isSelected
                              ? Icon(Icons.check,
                                  color: Colors.white, size: 24)
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // ── Logo da Loja ──
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Logo da Loja',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Aparece como marca d\'agua no fundo do PDV',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    // Preview
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.inputFill,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: themeProvider.logoPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd),
                              child: Image.file(
                                File(themeProvider.logoPath!),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.broken_image,
                                  color: AppTheme.textMuted,
                                  size: 32,
                                ),
                              ),
                            )
                          : Icon(Icons.image_outlined,
                              color: AppTheme.textMuted, size: 32),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _selecionarLogo(context),
                          icon: Icon(Icons.upload, size: 18),
                          label: Text('Selecionar Logo'),
                        ),
                        if (themeProvider.logoPath != null) ...[
                          SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () =>
                                themeProvider.setLogoPath(null, configProvider),
                            icon: Icon(Icons.delete_outline,
                                size: 18, color: AppTheme.error),
                            label: Text('Remover',
                                style: TextStyle(color: AppTheme.error)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // ── Marca d'agua PDV ──
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marca d\'agua no PDV',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('Exibir marca d\'agua',
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14)),
                    SizedBox(width: 12),
                    Switch(
                      value: themeProvider.showWatermark,
                      onChanged: (v) =>
                          themeProvider.setShowWatermark(v, configProvider),
                    ),
                  ],
                ),
                if (themeProvider.showWatermark) ...[
                  SizedBox(height: 16),
                  Text('Opacidade: ${(themeProvider.watermarkOpacity * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  Slider(
                    value: themeProvider.watermarkOpacity,
                    min: 0.01,
                    max: 0.15,
                    divisions: 14,
                    label:
                        '${(themeProvider.watermarkOpacity * 100).toStringAsFixed(0)}%',
                    onChanged: (v) =>
                        setState(() => themeProvider.setWatermarkOpacity(
                            v, configProvider)),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _selecionarLogo(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      dialogTitle: 'Selecionar Logo',
    );

    if (result != null && result.files.single.path != null && mounted) {
      final path = result.files.single.path!;
      final configProvider = context.read<ConfiguracoesProvider>();
      context.read<ThemeProvider>().setLogoPath(path, configProvider);
    }
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.inputFill,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 28,
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.textSecondary),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Backup Tab
// ---------------------------------------------------------------------------

class _BackupTab extends StatefulWidget {
  const _BackupTab();

  @override
  State<_BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends State<_BackupTab> {
  /// Asks for admin credentials. Returns true if validated.
  Future<bool> _pedirAutorizacaoAdmin() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AdminBackupAuthDialog(),
    );
    return result == true;
  }

  Future<void> _gerarBackup() async {
    final autorizado = await _pedirAutorizacaoAdmin();
    if (!autorizado) return;

    if (!mounted) return;
    await context.read<BackupProvider>().fazerBackup();
  }

  Future<void> _restaurarBackup() async {
    final autorizado = await _pedirAutorizacaoAdmin();
    if (!autorizado) return;

    if (!mounted) return;

    // Confirmação extra para restauração
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppTheme.error, size: 24),
            SizedBox(width: 8),
            Text('Restaurar Backup',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ],
        ),
        content: Text(
          'ATENÇÃO: Restaurar um backup substituirá TODOS os dados atuais do sistema. '
          'Essa ação não pode ser desfeita.\n\n'
          'Tem certeza que deseja continuar?',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Sim, Restaurar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;
    await context.read<BackupProvider>().restaurarBackup();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BackupProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.backup_rounded,
                  color: AppTheme.primary, size: 28),
              SizedBox(width: 12),
              Text('Backup do Sistema',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Gere um arquivo de backup para salvar os dados do sistema ou restaure a partir de um backup existente.',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 24),

          // Success message
          if (provider.successMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.greenSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                    color: AppTheme.greenSuccess.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: AppTheme.greenSuccess, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(provider.successMessage!,
                        style: TextStyle(
                            color: AppTheme.greenSuccess, fontSize: 13)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        size: 18, color: AppTheme.greenSuccess),
                    onPressed: provider.limparMensagens,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          // Error message
          if (provider.error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border:
                    Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: AppTheme.error, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(provider.error!,
                        style: TextStyle(
                            color: AppTheme.error, fontSize: 13)),
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.close, size: 18, color: AppTheme.error),
                    onPressed: provider.limparMensagens,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          // Gerar Backup section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.download_rounded,
                        color: AppTheme.primary, size: 22),
                    SizedBox(width: 8),
                    Text('Gerar Backup',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Gera um arquivo .sql com todos os dados do banco de dados. '
                  'Você poderá escolher onde salvar o arquivo.',
                  style:
                      TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _gerarBackup,
                    icon: provider.isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.download_rounded, size: 20),
                    label: Text(
                        provider.isLoading ? 'Gerando...' : 'Gerar Backup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Restaurar Backup section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.restore_rounded,
                        color: AppTheme.error, size: 22),
                    SizedBox(width: 8),
                    Text('Restaurar Backup',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppTheme.error, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A restauração substituirá TODOS os dados atuais. '
                          'Faça um backup antes de restaurar.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.error,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Selecione um arquivo .sql gerado anteriormente para restaurar os dados do sistema.',
                  style:
                      TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: 220,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed:
                        provider.isLoading ? null : _restaurarBackup,
                    icon: provider.isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.upload_file_rounded, size: 20),
                    label: Text(provider.isLoading
                        ? 'Restaurando...'
                        : 'Restaurar Backup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin Auth Dialog for Backup
// ---------------------------------------------------------------------------

class _AdminBackupAuthDialog extends StatefulWidget {
  const _AdminBackupAuthDialog();

  @override
  State<_AdminBackupAuthDialog> createState() =>
      _AdminBackupAuthDialogState();
}

class _AdminBackupAuthDialogState extends State<_AdminBackupAuthDialog> {
  final _loginCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _validar() async {
    final login = _loginCtrl.text.trim();
    final senha = _senhaCtrl.text.trim();

    if (login.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Preencha login e senha');
      return;
    }

    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final api = context.read<ApiClient>();
      await api.post(ApiConfig.validarAdmin,
          body: {'login': login, 'senha': senha});
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = 'Login ou senha de administrador invalidos';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: AppTheme.yellowWarning, size: 22),
          SizedBox(width: 8),
          Text('Autorizacao do Administrador',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Para acessar o backup, informe as credenciais de um administrador.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _loginCtrl,
            autofocus: true,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Login do admin',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.primary, width: 2),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _senhaCtrl,
            obscureText: true,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Senha',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.primary, width: 2),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (_) => _validar(),
          ),
          if (_erro != null) ...[
            SizedBox(height: 12),
            Text(_erro!,
                style: TextStyle(color: AppTheme.error, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: Text('Cancelar',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _validar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text('Confirmar'),
        ),
      ],
    );
  }
}
