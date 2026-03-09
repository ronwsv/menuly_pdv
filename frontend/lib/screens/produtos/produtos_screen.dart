import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../config/api_config.dart';
import '../../models/produto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/produtos_provider.dart';
import '../../providers/fornecedores_provider.dart';
import 'produto_form_dialog.dart';

class ProdutosScreen extends StatefulWidget {
  ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  final _searchController = TextEditingController();
  int? _categoriaSelecionada;

  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProdutosProvider>();
    provider.carregarProdutos();
    provider.carregarCategorias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    final provider = context.read<ProdutosProvider>();
    provider.setBusca(value.isEmpty ? null : value);
    provider.carregarProdutos();
  }

  void _onCategoriaChanged(int? categoriaId) {
    setState(() => _categoriaSelecionada = categoriaId);
    final provider = context.read<ProdutosProvider>();
    provider.setCategoriaFiltro(categoriaId);
    provider.carregarProdutos();
  }

  void _abrirFormulario([Produto? produto]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: context.read<ProdutosProvider>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<FornecedoresProvider>(),
          ),
        ],
        child: ProdutoFormDialog(produto: produto),
      ),
    );
    if (result == true && mounted) {
      context.read<ProdutosProvider>().carregarProdutos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProdutosProvider>(
      builder: (context, provider, _) {
        final produtos = provider.produtos;
        final totalProdutos = provider.total;
        final ativos = produtos.where((p) => p.ativo).length;
        final estoqueBaixo = produtos.where((p) => p.estoqueBaixo).length;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──
                _buildTopBar(provider),
                SizedBox(height: 20),

                // ── Stat cards ──
                _buildStatCards(totalProdutos, ativos, estoqueBaixo),
                SizedBox(height: 20),

                // ── Product grid ──
                Expanded(
                  child: _buildBody(provider, produtos),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(ProdutosProvider provider) {
    return Row(
      children: [
        Text(
          'Produtos',
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
              hintText: 'Buscar produto...',
              prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
              isDense: true,
            ),
            style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            onSubmitted: _onSearch,
            onChanged: (v) {
              if (v.isEmpty) _onSearch(v);
            },
          ),
        ),
        SizedBox(width: 12),
        _buildCategoriaDropdown(provider),
        Spacer(),
        _buildBatchMenu(provider),
        SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _abrirFormulario(),
          icon: Icon(Icons.add, size: 18),
          label: Text('Novo Produto'),
        ),
      ],
    );
  }

  Widget _buildBatchMenu(ProdutosProvider provider) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: AppTheme.textSecondary),
      tooltip: 'Operacoes em lote',
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppTheme.border),
      ),
      onSelected: (value) {
        if (value == 'estoque_minimo') {
          _showBatchEstoqueMinimoDialog(provider);
        } else if (value == 'margem') {
          _showBatchMargemDialog(provider);
        } else if (value == 'baixar_modelo') {
          _baixarModeloCSV(provider);
        } else if (value == 'importar_csv') {
          _importarCSV(provider);
        }
      },
      itemBuilder: (_) {
        final isAdmin = context.read<AuthProvider>().papelUsuario == 'admin';
        return [
        PopupMenuItem(
          value: 'estoque_minimo',
          child: Row(
            children: [
              Icon(Icons.inventory_outlined, size: 18, color: AppTheme.accent),
              SizedBox(width: 8),
              Text('Definir estoque minimo em lote',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
            ],
          ),
        ),
        if (isAdmin) PopupMenuItem(
          value: 'margem',
          child: Row(
            children: [
              Icon(Icons.percent, size: 18, color: AppTheme.greenSuccess),
              SizedBox(width: 8),
              Text('Alterar margem bruta',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'baixar_modelo',
          child: Row(
            children: [
              Icon(Icons.file_download_outlined, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Baixar modelo CSV',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'importar_csv',
          child: Row(
            children: [
              Icon(Icons.upload_file_rounded, size: 18, color: AppTheme.accent),
              SizedBox(width: 8),
              Text('Importar produtos (CSV)',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ];
      },
    );
  }

  void _showBatchEstoqueMinimoDialog(ProdutosProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Text('Definir Estoque Minimo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Definir o estoque minimo para TODOS os produtos ativos:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Quantidade minima',
                hintText: 'Ex: 5',
              ),
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final valor = int.tryParse(controller.text.trim());
              if (valor == null || valor < 0) return;
              Navigator.pop(ctx);
              try {
                final result = await provider.batchEstoqueMinimo(valor);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                      'Estoque minimo definido para $valor em ${result['affected']} produtos',
                    )),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              }
            },
            child: Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _showBatchMargemDialog(ProdutosProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Text('Alterar Margem Bruta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recalcular o preco de venda de TODOS os produtos ativos\ncom base na nova margem sobre o preco de custo:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nova margem (%)',
                hintText: 'Ex: 50',
                suffixText: '%',
              ),
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            onPressed: () async {
              final margem = double.tryParse(controller.text.trim());
              if (margem == null || margem < 0) return;
              Navigator.pop(ctx);
              try {
                final result = await provider.batchMargem(margem);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                      'Margem de ${margem.toStringAsFixed(1)}% aplicada em ${result['affected']} produtos',
                    )),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              }
            },
            child: Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Future<void> _baixarModeloCSV(ProdutosProvider provider) async {
    try {
      final path = await provider.gerarModeloCSV();
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Modelo CSV salvo em: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar modelo: $e')),
        );
      }
    }
  }

  Future<void> _importarCSV(ProdutosProvider provider) async {
    try {
      // 1. Selecionar arquivo
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Selecionar arquivo CSV',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) return;

      // 2. Ler e parsear CSV
      var content = await File(filePath).readAsString();
      // Remover BOM UTF-8 se presente
      if (content.startsWith('\uFEFF')) {
        content = content.substring(1);
      }
      final lines = content
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Arquivo CSV vazio ou sem dados')),
          );
        }
        return;
      }

      // Detectar separador: ; ou ,
      final sep = lines[0].contains(';') ? ';' : ',';

      final headers = _parseCSVLine(lines[0], sep);
      final dados = <Map<String, dynamic>>[];

      for (int i = 1; i < lines.length; i++) {
        final values = _parseCSVLine(lines[i], sep);
        final row = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < values.length; j++) {
          final key = headers[j].trim();
          final val = values[j].trim();
          if (val.isNotEmpty) {
            // Tentar converter números
            if (['preco_venda', 'preco_custo', 'preco_atacado'].contains(key)) {
              row[key] = double.tryParse(val.replaceAll(',', '.')) ?? val;
            } else if (['estoque_atual', 'estoque_minimo', 'categoria_id',
                'fornecedor_id', 'qtd_minima_atacado'].contains(key)) {
              row[key] = int.tryParse(val) ?? val;
            } else {
              row[key] = val;
            }
          }
        }
        if (row.isNotEmpty) dados.add(row);
      }

      if (dados.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nenhum produto encontrado no arquivo')),
          );
        }
        return;
      }

      // 3. Mostrar preview e confirmar
      if (!mounted) return;
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => _ImportPreviewDialog(
          dados: dados,
          headers: headers,
        ),
      );

      if (confirmar != true || !mounted) return;

      // 4. Enviar ao backend
      final resultado = await provider.importarCSV(dados);
      final importados = resultado['importados'] ?? 0;
      final erros = (resultado['erros'] as List?) ?? [];

      if (!mounted) return;

      // 5. Mostrar resultado
      showDialog(
        context: context,
        builder: (ctx) => _ImportResultDialog(
          importados: importados as int,
          erros: erros,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar: $e')),
        );
      }
    }
  }

  /// Parseia uma linha CSV respeitando aspas.
  List<String> _parseCSVLine(String line, String sep) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (c == sep && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(c);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  Widget _buildCategoriaDropdown(ProdutosProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _categoriaSelecionada,
          hint: Text(
            'Categoria',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          dropdownColor: AppTheme.cardSurface,
          style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Todas'),
            ),
            ...provider.categorias.map(
              (c) => DropdownMenuItem<int?>(
                value: c.id,
                child: Text(c.nome),
              ),
            ),
          ],
          onChanged: _onCategoriaChanged,
        ),
      ),
    );
  }

  Widget _buildStatCards(int total, int ativos, int estoqueBaixo) {
    return Row(
      children: [
        _StatCard(
          label: 'Total Produtos',
          value: total.toString(),
          icon: Icons.inventory_2_outlined,
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
          label: 'Estoque Baixo',
          value: estoqueBaixo.toString(),
          icon: Icons.warning_amber_rounded,
          color: AppTheme.error,
        ),
      ],
    );
  }

  Widget _buildBody(ProdutosProvider provider, List<Produto> produtos) {
    if (provider.isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            SizedBox(height: 12),
            Text(
              'Erro ao carregar produtos',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              provider.error!,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => provider.carregarProdutos(),
              child: Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (produtos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text(
              'Nenhum produto encontrado',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 200,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: produtos.length,
      itemBuilder: (context, index) => _buildProductCard(produtos[index]),
    );
  }

  Widget _buildProductCard(Produto produto) {
    final isBaixo = produto.isCombo ? (produto.estoqueDisponivel ?? 0) == 0 : produto.estoqueBaixo;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _abrirFormulario(produto),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail
              if (produto.imagemPath != null && produto.imagemPath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: Image.network(
                      ApiConfig.uploadUrl(produto.imagemPath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category + Combo badge
                    Row(
                      children: [
                        if (produto.isCombo)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'COMBO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                        if (produto.tamanho != null && produto.tamanho!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              produto.tamanho!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        if (produto.categoriaNome != null && produto.categoriaNome!.isNotEmpty)
                          Expanded(
                            child: Text(
                              produto.categoriaNome!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9575cd),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),

                    // Product name
                    Text(
                      produto.descricao,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),

                    // Barcode
                    if (produto.codigoBarras != null && produto.codigoBarras!.isNotEmpty)
                      Text(
                        produto.codigoBarras!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Consolas',
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    Spacer(),

                    // Wholesale price indicator
                    if (produto.precoAtacado != null && produto.precoAtacado! > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'Atacado: ${_currencyFormat.format(produto.precoAtacado!)} (${produto.qtdMinimaAtacado ?? 0}+ un)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    // Price + Stock badge row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _currencyFormat.format(produto.precoVenda),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.greenSuccess,
                          ),
                        ),
                        if (produto.isCombo && produto.estoqueDisponivel != null)
                          Text(
                            'Est: ${produto.estoqueDisponivel}',
                            style: TextStyle(fontSize: 11, color: isBaixo ? AppTheme.error : AppTheme.textMuted),
                          )
                        else
                          _StockBadge(isLow: isBaixo),
                      ],
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
}

// ── Stat Card widget ─────────────────────────────────────────────────────────

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

// ── Stock Badge widget ───────────────────────────────────────────────────────

class _StockBadge extends StatefulWidget {
  final bool isLow;
  const _StockBadge({required this.isLow});

  @override
  State<_StockBadge> createState() => _StockBadgeState();
}

class _StockBadgeState extends State<_StockBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isLow) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isLow ? AppTheme.error : AppTheme.greenSuccess;
    final text = widget.isLow ? 'Baixo' : 'OK';

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );

    if (widget.isLow) {
      return FadeTransition(opacity: _opacity, child: badge);
    }
    return badge;
  }
}

// ── Import Preview Dialog ────────────────────────────────────────────────────

class _ImportPreviewDialog extends StatelessWidget {
  final List<Map<String, dynamic>> dados;
  final List<String> headers;

  const _ImportPreviewDialog({required this.dados, required this.headers});

  @override
  Widget build(BuildContext context) {
    final previewCount = dados.length > 5 ? 5 : dados.length;

    return AlertDialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      title: Row(
        children: [
          Icon(Icons.preview_rounded, color: AppTheme.primary, size: 22),
          SizedBox(width: 8),
          Text('Importar Produtos',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dados.length} produto(s) encontrado(s) no arquivo.',
              style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            ),
            SizedBox(height: 4),
            Text(
              'Preview das primeiras $previewCount linhas:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            SizedBox(height: 12),
            Container(
              constraints: BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: AppTheme.inputFill,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        AppTheme.primary.withValues(alpha: 0.08)),
                    dataRowMinHeight: 32,
                    dataRowMaxHeight: 40,
                    columnSpacing: 16,
                    columns: [
                      DataColumn(
                          label: Text('#',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary))),
                      DataColumn(
                          label: Text('Descricao',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary))),
                      DataColumn(
                          label: Text('Preco Venda',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary))),
                      DataColumn(
                          label: Text('Cod. Barras',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary))),
                    ],
                    rows: List.generate(previewCount, (i) {
                      final d = dados[i];
                      return DataRow(cells: [
                        DataCell(Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary))),
                        DataCell(Text(
                            d['descricao']?.toString() ?? '',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary))),
                        DataCell(Text(
                            d['preco_venda']?.toString() ?? '',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary))),
                        DataCell(Text(
                            d['codigo_barras']?.toString() ?? '',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted))),
                      ]);
                    }),
                  ),
                ),
              ),
            ),
            if (dados.length > 5) ...[
              SizedBox(height: 8),
              Text(
                '... e mais ${dados.length - 5} produto(s)',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child:
              Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: Icon(Icons.upload_file_rounded, size: 18),
          label: Text('Importar ${dados.length} produto(s)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ── Import Result Dialog ─────────────────────────────────────────────────────

class _ImportResultDialog extends StatelessWidget {
  final int importados;
  final List erros;

  const _ImportResultDialog({required this.importados, required this.erros});

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
          Icon(
            erros.isEmpty
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color:
                erros.isEmpty ? AppTheme.greenSuccess : AppTheme.yellowWarning,
            size: 22,
          ),
          SizedBox(width: 8),
          Text('Resultado da Importacao',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.greenSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                '$importados produto(s) importado(s) com sucesso.',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.greenSuccess),
              ),
            ),

            if (erros.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  '${erros.length} erro(s) encontrado(s):',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.error),
                ),
              ),
              SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: erros.length,
                  itemBuilder: (_, i) {
                    final erro = erros[i] as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'Linha ${erro['linha']}: ${erro['erro']}',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: Text('Fechar'),
        ),
      ],
    );
  }
}
