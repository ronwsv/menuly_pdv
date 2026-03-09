import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../config/api_config.dart';
import '../../models/consignacao.dart';
import '../../providers/consignacoes_provider.dart';
import '../../services/api_client.dart';

class ConsignacoesScreen extends StatefulWidget {
  const ConsignacoesScreen({super.key});
  @override
  State<ConsignacoesScreen> createState() => _ConsignacoesScreenState();
}

class _ConsignacoesScreenState extends State<ConsignacoesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsignacoesProvider>().carregarConsignacoes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsignacoesProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
              const SizedBox(height: 20),
              _buildStatCards(provider),
              const SizedBox(height: 20),
              _buildFilters(provider),
              const SizedBox(height: 16),
              Expanded(child: _buildTable(provider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ConsignacoesProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consignações',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text('Gerencie consignações de saída e entrada',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showNovaConsignacaoDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nova Consignação'),
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

  Widget _buildStatCards(ConsignacoesProvider provider) {
    final list = provider.consignacoes;
    final abertas = list.where((c) => c.status == 'aberta' || c.status == 'parcial').length;
    final saidas = list.where((c) => c.tipo == 'saida').length;
    final entradas = list.where((c) => c.tipo == 'entrada').length;

    return Row(
      children: [
        _StatCard(
            label: 'Total', value: provider.total.toString(),
            icon: Icons.swap_vert, color: AppTheme.accent),
        const SizedBox(width: 12),
        _StatCard(
            label: 'Abertas/Parciais', value: abertas.toString(),
            icon: Icons.pending_actions, color: AppTheme.yellowWarning),
        const SizedBox(width: 12),
        _StatCard(
            label: 'Saídas', value: saidas.toString(),
            icon: Icons.arrow_upward, color: AppTheme.error),
        const SizedBox(width: 12),
        _StatCard(
            label: 'Entradas', value: entradas.toString(),
            icon: Icons.arrow_downward, color: AppTheme.greenSuccess),
      ],
    );
  }

  Widget _buildFilters(ConsignacoesProvider provider) {
    return Row(
      children: [
        _FilterChip(
            label: 'Todas', selected: provider.tipo == null,
            onTap: () => provider.setTipo(null)),
        const SizedBox(width: 8),
        _FilterChip(
            label: 'Saída', selected: provider.tipo == 'saida',
            onTap: () => provider.setTipo('saida')),
        const SizedBox(width: 8),
        _FilterChip(
            label: 'Entrada', selected: provider.tipo == 'entrada',
            onTap: () => provider.setTipo('entrada')),
        const SizedBox(width: 16),
        Container(width: 1, height: 24, color: AppTheme.border),
        const SizedBox(width: 16),
        _FilterChip(
            label: 'Abertas', selected: provider.status == 'aberta',
            onTap: () => provider.setStatus('aberta')),
        const SizedBox(width: 8),
        _FilterChip(
            label: 'Parciais', selected: provider.status == 'parcial',
            onTap: () => provider.setStatus('parcial')),
        const SizedBox(width: 8),
        _FilterChip(
            label: 'Fechadas', selected: provider.status == 'fechada',
            onTap: () => provider.setStatus('fechada')),
        const SizedBox(width: 8),
        if (provider.tipo != null || provider.status != null)
          TextButton.icon(
            onPressed: () => provider.limparFiltros(),
            icon: Icon(Icons.clear, size: 16, color: AppTheme.textMuted),
            label: Text('Limpar',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ),
      ],
    );
  }

  Widget _buildTable(ConsignacoesProvider provider) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 12),
            Text(provider.error!,
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () => provider.carregarConsignacoes(),
                child: const Text('Tentar Novamente')),
          ],
        ),
      );
    }
    if (provider.consignacoes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_vert,
                size: 64, color: AppTheme.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Nenhuma consignação registrada',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final totalPages = (provider.total / 50).ceil();

    return Column(
      children: [
        Expanded(
          child: Container(
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
                  columns: const [
                    DataColumn(label: Text('Número')),
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Parceiro')),
                    DataColumn(label: Text('Itens')),
                    DataColumn(label: Text('Valor Total')),
                    DataColumn(label: Text('Acertado')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Data')),
                    DataColumn(label: Text('Ações')),
                  ],
                  rows: provider.consignacoes.map((c) {
                    return DataRow(cells: [
                      DataCell(Text(c.numero,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accent))),
                      DataCell(_TipoBadge(tipo: c.tipo)),
                      DataCell(Text(c.parceiro,
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textPrimary))),
                      DataCell(Text(c.totalItens.toString(),
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary))),
                      DataCell(Text(currencyFormat.format(c.valorTotal),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary))),
                      DataCell(Text(currencyFormat.format(c.valorAcertado),
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.greenSuccess))),
                      DataCell(_StatusBadge(status: c.status)),
                      DataCell(Text(
                          c.criadoEm != null
                              ? dateFormat.format(c.criadoEm!)
                              : '-',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textMuted))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.visibility,
                                size: 18, color: AppTheme.accent),
                            tooltip: 'Ver detalhes',
                            onPressed: () => _showDetalhes(c.id),
                          ),
                          if (c.status == 'aberta' || c.status == 'parcial')
                            IconButton(
                              icon: Icon(Icons.check_circle_outline,
                                  size: 18, color: AppTheme.greenSuccess),
                              tooltip: 'Registrar acerto',
                              onPressed: () => _showAcertoDialog(c.id),
                            ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: provider.page > 1
                    ? () => provider.setPage(provider.page - 1)
                    : null,
              ),
              Text(
                'Página ${provider.page} de $totalPages (${provider.total} registros)',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: provider.page < totalPages
                    ? () => provider.setPage(provider.page + 1)
                    : null,
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showNovaConsignacaoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _NovaConsignacaoDialog(),
    );
  }

  void _showDetalhes(int id) async {
    final provider = context.read<ConsignacoesProvider>();
    final consignacao = await provider.obterConsignacao(id);
    if (consignacao == null || !mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => _DetalhesDialog(consignacao: consignacao),
    );
  }

  void _showAcertoDialog(int id) async {
    final provider = context.read<ConsignacoesProvider>();
    final consignacao = await provider.obterConsignacao(id);
    if (consignacao == null || !mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => _AcertoDialog(consignacao: consignacao),
    );
  }
}

// ── Nova Consignação Dialog ──

class _NovaConsignacaoDialog extends StatefulWidget {
  const _NovaConsignacaoDialog();
  @override
  State<_NovaConsignacaoDialog> createState() => _NovaConsignacaoDialogState();
}

class _NovaConsignacaoDialogState extends State<_NovaConsignacaoDialog> {
  String _tipo = 'saida';
  Map<String, dynamic>? _parceiroSelecionado;
  final _parceiroCtrl = TextEditingController();
  List<Map<String, dynamic>> _parceirosResultado = [];
  bool _buscandoParceiro = false;

  final _obsCtrl = TextEditingController();
  final List<_ItemConsignacao> _itens = [];
  bool _salvando = false;

  // Product search
  final _prodBuscaCtrl = TextEditingController();
  List<Map<String, dynamic>> _prodResultado = [];
  bool _buscandoProd = false;

  @override
  void dispose() {
    _parceiroCtrl.dispose();
    _obsCtrl.dispose();
    _prodBuscaCtrl.dispose();
    for (final item in _itens) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _buscarParceiro(String busca) async {
    if (busca.length < 2) {
      setState(() => _parceirosResultado = []);
      return;
    }
    setState(() => _buscandoParceiro = true);
    try {
      final api = context.read<ApiClient>();
      final endpoint =
          _tipo == 'saida' ? ApiConfig.clientes : ApiConfig.fornecedores;
      final result = await api.get(endpoint, queryParams: {'busca': busca});
      final data = result['data'] as List? ?? [];
      setState(() {
        _parceirosResultado = data.cast<Map<String, dynamic>>();
        _buscandoParceiro = false;
      });
    } catch (_) {
      setState(() => _buscandoParceiro = false);
    }
  }

  void _selecionarParceiro(Map<String, dynamic> parceiro) {
    setState(() {
      _parceiroSelecionado = parceiro;
      _parceiroCtrl.text = parceiro['nome']?.toString() ??
          parceiro['razao_social']?.toString() ??
          '';
      _parceirosResultado = [];
    });
  }

  Future<void> _buscarProduto(String busca) async {
    if (busca.length < 2) {
      setState(() => _prodResultado = []);
      return;
    }
    setState(() => _buscandoProd = true);
    try {
      final api = context.read<ApiClient>();
      final result = await api
          .get(ApiConfig.produtos, queryParams: {'busca': busca, 'ativo': '1'});
      final data = result['data'] as List? ?? [];
      setState(() {
        _prodResultado = data.cast<Map<String, dynamic>>();
        _buscandoProd = false;
      });
    } catch (_) {
      setState(() => _buscandoProd = false);
    }
  }

  void _adicionarProduto(Map<String, dynamic> prod) {
    final id = prod['id'] is int
        ? prod['id'] as int
        : int.parse(prod['id'].toString());
    if (_itens.any((i) => i.produtoId == id)) return;
    setState(() {
      _itens.add(_ItemConsignacao(
        produtoId: id,
        descricao: prod['descricao']?.toString() ?? '',
        tamanho: prod['tamanho']?.toString(),
        precoVenda: _parseDouble(prod['preco_venda']),
      ));
      _prodBuscaCtrl.clear();
      _prodResultado = [];
    });
  }

  void _removerItem(int index) {
    _itens[index].dispose();
    setState(() => _itens.removeAt(index));
  }

  double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  double get _valorTotal =>
      _itens.fold(0, (sum, i) => sum + i.quantidade * i.preco);

  Future<void> _salvar() async {
    if (_parceiroSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tipo == 'saida'
              ? 'Selecione um cliente'
              : 'Selecione um fornecedor')));
      return;
    }
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adicione pelo menos um produto')));
      return;
    }
    for (final item in _itens) {
      if (item.quantidade <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quantidade deve ser maior que zero')));
        return;
      }
    }

    setState(() => _salvando = true);

    final parceiroId = _parceiroSelecionado!['id'] is int
        ? _parceiroSelecionado!['id'] as int
        : int.parse(_parceiroSelecionado!['id'].toString());

    final data = <String, dynamic>{
      'tipo': _tipo,
      if (_tipo == 'saida') 'cliente_id': parceiroId,
      if (_tipo == 'entrada') 'fornecedor_id': parceiroId,
      'observacoes': _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      'itens': _itens
          .map((i) => {
                'produto_id': i.produtoId,
                'quantidade': i.quantidade,
                'preco_unitario': i.preco,
              })
          .toList(),
    };

    final provider = context.read<ConsignacoesProvider>();
    final result = await provider.criarConsignacao(data);

    if (!mounted) return;
    setState(() => _salvando = false);

    if (result != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Consignação ${result.numero} criada')));
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(provider.error!)));
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
      child: Container(
        width: 700,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nova Consignação',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tipo
            Row(
              children: [
                Text('Tipo: ',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Saída (Cliente)'),
                  selected: _tipo == 'saida',
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() {
                    _tipo = 'saida';
                    _parceiroSelecionado = null;
                    _parceiroCtrl.clear();
                    _parceirosResultado = [];
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Entrada (Fornecedor)'),
                  selected: _tipo == 'entrada',
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() {
                    _tipo = 'entrada';
                    _parceiroSelecionado = null;
                    _parceiroCtrl.clear();
                    _parceirosResultado = [];
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Parceiro search
            Text(_tipo == 'saida' ? 'Cliente' : 'Fornecedor',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _parceiroCtrl,
              onChanged: _buscarParceiro,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: _tipo == 'saida'
                    ? 'Buscar cliente...'
                    : 'Buscar fornecedor...',
                prefixIcon: Icon(Icons.search, size: 18,
                    color: AppTheme.textMuted),
                suffixIcon: _parceiroSelecionado != null
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 18,
                            color: AppTheme.textMuted),
                        onPressed: () => setState(() {
                          _parceiroSelecionado = null;
                          _parceiroCtrl.clear();
                        }),
                      )
                    : null,
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            if (_parceirosResultado.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _parceirosResultado.length,
                  itemBuilder: (ctx, i) {
                    final p = _parceirosResultado[i];
                    final nome = p['nome']?.toString() ??
                        p['razao_social']?.toString() ??
                        '';
                    return ListTile(
                      dense: true,
                      title: Text(nome,
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textPrimary)),
                      onTap: () => _selecionarParceiro(p),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            // Product search
            Text('Produtos',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _prodBuscaCtrl,
              onChanged: _buscarProduto,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar produto por nome ou código...',
                prefixIcon: Icon(Icons.search, size: 18,
                    color: AppTheme.textMuted),
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            if (_prodResultado.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _prodResultado.length,
                  itemBuilder: (ctx, i) {
                    final p = _prodResultado[i];
                    final desc = p['descricao']?.toString() ?? '';
                    final tam = p['tamanho']?.toString();
                    final preco = _parseDouble(p['preco_venda']);
                    return ListTile(
                      dense: true,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(desc,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary)),
                          ),
                          if (tam != null && tam.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(tam,
                                  style: TextStyle(
                                      fontSize: 10, color: AppTheme.primary)),
                            ),
                        ],
                      ),
                      subtitle: Text(
                          NumberFormat.currency(
                                  locale: 'pt_BR', symbol: 'R\$')
                              .format(preco),
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                      onTap: () => _adicionarProduto(p),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),

            // Items list
            Flexible(
              child: _itens.isEmpty
                  ? Center(
                      child: Text('Nenhum produto adicionado',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textMuted)))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _itens.length,
                      itemBuilder: (ctx, i) {
                        final item = _itens[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.inputFill,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(item.descricao,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.textPrimary)),
                                        ),
                                        if (item.tamanho != null &&
                                            item.tamanho!.isNotEmpty)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(item.tamanho!,
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppTheme.primary)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary),
                                  decoration: InputDecoration(
                                    labelText: 'Qtd',
                                    labelStyle: TextStyle(fontSize: 11),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSm),
                                    ),
                                  ),
                                  controller: item.qtdController,
                                  onChanged: (v) {
                                    item.quantidade =
                                        double.tryParse(v) ?? 0;
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary),
                                  decoration: InputDecoration(
                                    labelText: 'Preço',
                                    labelStyle: TextStyle(fontSize: 11),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSm),
                                    ),
                                  ),
                                  controller: item.precoController,
                                  onChanged: (v) {
                                    item.preco = double.tryParse(v) ?? 0;
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: Text(
                                    currencyFormat
                                        .format(item.quantidade * item.preco),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary)),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    size: 18, color: AppTheme.error),
                                onPressed: () => _removerItem(i),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),

            // Observações
            TextField(
              controller: _obsCtrl,
              maxLines: 2,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Observações (opcional)',
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Total: ${currencyFormat.format(_valorTotal)} (${_itens.length} itens)',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Criar Consignação'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemConsignacao {
  final int produtoId;
  final String descricao;
  final String? tamanho;
  double quantidade;
  double preco;
  final TextEditingController qtdController;
  final TextEditingController precoController;

  _ItemConsignacao({
    required this.produtoId,
    required this.descricao,
    this.tamanho,
    required double precoVenda,
  })  : quantidade = 1,
        preco = precoVenda,
        qtdController = TextEditingController(text: '1'),
        precoController = TextEditingController(text: precoVenda.toStringAsFixed(2));

  void dispose() {
    qtdController.dispose();
    precoController.dispose();
  }
}

// ── Detalhes Dialog ──

class _DetalhesDialog extends StatelessWidget {
  final Consignacao consignacao;
  const _DetalhesDialog({required this.consignacao});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: Container(
        width: 650,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Consignação ${consignacao.numero}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const SizedBox(width: 12),
                      _StatusBadge(status: consignacao.status),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info
              _InfoRow(
                  label: 'Tipo',
                  value: consignacao.tipo == 'saida'
                      ? 'Saída (Cliente)'
                      : 'Entrada (Fornecedor)'),
              _InfoRow(label: 'Parceiro', value: consignacao.parceiro),
              _InfoRow(
                  label: 'Valor Total',
                  value: currencyFormat.format(consignacao.valorTotal)),
              _InfoRow(
                  label: 'Valor Acertado',
                  value: currencyFormat.format(consignacao.valorAcertado)),
              if (consignacao.observacoes != null &&
                  consignacao.observacoes!.isNotEmpty)
                _InfoRow(label: 'Obs', value: consignacao.observacoes!),
              _InfoRow(
                  label: 'Data',
                  value: consignacao.criadoEm != null
                      ? dateFormat.format(consignacao.criadoEm!)
                      : '-'),
              const SizedBox(height: 16),

              // Items
              Text('Itens',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              if (consignacao.itens != null && consignacao.itens!.isNotEmpty)
                DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(AppTheme.scaffoldBackground),
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('Produto')),
                    DataColumn(label: Text('Qtd')),
                    DataColumn(label: Text('Vendida')),
                    DataColumn(label: Text('Devolvida')),
                    DataColumn(label: Text('Pendente')),
                    DataColumn(label: Text('Preço')),
                  ],
                  rows: consignacao.itens!.map((item) {
                    return DataRow(cells: [
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.produtoDescricao ?? '#${item.produtoId}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary)),
                          if (item.produtoTamanho != null &&
                              item.produtoTamanho!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(item.produtoTamanho!,
                                  style: TextStyle(
                                      fontSize: 9, color: AppTheme.primary)),
                            ),
                        ],
                      )),
                      DataCell(Text(item.quantidade.toStringAsFixed(0),
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textPrimary))),
                      DataCell(Text(item.quantidadeVendida.toStringAsFixed(0),
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.greenSuccess))),
                      DataCell(Text(
                          item.quantidadeDevolvida.toStringAsFixed(0),
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.yellowWarning))),
                      DataCell(Text(item.quantidadePendente.toStringAsFixed(0),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: item.quantidadePendente > 0
                                  ? AppTheme.error
                                  : AppTheme.textMuted))),
                      DataCell(Text(
                          currencyFormat.format(item.precoUnitario),
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimary))),
                    ]);
                  }).toList(),
                ),

              // Acertos
              if (consignacao.acertos != null &&
                  consignacao.acertos!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Histórico de Acertos',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                ...consignacao.acertos!.map((acerto) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.inputFill,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            acerto.criadoEm != null
                                ? dateFormat.format(acerto.criadoEm!)
                                : '-',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                        Text(
                            currencyFormat.format(acerto.valorVendido),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.greenSuccess)),
                        if (acerto.formaPagamento != null)
                          Text(acerto.formaPagamento!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted)),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (consignacao.status == 'aberta' ||
                      consignacao.status == 'parcial') ...[
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirmar cancelamento'),
                            content: Text(
                              'Tem certeza que deseja cancelar a consignação #${consignacao.numero}?\n\n'
                              'Esta ação reverterá o estoque e os movimentos de caixa.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Não'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.error),
                                child: const Text('Sim, cancelar',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirmar != true) return;

                        final provider =
                            context.read<ConsignacoesProvider>();
                        final scaffoldMessenger =
                            ScaffoldMessenger.of(context);
                        Navigator.of(context).pop();
                        final ok =
                            await provider.cancelarConsignacao(consignacao.id);
                        scaffoldMessenger.showSnackBar(SnackBar(
                            content: Text(ok
                                ? 'Consignação cancelada'
                                : provider.error ?? 'Erro ao cancelar')));
                      },
                      icon: Icon(Icons.cancel_outlined,
                          size: 16, color: AppTheme.error),
                      label: Text('Cancelar',
                          style: TextStyle(color: AppTheme.error)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.error),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
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

