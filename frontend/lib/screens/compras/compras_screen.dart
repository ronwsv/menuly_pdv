import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/compra.dart';
import '../../models/fornecedor.dart';
import '../../models/produto.dart';
import '../../providers/compras_provider.dart';
import '../../providers/fornecedores_provider.dart';
import '../../providers/produtos_provider.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';

class ComprasScreen extends StatefulWidget {
  ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    context.read<ComprasProvider>().carregarCompras();
  }

  void _abrirFormulario([Compra? compra]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
              value: context.read<ComprasProvider>()),
          ChangeNotifierProvider.value(
              value: context.read<FornecedoresProvider>()),
          ChangeNotifierProvider.value(
              value: context.read<ProdutosProvider>()),
          Provider.value(value: context.read<ApiClient>()),
        ],
        child: _CompraFormDialog(compra: compra),
      ),
    );
    if (result == true && mounted) {
      context.read<ComprasProvider>().carregarCompras();
    }
  }

  void _confirmarExclusao(Compra compra) async {
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
          'Deseja realmente excluir esta compra?\n'
          'O estoque sera revertido automaticamente.',
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
        await context.read<ComprasProvider>().excluirCompra(compra.id);
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
    return Consumer<ComprasProvider>(
      builder: (context, provider, _) {
        final compras = provider.compras;
        final totalCompras = provider.total;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                SizedBox(height: 20),
                _buildStatCards(compras, totalCompras),
                SizedBox(height: 20),
                Expanded(child: _buildBody(provider, compras)),
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
          'Compras',
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
          label: Text('Nova Compra'),
        ),
      ],
    );
  }

  Widget _buildStatCards(List<Compra> compras, int total) {
    final totalValor = compras.fold<double>(0, (s, c) => s + c.valorFinal);

    return Row(
      children: [
        _StatCard(
          label: 'Total Compras',
          value: total.toString(),
          icon: Icons.shopping_cart_outlined,
          color: AppTheme.accent,
        ),
        SizedBox(width: 16),
        _StatCard(
          label: 'Valor Total',
          value: _currencyFormat.format(totalValor),
          icon: Icons.attach_money,
          color: AppTheme.greenSuccess,
        ),
      ],
    );
  }

  Widget _buildBody(ComprasProvider provider, List<Compra> compras) {
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
              'Erro ao carregar compras',
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
              onPressed: () => provider.carregarCompras(),
              child: Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (compras.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text(
              'Nenhuma compra registrada',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(AppTheme.scaffoldBackground),
          dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
          border: TableBorder.all(color: AppTheme.border, width: 0.5),
          columnSpacing: 24,
          columns: [
            DataColumn(label: Text('Data')),
            DataColumn(label: Text('Fornecedor')),
            DataColumn(label: Text('Forma Pgto')),
            DataColumn(label: Text('Valor Bruto'), numeric: true),
            DataColumn(label: Text('Valor Final'), numeric: true),
            DataColumn(label: Text('Chave NF-e')),
            DataColumn(label: Text('Acoes')),
          ],
          rows: compras.map((c) => _buildRow(c)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(Compra compra) {
    String dataFormatada = compra.dataCompra;
    try {
      final dt = DateTime.parse(compra.dataCompra);
      dataFormatada = _dateFormat.format(dt);
    } catch (_) {}

    final pagamentoLabel = switch (compra.formaPagamento) {
      'dinheiro' => 'Dinheiro',
      'cartao' => 'Cartao',
      'pix' => 'PIX',
      'boleto' => 'Boleto',
      'transferencia' => 'Transferencia',
      null => '-',
      _ => compra.formaPagamento!,
    };

    final chaveResumo = compra.chaveNfe != null && compra.chaveNfe!.length > 10
        ? '${compra.chaveNfe!.substring(0, 10)}...'
        : compra.chaveNfe ?? '-';

    return DataRow(cells: [
      DataCell(Text(
        dataFormatada,
        style: TextStyle(color: AppTheme.textPrimary),
      )),
      DataCell(Text(
        compra.fornecedorNome ?? 'ID: ${compra.fornecedorId}',
        style: TextStyle(
            color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
      )),
      DataCell(Text(
        pagamentoLabel,
        style: TextStyle(color: AppTheme.textPrimary),
      )),
      DataCell(Text(
        _currencyFormat.format(compra.valorBruto),
        style: TextStyle(color: AppTheme.textSecondary),
      )),
      DataCell(Text(
        _currencyFormat.format(compra.valorFinal),
        style: TextStyle(
            color: AppTheme.greenSuccess, fontWeight: FontWeight.w600),
      )),
      DataCell(Tooltip(
        message: compra.chaveNfe ?? '',
        child: Text(
          chaveResumo,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      )),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.visibility_outlined, size: 18),
            color: AppTheme.accent,
            tooltip: 'Detalhes',
            onPressed: () => _abrirFormulario(compra),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18),
            color: AppTheme.error,
            tooltip: 'Excluir',
            onPressed: () => _confirmarExclusao(compra),
          ),
        ],
      )),
    ]);
  }
}

