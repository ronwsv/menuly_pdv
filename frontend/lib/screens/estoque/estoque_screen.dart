import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../providers/estoque_provider.dart';
import '../../providers/produtos_provider.dart';
import '../../models/produto.dart';

class EstoqueScreen extends StatefulWidget {
  EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentTab();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    _loadCurrentTab();
  }

  void _loadCurrentTab() {
    final provider = context.read<EstoqueProvider>();
    switch (_tabController.index) {
      case 0:
        provider.carregarPosicao();
        break;
      case 1:
        provider.carregarAbaixoMinimo();
        break;
      case 2:
        provider.carregarHistorico();
        break;
    }
  }

  void _refresh() => _loadCurrentTab();

  void _abrirMovimentacao() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
              value: context.read<EstoqueProvider>()),
          ChangeNotifierProvider.value(
              value: context.read<ProdutosProvider>()),
        ],
        child: const _MovimentoDialog(),
      ),
    );
    if (result == true && mounted) {
      _loadCurrentTab();
    }
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
            // Header
            Row(
              children: [
                Text(
                  'Estoque',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: _abrirMovimentacao,
                  icon: Icon(Icons.swap_vert, size: 18),
                  label: Text('Movimentar'),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: _refresh,
                  icon: Icon(Icons.refresh,
                      color: AppTheme.textSecondary),
                  tooltip: 'Atualizar',
                ),
              ],
            ),
            SizedBox(height: 16),

            // Tab bar
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
                labelStyle: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                dividerHeight: 0,
                tabs: [
                  Tab(text: 'Posicao'),
                  Tab(text: 'Abaixo Minimo'),
                  Tab(text: 'Historico'),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PosicaoTab(),
                  _AbaixoMinimoTab(),
                  _HistoricoTab(dateFormat: _dateFormat),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Posicao tab --

class _PosicaoTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EstoqueProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return _ErrorState(
            message: provider.error!,
            onRetry: () => provider.carregarPosicao(),
          );
        }
        if (provider.posicao.isEmpty) {
          return const _EmptyState(message: 'Nenhum produto em estoque');
        }

        return SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(AppTheme.scaffoldBackground),
              dataRowColor:
                  WidgetStateProperty.all(AppTheme.cardSurface),
              border: TableBorder.all(color: AppTheme.border, width: 0.5),
              columns: [
                DataColumn(label: Text('Produto')),
                DataColumn(
                    label: Text('Estoque Atual'), numeric: true),
                DataColumn(
                    label: Text('Estoque Minimo'), numeric: true),
                DataColumn(label: Text('Status')),
              ],
              rows: provider.posicao.map((item) {
                final atual = (item['estoque_atual'] ?? 0) as num;
                final minimo = (item['estoque_minimo'] ?? 0) as num;
                final isBaixo = minimo > 0 && atual < minimo;

                return DataRow(cells: [
                  DataCell(Text(
                    item['descricao']?.toString() ?? '',
                    style:
                        TextStyle(color: AppTheme.textPrimary),
                  )),
                  DataCell(Text(
                    atual.toString(),
                    style: TextStyle(
                      color: isBaixo
                          ? AppTheme.error
                          : AppTheme.textPrimary,
                      fontWeight: isBaixo ? FontWeight.w600 : null,
                    ),
                  )),
                  DataCell(Text(
                    minimo.toString(),
                    style:
                        TextStyle(color: AppTheme.textPrimary),
                  )),
                  DataCell(_StatusBadge(isLow: isBaixo)),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

// -- Abaixo Minimo tab --

class _AbaixoMinimoTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EstoqueProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return _ErrorState(
            message: provider.error!,
            onRetry: () => provider.carregarAbaixoMinimo(),
          );
        }
        if (provider.abaixoMinimo.isEmpty) {
          return const _EmptyState(
            message: 'Nenhum produto abaixo do estoque minimo',
            icon: Icons.check_circle_outline,
            iconColor: AppTheme.greenSuccess,
          );
        }

        return SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(AppTheme.scaffoldBackground),
              dataRowColor:
                  WidgetStateProperty.all(AppTheme.cardSurface),
              border: TableBorder.all(color: AppTheme.border, width: 0.5),
              columns: [
                DataColumn(label: Text('Produto')),
                DataColumn(
                    label: Text('Estoque Atual'), numeric: true),
                DataColumn(
                    label: Text('Estoque Minimo'), numeric: true),
                DataColumn(label: Text('Status')),
              ],
              rows: provider.abaixoMinimo.map((item) {
                final atual = (item['estoque_atual'] ?? 0) as num;
                final minimo = (item['estoque_minimo'] ?? 0) as num;

                return DataRow(cells: [
                  DataCell(Text(
                    item['descricao']?.toString() ?? '',
                    style:
                        TextStyle(color: AppTheme.textPrimary),
                  )),
                  DataCell(Text(
                    atual.toString(),
                    style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600),
                  )),
                  DataCell(Text(
                    minimo.toString(),
                    style:
                        TextStyle(color: AppTheme.textPrimary),
                  )),
                  DataCell(const _StatusBadge(isLow: true)),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

// -- Historico tab (com filtros) --

class _HistoricoTab extends StatefulWidget {
  final DateFormat dateFormat;
  const _HistoricoTab({required this.dateFormat});

  @override
  State<_HistoricoTab> createState() => _HistoricoTabState();
}

class _HistoricoTabState extends State<_HistoricoTab> {
  String? _tipoFiltro;
  String? _ocorrenciaFiltro;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  void _aplicarFiltros() {
    context.read<EstoqueProvider>().carregarHistorico(
          tipo: _tipoFiltro,
          ocorrencia: _ocorrenciaFiltro,
          dataInicio: _dataInicio?.toIso8601String(),
          dataFim: _dataFim != null
              ? _dataFim!
                  .add(Duration(days: 1))
                  .toIso8601String()
              : null,
        );
  }

  void _limparFiltros() {
    setState(() {
      _tipoFiltro = null;
      _ocorrenciaFiltro = null;
      _dataInicio = null;
      _dataFim = null;
    });
    context.read<EstoqueProvider>().carregarHistorico();
  }

  Future<void> _selecionarData(bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isInicio ? _dataInicio : _dataFim) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 1)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.cardSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = picked;
        } else {
          _dataFim = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EstoqueProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Filtros
            _buildFiltros(),
            SizedBox(height: 12),

            // Conteudo
            Expanded(child: _buildContent(provider)),
          ],
        );
      },
    );
  }

  Widget _buildFiltros() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          // Tipo
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String?>(
              value: _tipoFiltro,
              decoration: InputDecoration(
                labelText: 'Tipo',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              dropdownColor: AppTheme.cardSurface,
              style: TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13),
              items: [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(
                    value: 'entrada', child: Text('Entrada')),
                DropdownMenuItem(value: 'saida', child: Text('Saida')),
              ],
              onChanged: (v) => setState(() => _tipoFiltro = v),
            ),
          ),
          SizedBox(width: 10),

          // Ocorrencia
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String?>(
              value: _ocorrenciaFiltro,
              decoration: InputDecoration(
                labelText: 'Ocorrencia',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              dropdownColor: AppTheme.cardSurface,
              style: TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13),
              items: [
                DropdownMenuItem(value: null, child: Text('Todas')),
                DropdownMenuItem(value: 'venda', child: Text('Venda')),
                DropdownMenuItem(
                    value: 'compra', child: Text('Compra')),
                DropdownMenuItem(
                    value: 'ajuste', child: Text('Ajuste')),
                DropdownMenuItem(
                    value: 'devolucao', child: Text('Devolucao')),
                DropdownMenuItem(
                    value: 'cadastro', child: Text('Cadastro')),
                DropdownMenuItem(
                    value: 'consignacao', child: Text('Consignacao')),
              ],
              onChanged: (v) =>
                  setState(() => _ocorrenciaFiltro = v),
            ),
          ),
          SizedBox(width: 10),

          // Data inicio
          SizedBox(
            width: 140,
            child: GestureDetector(
              onTap: () => _selecionarData(true),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data Inicio',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  suffixIcon: Icon(Icons.calendar_today,
                      size: 14, color: AppTheme.textSecondary),
                ),
                child: Text(
                  _dataInicio != null
                      ? dateFormat.format(_dataInicio!)
                      : '',
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),

          // Data fim
          SizedBox(
            width: 140,
            child: GestureDetector(
              onTap: () => _selecionarData(false),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data Fim',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  suffixIcon: Icon(Icons.calendar_today,
                      size: 14, color: AppTheme.textSecondary),
                ),
                child: Text(
                  _dataFim != null
                      ? dateFormat.format(_dataFim!)
                      : '',
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),

          // Botoes
          ElevatedButton(
            onPressed: _aplicarFiltros,
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text('Filtrar', style: TextStyle(fontSize: 13)),
          ),
          SizedBox(width: 6),
          OutlinedButton(
            onPressed: _limparFiltros,
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: Text('Limpar', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(EstoqueProvider provider) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return _ErrorState(
        message: provider.error!,
        onRetry: () => provider.carregarHistorico(),
      );
    }
    if (provider.historico.isEmpty) {
      return const _EmptyState(
          message: 'Nenhum historico de movimentacao');
    }

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(AppTheme.scaffoldBackground),
          dataRowColor:
              WidgetStateProperty.all(AppTheme.cardSurface),
          border: TableBorder.all(color: AppTheme.border, width: 0.5),
          columns: [
            DataColumn(label: Text('Data')),
            DataColumn(label: Text('Produto')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Ocorrencia')),
            DataColumn(label: Text('Quantidade'), numeric: true),
            DataColumn(label: Text('Observacoes')),
          ],
          rows: provider.historico.map((item) {
            String formattedDate = '';
            final raw = item['criado_em']?.toString() ?? '';
            if (raw.isNotEmpty) {
              try {
                formattedDate =
                    widget.dateFormat.format(DateTime.parse(raw));
              } catch (_) {
                formattedDate = raw;
              }
            }

            final tipo = item['tipo']?.toString() ?? '';
            final isEntrada = tipo == 'entrada';

            return DataRow(cells: [
              DataCell(Text(
                formattedDate,
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13),
              )),
              DataCell(Text(
                item['produto_descricao']?.toString() ?? '',
                style:
                    TextStyle(color: AppTheme.textPrimary),
              )),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isEntrada
                          ? AppTheme.greenSuccess
                          : AppTheme.error)
                      .withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  isEntrada ? 'Entrada' : 'Saida',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isEntrada
                        ? AppTheme.greenSuccess
                        : AppTheme.error,
                  ),
                ),
              )),
              DataCell(Text(
                _formatOcorrencia(
                    item['ocorrencia']?.toString() ?? ''),
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              )),
              DataCell(Text(
                (item['quantidade'] ?? '').toString(),
                style:
                    TextStyle(color: AppTheme.textPrimary),
              )),
              DataCell(Text(
                item['observacoes']?.toString() ?? '',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  String _formatOcorrencia(String value) {
    return switch (value) {
      'venda' => 'Venda',
      'compra' => 'Compra',
      'ajuste' => 'Ajuste',
      'devolucao' => 'Devolucao',
      'cadastro' => 'Cadastro',
      'consignacao' => 'Consignacao',
      'cancelamento_venda' => 'Cancel. Venda',
      'exclusao_compra' => 'Excl. Compra',
      'ajuste_compra' => 'Ajuste Compra',
      'movimentacao_manual' => 'Manual',
      _ => value,
    };
  }
}

// -- Dialog de Movimentacao Manual --

class _MovimentoDialog extends StatefulWidget {
  const _MovimentoDialog();

  @override
  State<_MovimentoDialog> createState() => _MovimentoDialogState();
}

class _MovimentoDialogState extends State<_MovimentoDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _produtoId;
  String _tipo = 'entrada';
  String _ocorrencia = 'ajuste';
  final _quantidadeCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  List<Produto> _produtos = [];
  bool _saving = false;

  static const _ocorrencias = {
    'ajuste': 'Ajuste',
    'devolucao': 'Devolucao',
    'consignacao': 'Consignacao',
    'cadastro': 'Cadastro',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarProdutos();
    });
  }

  Future<void> _carregarProdutos() async {
    await context.read<ProdutosProvider>().carregarProdutos();
    if (mounted) {
      setState(() {
        _produtos = context.read<ProdutosProvider>().produtos;
      });
    }
  }

  @override
  void dispose() {
    _quantidadeCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_produtoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecione um produto')),
      );
      return;
    }

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'produto_id': _produtoId,
      'tipo': _tipo,
      'ocorrencia': _ocorrencia,
      'quantidade': double.tryParse(_quantidadeCtrl.text.trim()) ?? 0,
    };

    if (_observacoesCtrl.text.trim().isNotEmpty) {
      data['observacoes'] = _observacoesCtrl.text.trim();
    }

    try {
      await context.read<EstoqueProvider>().registrarMovimento(data);
      if (mounted) Navigator.of(context).pop(true);
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
    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: SizedBox(
        width: 500,
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
                    'Movimentar Estoque',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Tipo (Entrada / Saida)
                  Row(
                    children: [
                      Expanded(
                        child: _TipoButton(
                          label: 'Entrada',
                          icon: Icons.arrow_downward,
                          color: AppTheme.greenSuccess,
                          selected: _tipo == 'entrada',
                          onTap: () =>
                              setState(() => _tipo = 'entrada'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _TipoButton(
                          label: 'Saida',
                          icon: Icons.arrow_upward,
                          color: AppTheme.error,
                          selected: _tipo == 'saida',
                          onTap: () =>
                              setState(() => _tipo = 'saida'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Produto
                  DropdownButtonFormField<int>(
                    value: _produtoId,
                    decoration: InputDecoration(
                        labelText: 'Produto *'),
                    dropdownColor: AppTheme.cardSurface,
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    isExpanded: true,
                    items: _produtos.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(p.descricao,
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _produtoId = v),
                    validator: (v) =>
                        v == null ? 'Selecione um produto' : null,
                  ),
                  SizedBox(height: 12),

                  // Ocorrencia
                  DropdownButtonFormField<String>(
                    value: _ocorrencia,
                    decoration: InputDecoration(
                        labelText: 'Ocorrencia'),
                    dropdownColor: AppTheme.cardSurface,
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    items: _ocorrencias.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _ocorrencia = v);
                      }
                    },
                  ),
                  SizedBox(height: 12),

                  // Quantidade
                  TextFormField(
                    controller: _quantidadeCtrl,
                    decoration: InputDecoration(
                        labelText: 'Quantidade *'),
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d.]')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe a quantidade';
                      }
                      final num = double.tryParse(v.trim());
                      if (num == null || num <= 0) {
                        return 'Quantidade deve ser positiva';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),

                  // Observacoes
                  TextFormField(
                    controller: _observacoesCtrl,
                    decoration: InputDecoration(
                      labelText: 'Observacoes',
                      alignLabelWithHint: true,
                    ),
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    maxLines: 3,
                  ),
                  SizedBox(height: 24),

                  // Botoes
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
                            : Text('Registrar'),
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

class _TipoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TipoButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.15)
              : AppTheme.scaffoldBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected ? color : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? color : AppTheme.textSecondary),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Shared widgets --

class _StatusBadge extends StatelessWidget {
  final bool isLow;
  const _StatusBadge({required this.isLow});

  @override
  Widget build(BuildContext context) {
    final color = isLow ? AppTheme.error : AppTheme.greenSuccess;
    final text = isLow ? 'Baixo' : 'Normal';

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? iconColor;

  const _EmptyState({
    required this.message,
    this.icon = Icons.warehouse_outlined,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: iconColor ?? AppTheme.textSecondary),
          SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState(
      {required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: AppTheme.error),
          SizedBox(height: 12),
          Text(
            'Erro ao carregar dados',
            style: TextStyle(
                color: AppTheme.textPrimary, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
          SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