// ── Acerto Dialog ──

class _AcertoDialog extends StatefulWidget {
  final Consignacao consignacao;
  const _AcertoDialog({required this.consignacao});
  @override
  State<_AcertoDialog> createState() => _AcertoDialogState();
}

class _AcertoDialogState extends State<_AcertoDialog> {
  late final List<_AcertoItemData> _itensAcerto;
  String _formaPagamento = 'dinheiro';
  final _obsCtrl = TextEditingController();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _itensAcerto = (widget.consignacao.itens ?? [])
        .where((i) => i.quantidadePendente > 0)
        .map((i) => _AcertoItemData(item: i))
        .toList();
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  double get _valorVendido {
    return _itensAcerto.fold(
        0, (sum, i) => sum + i.vendida * i.item.precoUnitario);
  }

  Future<void> _salvar() async {
    // Validate
    for (final ai in _itensAcerto) {
      if (ai.vendida + ai.devolvida > ai.item.quantidadePendente) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Vendida + Devolvida não pode exceder pendente para ${ai.item.produtoDescricao}')));
        return;
      }
    }

    final itensComMovimento =
        _itensAcerto.where((i) => i.vendida > 0 || i.devolvida > 0).toList();
    if (itensComMovimento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Informe vendida ou devolvida para pelo menos um item')));
      return;
    }