// -- Stat Card --

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
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
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

// -- Compra Form Dialog --

class _CompraFormDialog extends StatefulWidget {
  final Compra? compra;
  const _CompraFormDialog({this.compra});

  @override
  State<_CompraFormDialog> createState() => _CompraFormDialogState();
}

class _CompraFormDialogState extends State<_CompraFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  int? _fornecedorId;
  DateTime _dataCompra = DateTime.now();
  String? _formaPagamento;
  final _chaveNfeCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  final _valorFinalCtrl = TextEditingController();

  List<_ItemCompra> _itens = [];
  List<Fornecedor> _fornecedores = [];
  List<Produto> _produtos = [];
  bool _saving = false;
  bool _loadingDetalhes = false;

  bool get _isEditing => widget.compra != null;

  static const _formasPagamento = [
    'dinheiro',
    'cartao',
    'pix',
    'boleto',
    'transferencia',
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    // Carregar fornecedores e produtos
    final fornProv = context.read<FornecedoresProvider>();
    final prodProv = context.read<ProdutosProvider>();

    await Future.wait([
      fornProv.carregarFornecedores(),
      prodProv.carregarProdutos(),
    ]);

    if (!mounted) return;

    setState(() {
      _fornecedores = fornProv.fornecedores;
      _produtos = prodProv.produtos;
    });

    // Se editando, carregar detalhes
    if (_isEditing) {
      setState(() => _loadingDetalhes = true);
      try {
        final compraDetalhes =
            await context.read<ComprasProvider>().obterCompra(widget.compra!.id);
        if (mounted) {
          setState(() {
            _fornecedorId = compraDetalhes.fornecedorId;
            _dataCompra = DateTime.tryParse(compraDetalhes.dataCompra) ?? DateTime.now();
            _formaPagamento = compraDetalhes.formaPagamento;
            _chaveNfeCtrl.text = compraDetalhes.chaveNfe ?? '';
            _observacoesCtrl.text = compraDetalhes.observacoes ?? '';
            _valorFinalCtrl.text = compraDetalhes.valorFinal.toStringAsFixed(2);
            _itens = compraDetalhes.itens.map((i) {
              return _ItemCompra(
                produtoId: i.produtoId,
                descricao: i.produtoDescricao ?? 'Produto ${i.produtoId}',
                quantidade: i.quantidade,
                precoUnitario: i.precoUnitario,
              );
            }).toList();
            _loadingDetalhes = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loadingDetalhes = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _chaveNfeCtrl.dispose();
    _observacoesCtrl.dispose();
    _valorFinalCtrl.dispose();
    super.dispose();
  }

  double get _valorBruto =>
      _itens.fold<double>(0, (s, i) => s + i.total);

  void _adicionarItem() {
    setState(() {
      _itens.add(_ItemCompra(
        produtoId: 0,
        descricao: '',
        quantidade: 1,
        precoUnitario: 0,
      ));
    });
  }

  void _removerItem(int index) {
    setState(() => _itens.removeAt(index));
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataCompra,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.cardSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dataCompra = picked);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fornecedorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecione um fornecedor')),
      );
      return;
    }

    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adicione pelo menos um item')),
      );
      return;
    }

    // Validar itens
    for (var i = 0; i < _itens.length; i++) {
      if (_itens[i].produtoId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selecione o produto no item ${i + 1}')),
        );
        return;
      }
    }

    setState(() => _saving = true);

    final valorFinal =
        double.tryParse(_valorFinalCtrl.text.trim()) ?? _valorBruto;

    final data = <String, dynamic>{
      'fornecedor_id': _fornecedorId,
      'data_compra': _dataCompra.toIso8601String(),
      'valor_final': valorFinal,
      'forma_pagamento': _formaPagamento,
      'chave_nfe': _chaveNfeCtrl.text.trim().isEmpty
          ? null
          : _chaveNfeCtrl.text.trim(),
      'observacoes': _observacoesCtrl.text.trim().isEmpty
          ? null
          : _observacoesCtrl.text.trim(),
      'itens': _itens
          .map((i) => {
                'produto_id': i.produtoId,
                'quantidade': i.quantidade,
                'preco_unitario': i.precoUnitario,
              })
          .toList(),
    };

    try {
      final provider = context.read<ComprasProvider>();
      if (_isEditing) {
        await provider.atualizarCompra(widget.compra!.id, data);
      } else {
        await provider.criarCompra(data);
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
        width: 900,
        height: 680,
        child: _loadingDetalhes
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(
                        children: [
                          Text(
                            _isEditing ? 'Editar Compra' : 'Nova Compra',
                            style: TextStyle(
                              fontSize: 18,
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
                    SizedBox(height: 16),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top fields
                            _buildTopFields(),
                            SizedBox(height: 20),

                            // Items header
                            Row(
                              children: [
                                Text(
                                  'Itens da Compra',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Spacer(),
                                OutlinedButton.icon(
                                  onPressed: _adicionarItem,
                                  icon: Icon(Icons.add, size: 16),
                                  label: Text('Adicionar Item'),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),

                            // Items list
                            ..._itens.asMap().entries.map(
                                  (entry) =>
                                      _buildItemRow(entry.key, entry.value),
                                ),

                            if (_itens.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(20),
                                alignment: Alignment.center,
                                child: Text(
                                  'Nenhum item adicionado',
                                  style: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 14),
                                ),
                              ),

                            SizedBox(height: 16),

                            // Totals
                            _buildTotals(),
                            SizedBox(height: 16),

                            // Observacoes
                            TextFormField(
                              controller: _observacoesCtrl,
                              decoration: InputDecoration(
                                labelText: 'Observacoes',
                                alignLabelWithHint: true,
                              ),
                              style: TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 14),
                              maxLines: 2,
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
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
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTopFields() {
    final dateStr = DateFormat('dd/MM/yyyy').format(_dataCompra);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          child: Column(
            children: [
              // Fornecedor
              DropdownButtonFormField<int>(
                value: _fornecedorId,
                decoration:
                    InputDecoration(labelText: 'Fornecedor *'),
                dropdownColor: AppTheme.cardSurface,
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14),
                isExpanded: true,
                items: _fornecedores.map((f) {
                  return DropdownMenuItem(
                    value: f.id,
                    child: Text(
                      f.nomeFantasia?.isNotEmpty == true
                          ? f.nomeFantasia!
                          : f.razaoSocial,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _fornecedorId = v),
                validator: (v) =>
                    v == null ? 'Selecione um fornecedor' : null,
              ),
              SizedBox(height: 12),

              // Data
              GestureDetector(
                onTap: _selecionarData,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Data da Compra',
                    suffixIcon: Icon(Icons.calendar_today,
                        size: 18, color: AppTheme.textSecondary),
                  ),
                  child: Text(
                    dateStr,
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 20),

        // Right column
        Expanded(
          child: Column(
            children: [
              // Forma Pagamento
              DropdownButtonFormField<String>(
                value: _formaPagamento,
                decoration:
                    InputDecoration(labelText: 'Forma de Pagamento'),
                dropdownColor: AppTheme.cardSurface,
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14),
                items: [
                  const DropdownMenuItem<String>(
                      value: null, child: Text('Selecione')),
                  ..._formasPagamento.map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(f[0].toUpperCase() + f.substring(1)),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _formaPagamento = v),
              ),
              SizedBox(height: 12),

              // Chave NF-e
              TextFormField(
                controller: _chaveNfeCtrl,
                decoration:
                    InputDecoration(labelText: 'Chave NF-e (44 digitos)'),
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14),
                maxLength: 44,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(int index, _ItemCompra item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Produto dropdown
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<int>(
              value: item.produtoId == 0 ? null : item.produtoId,
              decoration: InputDecoration(
                labelText: 'Produto',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              dropdownColor: AppTheme.cardSurface,
              style:
                  TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              isExpanded: true,
              items: _produtos.map((p) {
                return DropdownMenuItem(
                  value: p.id,
                  child: Text(p.descricao, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  final prod = _produtos.firstWhere((p) => p.id == v);
                  setState(() {
                    item.produtoId = v;
                    item.descricao = prod.descricao;
                    item.precoUnitario = prod.precoCusto;
                  });
                }
              },
            ),
          ),
          SizedBox(width: 8),

          // Quantidade
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: item.quantidade.toString(),
              decoration: InputDecoration(
                labelText: 'Qtd',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style:
                  TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onChanged: (v) {
                setState(() {
                  item.quantidade = double.tryParse(v) ?? 0;
                });
              },
            ),
          ),
          SizedBox(width: 8),

          // Preco Unitario
          SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: item.precoUnitario.toStringAsFixed(2),
              decoration: InputDecoration(
                labelText: 'Preco Unit.',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style:
                  TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onChanged: (v) {
                setState(() {
                  item.precoUnitario = double.tryParse(v) ?? 0;
                });
              },
            ),
          ),
          SizedBox(width: 8),

          // Total
          SizedBox(
            width: 100,
            child: Text(
              _currencyFormat.format(item.total),
              style: TextStyle(
                color: AppTheme.greenSuccess,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 4),

          // Remove button
          IconButton(
            icon: Icon(Icons.close, size: 16, color: AppTheme.error),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () => _removerItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals() {
    final valorFinalStr = _valorFinalCtrl.text.trim();
    final valorFinal = double.tryParse(valorFinalStr) ?? _valorBruto;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Valor Bruto: ${_currencyFormat.format(_valorBruto)}',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 200,
            child: TextFormField(
              controller: _valorFinalCtrl,
              decoration: InputDecoration(
                labelText: 'Valor Final',
                prefixText: 'R\$ ',
              ),
              style:
                  TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for form items
class _ItemCompra {
  int produtoId;
  String descricao;
  double quantidade;
  double precoUnitario;

  _ItemCompra({
    required this.produtoId,
    required this.descricao,
    required this.quantidade,
    required this.precoUnitario,
  });

  double get total => quantidade * precoUnitario;
}
