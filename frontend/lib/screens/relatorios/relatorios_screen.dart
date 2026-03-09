import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendas_provider.dart';
import '../../providers/produtos_provider.dart';
import '../../providers/estoque_provider.dart';
import '../../providers/relatorios_provider.dart';
import '../../providers/configuracoes_provider.dart';
import '../../models/configuracao.dart';
import '../../widgets/charts/chart_card.dart';
import '../../widgets/charts/sales_line_chart.dart';
import '../../widgets/charts/payment_pie_chart.dart';
import '../../widgets/charts/ranking_bar_chart.dart';

class RelatoriosScreen extends StatefulWidget {
  RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  bool get _isAdmin => context.read<AuthProvider>().papelUsuario == 'admin';

  int _selectedSection = 0;
  String _periodoVendas = '30';
  int _produtoSubTab = 0;
  List<Map<String, dynamic>> _rankingGeral = [];
  List<Map<String, dynamic>> _rankingPorData = [];
  bool _loadingRanking = false;
  String _rankingPeriodo = '30';

  // Comissões state
  int? _comissaoVendedorId;
  String _comissaoPeriodo = '30';
  List<Usuario> _vendedores = [];

  static const _sections = ['Vendas', 'Produtos', 'Estoque', 'Comissoes'];
  static const _produtoSubTabs = [
    'Listagem Atual',
    'Listagem Detalhada',
    'Produtos em Falta',
    'Ranking Geral',
    'Ranking por Data',
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    _carregarSecaoAtual();
  }

  void _carregarSecaoAtual() {
    switch (_selectedSection) {
      case 0: // Vendas
        context.read<VendasProvider>().carregarVendas();
        _carregarGraficos();
        break;
      case 1: // Produtos
        context.read<ProdutosProvider>().carregarProdutos();
        _carregarRankings();
        break;
      case 2: // Estoque
        context.read<EstoqueProvider>().carregarAbaixoMinimo();
        context.read<EstoqueProvider>().carregarPosicao();
        break;
      case 3: // Comissões
        _carregarComissoes();
        _carregarVendedores();
        break;
    }
  }

  void _carregarGraficos() {
    final now = DateTime.now();
    int days;
    switch (_periodoVendas) {
      case '1':
        days = 1;
        break;
      case '7':
        days = 7;
        break;
      case '30':
        days = 30;
        break;
      default:
        days = 365;
    }
    final inicio = now.subtract(Duration(days: days));
    context.read<RelatoriosProvider>().carregarDadosGraficos(
      dataInicio: inicio.toIso8601String().split('T').first,
      dataFim: now.toIso8601String().split('T').first,
    );
  }

  void _carregarVendedores() async {
    try {
      final configProvider = context.read<ConfiguracoesProvider>();
      await configProvider.carregarUsuarios();
      if (mounted) {
        setState(() {
          _vendedores = configProvider.usuarios;
        });
      }
    } catch (_) {}
  }

  void _carregarComissoes() async {
    final now = DateTime.now();
    final days = int.tryParse(_comissaoPeriodo) ?? 30;
    final inicio = now.subtract(Duration(days: days));
    final dataInicio = inicio.toIso8601String().split('T').first;
    final dataFim = '${now.toIso8601String().split('T').first} 23:59:59';

    final provider = context.read<RelatoriosProvider>();
    // Load sequentially to avoid race condition on _isLoadingComissoes
    await provider.carregarComissoes(
      vendedorId: _comissaoVendedorId,
      dataInicio: _comissaoPeriodo == 'all' ? null : dataInicio,
      dataFim: _comissaoPeriodo == 'all' ? null : dataFim,
    );
    await provider.carregarResumoComissoes(
      vendedorId: _comissaoVendedorId,
      dataInicio: _comissaoPeriodo == 'all' ? null : dataInicio,
      dataFim: _comissaoPeriodo == 'all' ? null : dataFim,
    );
  }