    setState(() => _salvando = true);

    final data = <String, dynamic>{
      'forma_pagamento': _formaPagamento,
      'observacoes':
          _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      'itens': itensComMovimento
          .map((i) => {
                'consignacao_item_id': i.item.id,
                'quantidade_vendida': i.vendida,
                'quantidade_devolvida': i.devolvida,
              })
          .toList(),
    };

    final provider = context.read<ConsignacoesProvider>();
    final ok = await provider.registrarAcerto(widget.consignacao.id, data);

    if (!mounted) return;
    setState(() => _salvando = false);

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acerto registrado com sucesso')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Erro ao registrar acerto')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final c = widget.consignacao;

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: Container(
        width: 650,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Registrar Acerto - ${c.numero}',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  c.tipo == 'saida'
                      ? 'Informe a quantidade vendida e devolvida pelo cliente'
                      : 'Informe a quantidade vendida pela loja e devolvida ao fornecedor',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),

              // Items
              if (_itensAcerto.isEmpty)
                Center(
                    child: Text('Nenhum item pendente',
                        style: TextStyle(color: AppTheme.textMuted)))
              else
                ..._itensAcerto.map((ai) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.inputFill,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                  ai.item.produtoDescricao ??
                                      '#${ai.item.produtoId}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary)),
                            ),
                            Text(
                                'Pendente: ${ai.item.quantidadePendente.toStringAsFixed(0)} | ${currencyFormat.format(ai.item.precoUnitario)}/un',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Vendida',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm),
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    ai.vendida =
                                        double.tryParse(v) ?? 0;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Devolvida',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm),
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    ai.devolvida =
                                        double.tryParse(v) ?? 0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 12),

              // Forma pagamento
              Text('Forma de Pagamento',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _formaPagamento,
                dropdownColor: AppTheme.cardSurface,
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                decoration: InputDecoration(
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'dinheiro', child: Text('Dinheiro')),
                  DropdownMenuItem(value: 'pix', child: Text('PIX')),
                  DropdownMenuItem(
                      value: 'cartao_credito',
                      child: Text('Cartão Crédito')),
                  DropdownMenuItem(
                      value: 'cartao_debito',
                      child: Text('Cartão Débito')),
                  DropdownMenuItem(
                      value: 'transferencia',
                      child: Text('Transferência')),
                ],
                onChanged: (v) => setState(() => _formaPagamento = v!),
              ),
              const SizedBox(height: 12),

              // Obs
              TextField(
                controller: _obsCtrl,
                maxLines: 2,
                style:
                    TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Observações (opcional)',
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      c.tipo == 'saida'
                          ? 'Valor a receber: ${currencyFormat.format(_valorVendido)}'
                          : 'Valor a pagar: ${currencyFormat.format(_valorVendido)}',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.greenSuccess)),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _salvando ? null : _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.greenSuccess,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: _salvando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Registrar Acerto'),
                      ),
                    ],
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

class _AcertoItemData {
  final ConsignacaoItem item;
  double vendida;
  double devolvida;

  _AcertoItemData({required this.item})
      : vendida = 0,
        devolvida = 0;
}

// ── Shared Widgets ──

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
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppTheme.primary : AppTheme.textSecondary)),
      ),
    );
  }
}

class _TipoBadge extends StatelessWidget {
  final String tipo;
  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final isSaida = tipo == 'saida';
    final color = isSaida ? AppTheme.error : AppTheme.greenSuccess;
    final label = isSaida ? 'Saída' : 'Entrada';
    final icon = isSaida ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
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
        color = AppTheme.accent;
        label = 'Aberta';
        break;
      case 'parcial':
        color = AppTheme.yellowWarning;
        label = 'Parcial';
        break;
      case 'fechada':
        color = AppTheme.greenSuccess;
        label = 'Fechada';
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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
            width: 120,
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
