import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../providers/devolucoes_provider.dart';

class DevolucoesScreen extends StatefulWidget {
  DevolucoesScreen({super.key});
  @override
  State<DevolucoesScreen> createState() => _DevolucoesScreenState();
}

class _DevolucoesScreenState extends State<DevolucoesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DevolucoesProvider>().carregarDevolucoes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DevolucoesProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
              SizedBox(height: 20),
              _buildStatCards(provider),
              SizedBox(height: 20),
              _buildFilters(provider),
              SizedBox(height: 16),
              Expanded(child: _buildTable(provider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(DevolucoesProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trocas e Devoluções',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            SizedBox(height: 4),
            Text('Gerencie devoluções, trocas e créditos de clientes',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showNovaDevolucaoDialog(),
          icon: Icon(Icons.add, size: 18),
          label: Text('Nova Devolução'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(DevolucoesProvider provider) {
    final devolucoes = provider.devolucoes;
    final totalDevol = devolucoes.where((d) => d['tipo'] == 'devolucao').length;
    final totalTrocas = devolucoes.where((d) => d['tipo'] == 'troca').length;
    final valorTotal = devolucoes.fold<double>(
        0, (sum, d) => sum + ((d['valor_total'] as num?)?.toDouble() ?? 0));

    return Row(
      children: [
        _StatCard(
            label: 'Total',
            value: provider.total.toString(),
            icon: Icons.swap_horiz,
            color: AppTheme.accent),
        SizedBox(width: 12),
        _StatCard(
            label: 'Devoluções',
            value: totalDevol.toString(),
            icon: Icons.assignment_return,
            color: AppTheme.yellowWarning),
        SizedBox(width: 12),
        _StatCard(
            label: 'Trocas',
            value: totalTrocas.toString(),
            icon: Icons.swap_horizontal_circle,
            color: AppTheme.primary),
        SizedBox(width: 12),
        _StatCard(
            label: 'Valor Total',
            value: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                .format(valorTotal),
            icon: Icons.attach_money,
            color: AppTheme.error),
      ],
    );
  }

  Widget _buildFilters(DevolucoesProvider provider) {
    return Row(
      children: [
        _FilterChip(
            label: 'Todas',
            selected: provider.tipo == null && provider.status == null,
            onTap: () => provider.limparFiltros()),
        SizedBox(width: 8),
        _FilterChip(
            label: 'Devoluções',
            selected: provider.tipo == 'devolucao',
            onTap: () => provider.setTipo('devolucao')),
        SizedBox(width: 8),
        _FilterChip(
            label: 'Trocas',
            selected: provider.tipo == 'troca',
            onTap: () => provider.setTipo('troca')),
        SizedBox(width: 16),
        Container(width: 1, height: 24, color: AppTheme.border),
        SizedBox(width: 16),
        _FilterChip(
            label: 'Finalizadas',
            selected: provider.status == 'finalizada',
            onTap: () => provider.setStatus('finalizada')),
        SizedBox(width: 8),
        _FilterChip(
            label: 'Pendentes',
            selected: provider.status == 'pendente',
            onTap: () => provider.setStatus('pendente')),
      ],
    );
  }

  Widget _buildTable(DevolucoesProvider provider) {
    if (provider.isLoading) {
      return Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            SizedBox(height: 12),
            Text(provider.error!,
                style: TextStyle(color: AppTheme.textSecondary)),
            SizedBox(height: 12),
            ElevatedButton(
                onPressed: () => provider.carregarDevolucoes(),
                child: Text('Tentar Novamente')),
          ],
        ),
      );
    }
    if (provider.devolucoes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz,
                size: 64, color: AppTheme.textMuted.withValues(alpha: 0.3)),
            SizedBox(height: 16),
            Text('Nenhuma devolução registrada',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(AppTheme.scaffoldBackground),
            dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Venda')),
              DataColumn(label: Text('Tipo')),
              DataColumn(label: Text('Cliente')),
              DataColumn(label: Text('Motivo')),
              DataColumn(label: Text('Valor')),
              DataColumn(label: Text('Restituição')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Data')),
              DataColumn(label: Text('Ações')),
            ],
            rows: provider.devolucoes.map((d) {
              DateTime? data;
              try {
                data = DateTime.parse(d['data_devolucao'] ?? '');
              } catch (_) {}

              return DataRow(cells: [
                DataCell(Text('#${d['id']}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary))),
                DataCell(Text(d['venda_numero']?.toString() ?? '-',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.accent))),
                DataCell(_TipoBadge(tipo: d['tipo']?.toString() ?? '')),
                DataCell(Text(d['cliente_nome']?.toString() ?? '-',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textPrimary))),
                DataCell(
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 150),
                    child: Text(d['motivo']?.toString() ?? '-',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                  ),
                ),
                DataCell(Text(
                    currencyFormat
                        .format((d['valor_total'] as num?)?.toDouble() ?? 0),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary))),
                DataCell(_RestituicaoBadge(
                    forma: d['forma_restituicao']?.toString() ?? '')),
                DataCell(
                    _StatusBadge(status: d['status']?.toString() ?? '')),
                DataCell(Text(
                    data != null ? dateFormat.format(data) : '-',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textMuted))),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.visibility,
                          size: 18, color: AppTheme.accent),
                      tooltip: 'Ver detalhes',
                      onPressed: () => _showDetalhes(d['id'] as int),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showNovaDevolucaoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _NovaDevolucaoDialog(),
    );
  }

  void _showDetalhes(int id) async {
    final provider = context.read<DevolucoesProvider>();
    final devolucao = await provider.obterDevolucao(id);
    if (devolucao == null || !mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => _DetalhesDevolucaoDialog(devolucao: devolucao),
    );
  }
}

// ── Nova Devolução Dialog ──

class _NovaDevolucaoDialog extends StatefulWidget {
  const _NovaDevolucaoDialog();
  @override
  State<_NovaDevolucaoDialog> createState() => _NovaDevolucaoDialogState();
}

class _NovaDevolucaoDialogState extends State<_NovaDevolucaoDialog> {
  final _vendaController = TextEditingController();
  Map<String, dynamic>? _vendaData;
  bool _buscando = false;
  String? _erro;

  String _tipo = 'devolucao';
  String _motivo = '';
  String _formaRestituicao = 'credito';
  String _observacoes = '';

  // Itens selecionados: produtoId -> {selecionado, quantidade, motivo_item, estado_produto}
  final Map<int, Map<String, dynamic>> _itensSelecionados = {};

  bool _salvando = false;

  @override
  void dispose() {
    _vendaController.dispose();
    super.dispose();
  }

  Future<void> _buscarVenda() async {
    final numero = _vendaController.text.trim();
    if (numero.isEmpty) return;

    setState(() {
      _buscando = true;
      _erro = null;
      _vendaData = null;
      _itensSelecionados.clear();
    });

    final provider = context.read<DevolucoesProvider>();
    final venda = await provider.buscarVenda(numero);

    if (mounted) {
      setState(() {
        _buscando = false;
        if (venda != null) {
          _vendaData = venda;
        } else {
          _erro = provider.error ?? 'Venda nao encontrada';
        }
      });
    }
  }

  void _toggleItem(int produtoId, Map<String, dynamic> item) {
    setState(() {
      if (_itensSelecionados.containsKey(produtoId)) {
        _itensSelecionados.remove(produtoId);
      } else {
        final disponivel =
            (item['quantidade_disponivel'] as num?)?.toDouble() ?? 0;
        _itensSelecionados[produtoId] = {
          'quantidade': disponivel,
          'motivo_item': '',
          'estado_produto': 'novo',
        };
      }
    });
  }

  Future<void> _salvar() async {
    if (_vendaData == null) return;
    if (_itensSelecionados.isEmpty) {
      setState(() => _erro = 'Selecione pelo menos um item');
      return;
    }
    if (_motivo.isEmpty) {
      setState(() => _erro = 'Informe o motivo da devolucao');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final itens = _itensSelecionados.entries.map((e) {
      return {
        'produto_id': e.key,
        'quantidade': e.value['quantidade'],
        'motivo_item': e.value['motivo_item'],
        'estado_produto': e.value['estado_produto'],
        'retorna_estoque': true,
      };
    }).toList();

    final data = {
      'venda_id': _vendaData!['id'] is int
          ? _vendaData!['id']
          : int.parse(_vendaData!['id'].toString()),
      'tipo': _tipo,
      'motivo': _motivo,
      'forma_restituicao': _formaRestituicao,
      'observacoes': _observacoes.isNotEmpty ? _observacoes : null,
      'itens': itens,
    };

    final provider = context.read<DevolucoesProvider>();
    final result = await provider.criarDevolucao(data);

    if (mounted) {
      if (result != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Devolucao registrada com sucesso'),
              backgroundColor: AppTheme.greenSuccess),
        );
      } else {
        setState(() {
          _salvando = false;
          _erro = provider.error ?? 'Erro ao registrar devolucao';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: SizedBox(
        width: 700,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nova Devolução / Troca',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    IconButton(
                        icon: Icon(Icons.close,
                            color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                SizedBox(height: 16),

                // Buscar venda
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _vendaController,
                        style: TextStyle(
                            fontSize: 14, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Numero da venda...',
                          prefixIcon:
                              Icon(Icons.receipt_long, size: 20),
                          filled: true,
                          fillColor: AppTheme.inputFill,
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              borderSide:
                                  BorderSide(color: AppTheme.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              borderSide:
                                  BorderSide(color: AppTheme.border)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (_) => _buscarVenda(),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _buscando ? null : _buscarVenda,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      child: _buscando
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Buscar'),
                    ),
                  ],
                ),

                if (_erro != null) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: AppTheme.error),
                    ),
                    child: Text(_erro!,
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.error)),
                  ),
                ],

                // Dados da venda
                if (_vendaData != null) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBackground,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                'Venda #${_vendaData!['numero'] ?? ''}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                            Text(
                                'Total: ${currencyFormat.format(double.tryParse(_vendaData!['total']?.toString() ?? '0') ?? 0)}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accent)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                            'Cliente: ${_vendaData!['cliente_nome'] ?? 'Não identificado'}',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Tipo e Motivo
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _tipo,
                          decoration: InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          dropdownColor: AppTheme.cardSurface,
                          items: [
                            DropdownMenuItem(
                                value: 'devolucao',
                                child: Text('Devolução')),
                            DropdownMenuItem(
                                value: 'troca', child: Text('Troca')),
                          ],
                          onChanged: (v) =>
                              setState(() => _tipo = v ?? 'devolucao'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _formaRestituicao,
                          decoration: InputDecoration(
                            labelText: 'Restituição',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          dropdownColor: AppTheme.cardSurface,
                          items: [
                            DropdownMenuItem(
                                value: 'credito',
                                child: Text('Crédito')),
                            DropdownMenuItem(
                                value: 'dinheiro',
                                child: Text('Dinheiro')),
                            DropdownMenuItem(
                                value: 'troca', child: Text('Troca')),
                          ],
                          onChanged: (v) => setState(
                              () => _formaRestituicao = v ?? 'credito'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _motivo.isEmpty ? null : _motivo,
                    decoration: InputDecoration(
                      labelText: 'Motivo *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    dropdownColor: AppTheme.cardSurface,
                    items: [
                      DropdownMenuItem(
                          value: 'Defeito', child: Text('Defeito')),
                      DropdownMenuItem(
                          value: 'Arrependimento',
                          child: Text('Arrependimento')),
                      DropdownMenuItem(
                          value: 'Erro de operação',
                          child: Text('Erro de operação')),
                      DropdownMenuItem(
                          value: 'Tamanho errado',
                          child: Text('Tamanho errado')),
                      DropdownMenuItem(
                          value: 'Produto avariado',
                          child: Text('Produto avariado')),
                      DropdownMenuItem(
                          value: 'Outro', child: Text('Outro')),
                    ],
                    onChanged: (v) =>
                        setState(() => _motivo = v ?? ''),
                  ),
                  SizedBox(height: 12),

                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Observações',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textPrimary),
                    onChanged: (v) => _observacoes = v,
                  ),
                  SizedBox(height: 16),

                  // Itens da venda para selecionar
                  Text('Selecione os itens para devolver:',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  SizedBox(height: 8),

                  _buildItensTable(currencyFormat),
                  SizedBox(height: 16),

                  // Valor total da devolução
                  if (_itensSelecionados.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Valor da Devolução:',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                          Text(
                              currencyFormat
                                  .format(_calcularValorTotal()),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.accent)),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Botão salvar
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd)),
                      ),
                      child: _salvando
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : Text('Registrar Devolução',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItensTable(NumberFormat currencyFormat) {
    final itens = (_vendaData!['itens'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        children: itens.map((item) {
          final produtoId = int.tryParse(item['produto_id']?.toString() ?? '0') ?? 0;
          final descricao = item['produto_descricao']?.toString() ?? 'Produto';
          final qtdOriginal = double.tryParse(item['quantidade']?.toString() ?? '0') ?? 0;
          final qtdDisponivel = (item['quantidade_disponivel'] as num?)?.toDouble() ?? qtdOriginal;
          final precoUnit = double.tryParse(item['preco_unitario']?.toString() ?? '0') ?? 0;
          final selecionado = _itensSelecionados.containsKey(produtoId);
          final indisponivel = qtdDisponivel <= 0;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selecionado
                  ? AppTheme.primary.withValues(alpha: 0.05)
                  : null,
              border: Border(
                  bottom: BorderSide(color: AppTheme.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: selecionado,
                  onChanged: indisponivel
                      ? null
                      : (_) => _toggleItem(produtoId, item),
                  activeColor: AppTheme.primary,
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(descricao,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: indisponivel
                                  ? AppTheme.textMuted
                                  : AppTheme.textPrimary)),
                      Text(
                          'Qtd: ${qtdOriginal.toInt()} | Disp: ${qtdDisponivel.toInt()} | ${currencyFormat.format(precoUnit)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                if (selecionado) ...[
                  SizedBox(
                    width: 70,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Qtd',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 13),
                      controller: TextEditingController(
                          text: _itensSelecionados[produtoId]!['quantidade']
                              .toInt()
                              .toString()),
                      onChanged: (v) {
                        final qtd = double.tryParse(v) ?? 0;
                        if (qtd > 0 && qtd <= qtdDisponivel) {
                          _itensSelecionados[produtoId]!['quantidade'] = qtd;
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      value: _itensSelecionados[produtoId]!['estado_produto'],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        isDense: true,
                      ),
                      dropdownColor: AppTheme.cardSurface,
                      style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                      items: [
                        DropdownMenuItem(value: 'novo', child: Text('Novo')),
                        DropdownMenuItem(value: 'usado', child: Text('Usado')),
                        DropdownMenuItem(
                            value: 'defeito', child: Text('Defeito')),
                      ],
                      onChanged: (v) => setState(() {
                        _itensSelecionados[produtoId]!['estado_produto'] =
                            v ?? 'novo';
                      }),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  double _calcularValorTotal() {
    if (_vendaData == null) return 0;
    final itens = (_vendaData!['itens'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    double total = 0;

    for (final entry in _itensSelecionados.entries) {
      final item = itens.firstWhere(
        (i) => int.tryParse(i['produto_id']?.toString() ?? '0') == entry.key,
        orElse: () => {},
      );
      if (item.isEmpty) continue;
      final precoUnit =
          double.tryParse(item['preco_unitario']?.toString() ?? '0') ?? 0;
      total += entry.value['quantidade'] * precoUnit;
    }
    return total;
  }
}

// ── Detalhes Dialog ──

class _DetalhesDevolucaoDialog extends StatelessWidget {
  final Map<String, dynamic> devolucao;
  const _DetalhesDevolucaoDialog({required this.devolucao});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final itens = (devolucao['itens'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    DateTime? data;
    try {
      data = DateTime.parse(devolucao['data_devolucao'] ?? '');
    } catch (_) {}

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: SizedBox(
        width: 550,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Devolução #${devolucao['id']}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    IconButton(
                        icon: Icon(Icons.close,
                            color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                SizedBox(height: 16),

                // Info cards
                _InfoRow(
                    label: 'Venda',
                    value: '#${devolucao['venda_numero'] ?? devolucao['venda_id']}'),
                _InfoRow(
                    label: 'Tipo',
                    value: devolucao['tipo'] == 'troca'
                        ? 'Troca'
                        : 'Devolução'),
                _InfoRow(
                    label: 'Cliente',
                    value:
                        devolucao['cliente_nome']?.toString() ?? '-'),
                _InfoRow(
                    label: 'Operador',
                    value:
                        devolucao['usuario_nome']?.toString() ?? '-'),
                _InfoRow(
                    label: 'Motivo',
                    value: devolucao['motivo']?.toString() ?? '-'),
                _InfoRow(
                    label: 'Restituição',
                    value: _formaLabel(
                        devolucao['forma_restituicao']?.toString() ??
                            '')),
                _InfoRow(
                    label: 'Data',
                    value: data != null
                        ? dateFormat.format(data)
                        : '-'),
                _InfoRow(
                    label: 'Status',
                    value: devolucao['status']?.toString() ?? '-'),
                if (devolucao['observacoes'] != null &&
                    devolucao['observacoes'].toString().isNotEmpty)
                  _InfoRow(
                      label: 'Observações',
                      value: devolucao['observacoes'].toString()),

                SizedBox(height: 16),
                Divider(color: AppTheme.border),
                SizedBox(height: 8),

                Text('Itens Devolvidos',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                SizedBox(height: 8),

                ...itens.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBackground,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                    item['produto_descricao']
                                            ?.toString() ??
                                        'Produto #${item['produto_id']}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary)),
                                Text(
                                    'Qtd: ${(item['quantidade'] as num?)?.toInt() ?? 0} | Estado: ${item['estado_produto'] ?? 'novo'}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          Text(
                              currencyFormat.format(
                                  (item['subtotal'] as num?)
                                          ?.toDouble() ??
                                      0),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                        ],
                      ),
                    )),

                SizedBox(height: 8),
                Divider(color: AppTheme.border),
                SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    Text(
                        currencyFormat.format(
                            (devolucao['valor_total'] as num?)
                                    ?.toDouble() ??
                                0),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.accent)),
                  ],
                ),

                if ((devolucao['credito_gerado'] as num?)?.toDouble() != null &&
                    (devolucao['credito_gerado'] as num).toDouble() > 0) ...[
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Crédito gerado',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.greenSuccess)),
                      Text(
                          currencyFormat.format(
                              (devolucao['credito_gerado'] as num)
                                  .toDouble()),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.greenSuccess)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formaLabel(String forma) {
    switch (forma) {
      case 'dinheiro':
        return 'Dinheiro';
      case 'credito':
        return 'Crédito ao Cliente';
      case 'troca':
        return 'Troca por Produto';
      default:
        return forma;
    }
  }
}

// ── Widgets Auxiliares ──

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text(label,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
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

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected
                    ? AppTheme.accent
                    : AppTheme.textSecondary)),
      ),
    );
  }
}

class _TipoBadge extends StatelessWidget {
  final String tipo;
  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final isDevolucao = tipo == 'devolucao';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isDevolucao ? AppTheme.yellowWarning : AppTheme.primary)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isDevolucao ? 'Devolução' : 'Troca',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDevolucao ? AppTheme.yellowWarning : AppTheme.primary),
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
      case 'finalizada':
        color = AppTheme.greenSuccess;
        label = 'Finalizada';
        break;
      case 'pendente':
        color = AppTheme.yellowWarning;
        label = 'Pendente';
        break;
      case 'recusada':
        color = AppTheme.error;
        label = 'Recusada';
        break;
      default:
        color = AppTheme.textMuted;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _RestituicaoBadge extends StatelessWidget {
  final String forma;
  const _RestituicaoBadge({required this.forma});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;
    switch (forma) {
      case 'dinheiro':
        icon = Icons.payments;
        label = 'Dinheiro';
        break;
      case 'credito':
        icon = Icons.card_giftcard;
        label = 'Crédito';
        break;
      case 'troca':
        icon = Icons.swap_horiz;
        label = 'Troca';
        break;
      default:
        icon = Icons.help_outline;
        label = forma;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}