  Future<void> _carregarRankings() async {
    setState(() => _loadingRanking = true);
    try {
      final provider = context.read<ProdutosProvider>();
      _rankingGeral = await provider.rankingGeral();

      final now = DateTime.now();
      final days = int.tryParse(_rankingPeriodo) ?? 30;
      final inicio = now.subtract(Duration(days: days));
      _rankingPorData = await provider.rankingPorData(
        dataInicio: inicio.toIso8601String().split('T').first,
        dataFim: now.toIso8601String().split('T').first,
      );
    } catch (_) {}
    if (mounted) setState(() => _loadingRanking = false);
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
            _buildHeader(),
            SizedBox(height: 20),

            // -- Section chips --
            _buildSectionChips(),
            SizedBox(height: 20),

            // -- Content --
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Relatorios',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Spacer(),
        IconButton(
          onPressed: _carregarDados,
          icon: Icon(Icons.refresh, color: AppTheme.textSecondary),
          tooltip: 'Atualizar',
        ),
      ],
    );
  }

  Widget _buildSectionChips() {
    return Row(
      children: List.generate(_sections.length, (index) {
        final selected = _selectedSection == index;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(_sections[index]),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedSection = index);
              _carregarSecaoAtual();
            },
            selectedColor: AppTheme.primary,
            backgroundColor: AppTheme.cardSurface,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            side: BorderSide(
              color: selected ? AppTheme.primary : AppTheme.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContent() {
    switch (_selectedSection) {
      case 0:
        return _buildVendasSection();
      case 1:
        return _buildProdutosSection();
      case 2:
        return _buildEstoqueSection();
      case 3:
        return _buildComissoesSection();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // VENDAS SECTION
  // ---------------------------------------------------------------------------

  Widget _buildVendasSection() {
    return Consumer<VendasProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _ErrorState(
            message: provider.error!,
            onRetry: () => provider.carregarVendas(),
          );
        }

        final vendas = provider.vendas;

        // Filter by period
        final now = DateTime.now();
        final filteredVendas = vendas.where((v) {
          if (v.criadoEm.isEmpty) return false;
          try {
            final date = DateTime.parse(v.criadoEm);
            switch (_periodoVendas) {
              case '1':
                return date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
              case '7':
                return now.difference(date).inDays <= 7;
              case '30':
                return now.difference(date).inDays <= 30;
              default:
                return true;
            }
          } catch (_) {
            return true;
          }
        }).toList();

        final totalVendas =
            filteredVendas.fold<double>(0, (s, v) => s + v.total);
        final qtdVendas = filteredVendas.length;
        final ticketMedio = qtdVendas > 0 ? totalVendas / qtdVendas : 0.0;
        final totalDescontos =
            filteredVendas.fold<double>(0, (s, v) => s + v.desconto);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period selector
              _buildPeriodSelector(),
              SizedBox(height: 16),

              // Summary cards
              Row(
                children: [
                  _StatCard(
                    label: 'Total Vendas',
                    value: _currencyFormat.format(totalVendas),
                    icon: Icons.attach_money,
                    color: AppTheme.greenSuccess,
                  ),
                  SizedBox(width: 16),
                  _StatCard(
                    label: 'Qtd Vendas',
                    value: qtdVendas.toString(),
                    icon: Icons.receipt_long_outlined,
                    color: AppTheme.accent,
                  ),
                  SizedBox(width: 16),
                  _StatCard(
                    label: 'Ticket Medio',
                    value: _currencyFormat.format(ticketMedio),
                    icon: Icons.trending_up,
                    color: AppTheme.yellowWarning,
                  ),
                  SizedBox(width: 16),
                  _StatCard(
                    label: 'Total Descontos',
                    value: _currencyFormat.format(totalDescontos),
                    icon: Icons.discount_outlined,
                    color: AppTheme.error,
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Charts
              Consumer<RelatoriosProvider>(
                builder: (context, relProv, _) {
                  if (relProv.isLoadingCharts) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  return Column(
                    children: [
                      // Faturamento diario (line chart)
                      ChartCard(
                        title: 'Faturamento Diario',
                        chart: SalesLineChart(
                          data: relProv.resumoDiario,
                          currencyFormat: _currencyFormat,
                        ),
                      ),
                      SizedBox(height: 16),
                      // Row with pie + bar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ChartCard(
                              title: 'Formas de Pagamento',
                              height: 200,
                              chart: PaymentPieChart(
                                data: relProv.porFormaPagamento,
                                currencyFormat: _currencyFormat,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ChartCard(
                              title: 'Receita por Categoria',
                              height: 200,
                              chart: RankingBarChart(
                                data: relProv.receitaPorCategoria,
                                labelKey: 'categoria',
                                valueKey: 'total',
                                currencyFormat: _currencyFormat,
                                barColor: AppTheme.greenSuccess,
                                maxItems: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 20),

              // Last sales table
              Text(
                'Ultimas Vendas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 12),

              if (filteredVendas.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Nenhuma venda no periodo selecionado',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(AppTheme.scaffoldBackground),
                    dataRowColor:
                        WidgetStateProperty.all(AppTheme.cardSurface),
                    border:
                        TableBorder.all(color: AppTheme.border, width: 0.5),
                    columns: [
                      DataColumn(label: Text('Numero')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Forma Pgto')),
                      DataColumn(label: Text('Total'), numeric: true),
                      DataColumn(label: Text('Data')),
                    ],
                    rows: filteredVendas.take(20).map((v) {
                      String formattedDate = '';
                      if (v.criadoEm.isNotEmpty) {
                        try {
                          formattedDate =
                              _dateFormat.format(DateTime.parse(v.criadoEm));
                        } catch (_) {
                          formattedDate = v.criadoEm;
                        }
                      }
                      return DataRow(cells: [
                        DataCell(Text(
                          v.numero,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                        DataCell(_VendaStatusBadge(status: v.status)),
                        DataCell(Text(
                          v.formaPagamento ?? '-',
                          style:
                              TextStyle(color: AppTheme.textPrimary),
                        )),
                        DataCell(Text(
                          _currencyFormat.format(v.total),
                          style: TextStyle(
                            color: AppTheme.greenSuccess,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                        DataCell(Text(
                          formattedDate,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    const periods = [
      ('1', 'Hoje'),
      ('7', '7 dias'),
      ('30', '30 dias'),
      ('all', 'Todos'),
    ];

    return Row(
      children: [
        Text(
          'Periodo:',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 12),
        ...periods.map((p) {
          final selected = _periodoVendas == p.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: () {
                setState(() => _periodoVendas = p.$1);
                _carregarGraficos();
              },
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    selected ? AppTheme.primary : Colors.transparent,
                foregroundColor:
                    selected ? Colors.white : AppTheme.textSecondary,
                side: BorderSide(
                  color: selected ? AppTheme.primary : AppTheme.border,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(p.$2),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PRODUTOS SECTION
  // ---------------------------------------------------------------------------

  Widget _buildProdutosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-tab chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_produtoSubTabs.length, (index) {
              final selected = _produtoSubTab == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_produtoSubTabs[index]),
                  selected: selected,
                  onSelected: (_) => setState(() => _produtoSubTab = index),
                  selectedColor: AppTheme.accent,
                  backgroundColor: AppTheme.cardSurface,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: selected ? AppTheme.accent : AppTheme.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: 16),
        Expanded(
          child: switch (_produtoSubTab) {
            0 => _buildListagemAtual(),
            1 => _buildListagemDetalhada(),
            2 => _buildProdutosEmFalta(),
            3 => _buildRankingGeral(),
            4 => _buildRankingPorData(),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }

  Widget _buildListagemAtual() {
    return Consumer<ProdutosProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        final produtos = provider.produtos.where((p) => p.ativo).toList();
        if (produtos.isEmpty) {
          return const _EmptyState(message: 'Nenhum produto ativo');
        }
        return SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.scaffoldBackground),
              dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
              border: TableBorder.all(color: AppTheme.border, width: 0.5),
              columns: [
                DataColumn(label: Text('Produto')),
                DataColumn(label: Text('Categoria')),
                DataColumn(label: Text('Preco Venda'), numeric: true),
                DataColumn(label: Text('Estoque'), numeric: true),
                DataColumn(label: Text('Unid.')),
              ],
              rows: produtos.map((p) => DataRow(cells: [
                DataCell(Text(p.descricao,
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
                DataCell(Text(p.categoriaNome ?? '-',
                    style: TextStyle(color: AppTheme.textSecondary))),
                DataCell(Text(_currencyFormat.format(p.precoVenda),
                    style: TextStyle(color: AppTheme.greenSuccess, fontWeight: FontWeight.w600))),
                DataCell(Text(p.estoqueAtual.toString(),
                    style: TextStyle(
                      color: p.estoqueBaixo ? AppTheme.error : AppTheme.textPrimary,
                      fontWeight: p.estoqueBaixo ? FontWeight.w700 : FontWeight.normal,
                    ))),
                DataCell(Text(p.unidade,
                    style: TextStyle(color: AppTheme.textMuted))),
              ])).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListagemDetalhada() {
    return Consumer<ProdutosProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        final produtos = provider.produtos;
        if (produtos.isEmpty) {
          return const _EmptyState(message: 'Nenhum produto encontrado');
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.scaffoldBackground),
              dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
              border: TableBorder.all(color: AppTheme.border, width: 0.5),
              columns: [
                DataColumn(label: Text('Produto')),
                DataColumn(label: Text('Cod. Barras')),
                DataColumn(label: Text('Categoria')),
                if (_isAdmin) DataColumn(label: Text('P. Custo'), numeric: true),
                DataColumn(label: Text('P. Venda'), numeric: true),
                if (_isAdmin) DataColumn(label: Text('Margem'), numeric: true),
                DataColumn(label: Text('Estoque'), numeric: true),
                DataColumn(label: Text('NCM')),
                DataColumn(label: Text('Fornecedor')),
                DataColumn(label: Text('Status')),
              ],
              rows: produtos.map((p) => DataRow(cells: [
                DataCell(Text(p.descricao,
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
                DataCell(Text(p.codigoBarras ?? '-',
                    style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Consolas', fontSize: 12))),
                DataCell(Text(p.categoriaNome ?? '-',
                    style: TextStyle(color: AppTheme.textSecondary))),
                if (_isAdmin) DataCell(Text(_currencyFormat.format(p.precoCusto),
                    style: TextStyle(color: AppTheme.textPrimary))),
                DataCell(Text(_currencyFormat.format(p.precoVenda),
                    style: TextStyle(color: AppTheme.greenSuccess, fontWeight: FontWeight.w600))),
                if (_isAdmin) DataCell(Text(
                    p.margemLucro > 0 ? '${p.margemLucro.toStringAsFixed(1)}%' : '-',
                    style: TextStyle(color: AppTheme.accent))),
                DataCell(Text(p.estoqueAtual.toString(),
                    style: TextStyle(
                      color: p.estoqueBaixo ? AppTheme.error : AppTheme.textPrimary,
                    ))),
                DataCell(Text(p.ncmCode ?? '-',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12))),
                DataCell(Text(p.fornecedorNome ?? '-',
                    style: TextStyle(color: AppTheme.textSecondary))),
                DataCell(Text(
                    p.ativo ? (p.bloqueado ? 'Bloqueado' : 'Ativo') : 'Inativo',
                    style: TextStyle(
                      color: p.ativo
                          ? (p.bloqueado ? AppTheme.yellowWarning : AppTheme.greenSuccess)
                          : AppTheme.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ))),
              ])).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProdutosEmFalta() {
    return Consumer<EstoqueProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        final abaixoMinimo = provider.abaixoMinimo;
        if (abaixoMinimo.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: AppTheme.greenSuccess),
                SizedBox(height: 12),
                Text('Nenhum produto abaixo do estoque minimo',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.scaffoldBackground),
              dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
              border: TableBorder.all(color: AppTheme.border, width: 0.5),
              columns: [
                DataColumn(label: Text('Produto')),
                DataColumn(label: Text('Estoque Atual'), numeric: true),
                DataColumn(label: Text('Estoque Minimo'), numeric: true),
                DataColumn(label: Text('Faltam'), numeric: true),
              ],
              rows: abaixoMinimo.map((item) {
                final atual = (item['estoque_atual'] ?? 0) as num;
                final minimo = (item['estoque_minimo'] ?? 0) as num;
                final faltam = minimo - atual;
                return DataRow(cells: [
                  DataCell(Text(item['descricao']?.toString() ?? '',
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
                  DataCell(Text(atual.toString(),
                      style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700))),
                  DataCell(Text(minimo.toString(),
                      style: TextStyle(color: AppTheme.textPrimary))),
                  DataCell(Text(faltam.toInt().toString(),
                      style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600))),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankingGeral() {
    if (_loadingRanking) {
      return Center(child: CircularProgressIndicator());
    }
    if (_rankingGeral.isEmpty) {
      return const _EmptyState(message: 'Nenhum dado de vendas encontrado');
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart - Top 10 produtos
          if (_isAdmin)
            ChartCard(
              title: 'Top Produtos por Faturamento',
              chart: RankingBarChart(
                data: _rankingGeral,
                labelKey: 'descricao',
                valueKey: 'total_faturamento',
                currencyFormat: _currencyFormat,
                barColor: AppTheme.accent,
                maxItems: 10,
              ),
            )
          else
            ChartCard(
              title: 'Top Produtos por Quantidade',
              chart: RankingBarChart(
                data: _rankingGeral,
                labelKey: 'descricao',
                valueKey: 'total_quantidade',
                maxItems: 10,
              ),
            ),
          SizedBox(height: 16),
          // Table
          SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.scaffoldBackground),
          dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
          border: TableBorder.all(color: AppTheme.border, width: 0.5),
          columns: [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Produto')),
            DataColumn(label: Text('Qtd Vendida'), numeric: true),
            if (_isAdmin) DataColumn(label: Text('Faturamento'), numeric: true),
          ],
          rows: List.generate(_rankingGeral.length, (i) {
            final item = _rankingGeral[i];
            return DataRow(cells: [
              DataCell(Text('${i + 1}',
                  style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600))),
              DataCell(Text(item['descricao']?.toString() ?? '',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
              DataCell(Text(item['total_quantidade']?.toString() ?? '0',
                  style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600))),
              if (_isAdmin) DataCell(Text(
                  _currencyFormat.format((item['total_faturamento'] ?? 0).toDouble()),
                  style: TextStyle(color: AppTheme.greenSuccess, fontWeight: FontWeight.w600))),
            ]);
          }),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildRankingPorData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period selector
        Row(
          children: [
            Text('Periodo:', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            SizedBox(width: 12),
            ...[('7', '7 dias'), ('30', '30 dias'), ('90', '90 dias')].map((p) {
              final selected = _rankingPeriodo == p.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _rankingPeriodo = p.$1);
                    _carregarRankings();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected ? AppTheme.primary : Colors.transparent,
                    foregroundColor: selected ? Colors.white : AppTheme.textSecondary,
                    side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(p.$2),
                ),
              );
            }),
          ],
        ),
        SizedBox(height: 16),
        Expanded(
          child: _loadingRanking
              ? Center(child: CircularProgressIndicator())
              : _rankingPorData.isEmpty
                  ? const _EmptyState(message: 'Nenhuma venda no periodo selecionado')
                  : SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppTheme.scaffoldBackground),
                          dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
                          border: TableBorder.all(color: AppTheme.border, width: 0.5),
                          columns: [
                            DataColumn(label: Text('#')),
                            DataColumn(label: Text('Produto')),
                            DataColumn(label: Text('Qtd Vendida'), numeric: true),
                            if (_isAdmin) DataColumn(label: Text('Faturamento'), numeric: true),
                          ],
                          rows: List.generate(_rankingPorData.length, (i) {
                            final item = _rankingPorData[i];
                            return DataRow(cells: [
                              DataCell(Text('${i + 1}',
                                  style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600))),
                              DataCell(Text(item['descricao']?.toString() ?? '',
                                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
                              DataCell(Text(item['total_quantidade']?.toString() ?? '0',
                                  style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600))),
                              if (_isAdmin) DataCell(Text(
                                  _currencyFormat.format((item['total_faturamento'] ?? 0).toDouble()),
                                  style: TextStyle(color: AppTheme.greenSuccess, fontWeight: FontWeight.w600))),
                            ]);
                          }),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // COMISSOES SECTION
  // ---------------------------------------------------------------------------

  Widget _buildComissoesSection() {
    return Consumer<RelatoriosProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingComissoes) {
          return Center(child: CircularProgressIndicator());
        }

        final resumo = provider.resumoComissoes;
        final comissoes = provider.comissoes;

        // Totals from resumo
        double totalComissao = 0;
        double totalVendido = 0;
        int totalVendas = 0;
        for (final r in resumo) {
          totalComissao += _parseDouble(r['total_comissao']);
          totalVendido += _parseDouble(r['total_vendido']);
          totalVendas += (_parseInt(r['total_vendas']));
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters
              Row(
                children: [
                  // Vendedor dropdown
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<int?>(
                      value: _comissaoVendedorId,
                      decoration: InputDecoration(
                        labelText: 'Vendedor',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      dropdownColor: AppTheme.cardSurface,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      items: [
                        DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                        ..._vendedores.map((u) => DropdownMenuItem<int?>(
                          value: u.id,
                          child: Text(u.nome),
                        )),
                      ],
                      onChanged: (v) {
                        setState(() => _comissaoVendedorId = v);
                        _carregarComissoes();
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  // Period
                  Text('Periodo:', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  SizedBox(width: 8),
                  ...[('7', '7 dias'), ('30', '30 dias'), ('90', '90 dias'), ('all', 'Todos')].map((p) {
                    final selected = _comissaoPeriodo == p.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _comissaoPeriodo = p.$1);
                          _carregarComissoes();
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected ? AppTheme.primary : Colors.transparent,
                          foregroundColor: selected ? Colors.white : AppTheme.textSecondary,
                          side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(p.$2),
                      ),
                    );
                  }),
                ],
              ),
              SizedBox(height: 16),

              // Summary cards
              Row(
                children: [
                  _StatCard(
                    label: 'Total Comissoes',
                    value: _currencyFormat.format(totalComissao),
                    icon: Icons.payments_outlined,
                    color: AppTheme.accent,
                  ),
                  SizedBox(width: 16),
                  _StatCard(
                    label: 'Total Vendido',
                    value: _currencyFormat.format(totalVendido),
                    icon: Icons.attach_money,
                    color: AppTheme.greenSuccess,
                  ),
                  SizedBox(width: 16),
                  _StatCard(
                    label: 'Vendas com Comissao',
                    value: totalVendas.toString(),
                    icon: Icons.receipt_long_outlined,
                    color: AppTheme.yellowWarning,
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Chart - Comissao por vendedor
              if (resumo.isNotEmpty) ...[
                ChartCard(
                  title: 'Comissao por Vendedor',
                  height: 200,
                  chart: RankingBarChart(
                    data: resumo,
                    labelKey: 'vendedor_nome',
                    valueKey: 'total_comissao',
                    currencyFormat: _currencyFormat,
                    barColor: AppTheme.accent,
                    maxItems: 8,
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Resumo por vendedor
              if (resumo.isNotEmpty) ...[
                Text(
                  'Resumo por Vendedor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.scaffoldBackground),
                    dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
                    border: TableBorder.all(color: AppTheme.border, width: 0.5),
                    columns: [
                      DataColumn(label: Text('Vendedor')),
                      DataColumn(label: Text('Vendas'), numeric: true),
                      DataColumn(label: Text('Total Vendido'), numeric: true),
                      DataColumn(label: Text('% Medio'), numeric: true),
                      DataColumn(label: Text('Comissao'), numeric: true),
                    ],
                    rows: resumo.map((r) {
                      return DataRow(cells: [
                        DataCell(Text(
                          r['vendedor_nome']?.toString() ?? '',
                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                        )),
                        DataCell(Text(
                          r['total_vendas']?.toString() ?? '0',
                          style: TextStyle(color: AppTheme.textPrimary),
                        )),
                        DataCell(Text(
                          _currencyFormat.format(_parseDouble(r['total_vendido'])),
                          style: TextStyle(color: AppTheme.greenSuccess),
                        )),
                        DataCell(Text(
                          '${_parseDouble(r['percentual_medio']).toStringAsFixed(1)}%',
                          style: TextStyle(color: AppTheme.textSecondary),
                        )),
                        DataCell(Text(
                          _currencyFormat.format(_parseDouble(r['total_comissao'])),
                          style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Detalhamento
              Text(
                'Detalhamento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 12),

              if (comissoes.isEmpty)
                const _EmptyState(message: 'Nenhuma comissao no periodo selecionado')
              else
                SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.scaffoldBackground),
                    dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
                    border: TableBorder.all(color: AppTheme.border, width: 0.5),
                    columns: [
                      DataColumn(label: Text('Venda')),
                      DataColumn(label: Text('Vendedor')),
                      DataColumn(label: Text('Valor Venda'), numeric: true),
                      DataColumn(label: Text('%'), numeric: true),
                      DataColumn(label: Text('Comissao'), numeric: true),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Data')),
                    ],
                    rows: comissoes.map((c) {
                      String formattedDate = '';
                      final criadoEm = c['criado_em']?.toString() ?? '';
                      if (criadoEm.isNotEmpty) {
                        try {
                          formattedDate = _dateFormat.format(DateTime.parse(criadoEm));
                        } catch (_) {
                          formattedDate = criadoEm;
                        }
                      }
                      final status = c['status']?.toString() ?? 'ativa';
                      final isAtiva = status == 'ativa';

                      return DataRow(cells: [
                        DataCell(Text(
                          '#${c['venda_numero'] ?? c['venda_id']}',
                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                        )),
                        DataCell(Text(
                          c['vendedor_nome']?.toString() ?? '',
                          style: TextStyle(color: AppTheme.textPrimary),
                        )),
                        DataCell(Text(
                          _currencyFormat.format(_parseDouble(c['valor_venda'])),
                          style: TextStyle(color: AppTheme.textPrimary),
                        )),
                        DataCell(Text(
                          '${_parseDouble(c['percentual']).toStringAsFixed(1)}%',
                          style: TextStyle(color: AppTheme.textSecondary),
                        )),
                        DataCell(Text(
                          _currencyFormat.format(_parseDouble(c['valor_comissao'])),
                          style: TextStyle(
                            color: isAtiva ? AppTheme.accent : AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                            decoration: isAtiva ? null : TextDecoration.lineThrough,
                          ),
                        )),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAtiva
                                ? AppTheme.greenSuccess.withOpacity(0.15)
                                : AppTheme.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isAtiva ? AppTheme.greenSuccess : AppTheme.error,
                            ),
                          ),
                        )),
                        DataCell(Text(
                          formattedDate,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstoqueChart(List<Map<String, dynamic>> abaixoMinimo) {
    // Build data for a grouped bar chart showing atual vs minimo
    final items = abaixoMinimo.take(8).toList();
    final chartData = items.map((item) => <String, dynamic>{
      'descricao': item['descricao']?.toString() ?? '',
      'estoque_atual': ((item['estoque_atual'] ?? 0) as num).toDouble(),
    }).toList();

    return RankingBarChart(
      data: chartData,
      labelKey: 'descricao',
      valueKey: 'estoque_atual',
      barColor: AppTheme.error,
      maxItems: 8,
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // ESTOQUE SECTION
  // ---------------------------------------------------------------------------

  Widget _buildEstoqueSection() {
    return Consumer<EstoqueProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _ErrorState(
            message: provider.error!,
            onRetry: () {
              provider.carregarAbaixoMinimo();
              provider.carregarPosicao();
            },
          );
        }

        final posicao = provider.posicao;
        final abaixoMinimo = provider.abaixoMinimo;

        // Total items in stock
        int totalItens = 0;
        double totalValor = 0;
        for (final item in posicao) {
          final qtd = (item['estoque_atual'] ?? 0) as num;
          final preco = (item['preco_venda'] ?? 0) as num;
          totalItens += qtd.toInt();
          totalValor += qtd.toDouble() * preco.toDouble();
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Row(
                children: [
                  _StatCard(
                    label: 'Total Itens em Estoque',
                    value: totalItens.toString(),
                    icon: Icons.inventory_2_outlined,
                    color: AppTheme.accent,
                  ),
                  SizedBox(width: 16),
                  _StatCard(
                    label: 'Valor Estimado',
                    value: _currencyFormat.format(totalValor),
                    icon: Icons.attach_money,
                    color: AppTheme.greenSuccess,
                  ),
                  SizedBox(width: 16),
                  _StatCard(
                    label: 'Abaixo do Minimo',
                    value: abaixoMinimo.length.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.error,
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Chart - Estoque critico
              if (abaixoMinimo.isNotEmpty) ...[
                ChartCard(
                  title: 'Estoque Critico (Atual vs Minimo)',
                  height: 200,
                  chart: _buildEstoqueChart(abaixoMinimo),
                ),
                SizedBox(height: 20),
              ],

              // Below minimum stock table
              Text(
                'Produtos Abaixo do Estoque Minimo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 12),

              if (abaixoMinimo.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48, color: AppTheme.greenSuccess),
                      SizedBox(height: 12),
                      Text(
                        'Nenhum produto abaixo do estoque minimo',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(AppTheme.scaffoldBackground),
                    dataRowColor:
                        WidgetStateProperty.all(AppTheme.cardSurface),
                    border:
                        TableBorder.all(color: AppTheme.border, width: 0.5),
                    columns: [
                      DataColumn(label: Text('Produto')),
                      DataColumn(
                          label: Text('Estoque Atual'), numeric: true),
                      DataColumn(
                          label: Text('Estoque Minimo'), numeric: true),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: abaixoMinimo.map((item) {
                      final atual = (item['estoque_atual'] ?? 0) as num;
                      final minimo = (item['estoque_minimo'] ?? 0) as num;

                      return DataRow(cells: [
                        DataCell(Text(
                          item['descricao']?.toString() ?? '',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                        DataCell(Text(
                          atual.toString(),
                          style: TextStyle(color: AppTheme.error),
                        )),
                        DataCell(Text(
                          minimo.toString(),
                          style:
                              TextStyle(color: AppTheme.textPrimary),
                        )),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Text(
                            'Baixo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.error,
                            ),
                          ),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// -- Venda Status Badge --

class _VendaStatusBadge extends StatelessWidget {
  final String status;
  const _VendaStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'finalizada':
        bgColor = AppTheme.greenSuccess.withOpacity(0.15);
        textColor = AppTheme.greenSuccess;
        break;
      case 'cancelada':
        bgColor = AppTheme.error.withOpacity(0.15);
        textColor = AppTheme.error;
        break;
      case 'orcamento':
        bgColor = AppTheme.yellowWarning.withOpacity(0.15);
        textColor = AppTheme.yellowWarning;
        break;
      default:
        bgColor = AppTheme.textMuted.withOpacity(0.15);
        textColor = AppTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// -- Empty State --

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      ),
    );
  }
}

// -- Error State --

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          SizedBox(height: 12),
          Text(
            'Erro ao carregar dados',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
