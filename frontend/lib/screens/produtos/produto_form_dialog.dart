import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

import '../../app/theme.dart';
import '../../config/api_config.dart';
import '../../models/produto.dart';
import '../../models/fornecedor.dart';
import '../../providers/auth_provider.dart';
import '../../providers/produtos_provider.dart';
import '../../providers/fornecedores_provider.dart';

class ProdutoFormDialog extends StatefulWidget {
  final Produto? produto;

  ProdutoFormDialog({super.key, this.produto});

  @override
  State<ProdutoFormDialog> createState() => _ProdutoFormDialogState();
}

class _ProdutoFormDialogState extends State<ProdutoFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _codigoBarrasCtrl;
  late final TextEditingController _codigoInternoCtrl;
  late final TextEditingController _precoCustoCtrl;
  late final TextEditingController _precoVendaCtrl;
  late final TextEditingController _estoqueAtualCtrl;
  late final TextEditingController _estoqueMinimoCtrl;
  late final TextEditingController _ncmCtrl;
  late final TextEditingController _tributacaoCtrl;
  late final TextEditingController _detalhesCtrl;
  late final TextEditingController _tamanhoCtrl;

  int? _categoriaId;
  int? _fornecedorId;
  String _unidade = 'un';
  bool _saving = false;
  List<Fornecedor> _fornecedores = [];

  // Combo state
  bool _isCombo = false;
  List<_ComboComponente> _comboComponentes = [];

  // Image state
  Uint8List? _imageBytes;
  bool _hasNewImage = false;
  bool _compressing = false;

  static const _unidadesBase = [
    'un', 'pc', 'par', 'dz', 'kit', 'cx', 'pct', 'fd',
    'kg', 'g', 'l', 'ml', 'm', 'm2', 'm3', 'cm',
    'rl', 'gl', 'jg', 'ct', 'sc', 'tb', 'lt',
  ];
  late final List<String> _unidades;

  bool get _isEditing => widget.produto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    _descricaoCtrl = TextEditingController(text: p?.descricao ?? '');
    _codigoBarrasCtrl = TextEditingController(text: p?.codigoBarras ?? '');
    _codigoInternoCtrl = TextEditingController(text: p?.codigoInterno ?? '');
    _precoCustoCtrl = TextEditingController(
      text: p != null ? p.precoCusto.toStringAsFixed(2) : '',
    );
    _precoVendaCtrl = TextEditingController(
      text: p != null ? p.precoVenda.toStringAsFixed(2) : '',
    );
    _estoqueAtualCtrl = TextEditingController(
      text: p?.estoqueAtual.toString() ?? '0',
    );
    _estoqueMinimoCtrl = TextEditingController(
      text: p?.estoqueMinimo.toString() ?? '0',
    );
    _ncmCtrl = TextEditingController(text: p?.ncmCode ?? '');
    _tributacaoCtrl = TextEditingController(text: p?.tributacao ?? '');
    _detalhesCtrl = TextEditingController(text: p?.detalhes ?? '');
    _tamanhoCtrl = TextEditingController(text: p?.tamanho ?? '');
    _categoriaId = p?.categoriaId;
    _fornecedorId = p?.fornecedorId;
    _unidade = p?.unidade ?? 'un';
    // Garantir que a unidade do produto esteja na lista de opções
    if (_unidadesBase.contains(_unidade)) {
      _unidades = _unidadesBase;
    } else {
      _unidades = [_unidade, ..._unidadesBase];
    }
    _isCombo = p?.isCombo ?? false;
    if (_isCombo && p?.comboItens != null) {
      _comboComponentes = p!.comboItens!
          .map((ci) => _ComboComponente(
                produtoId: ci.produtoId,
                descricao: ci.descricao,
                quantidade: ci.quantidade,
                precoVenda: ci.precoVenda,
              ))
          .toList();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFornecedores();
      if (_isCombo && _comboComponentes.isEmpty && p != null) {
        _loadComboItens(p.id);
      }
    });
  }

  Future<void> _loadComboItens(int produtoId) async {
    try {
      final provider = context.read<ProdutosProvider>();
      final itens = await provider.carregarComboItens(produtoId);
      if (mounted) {
        setState(() {
          _comboComponentes = itens
              .map((ci) => _ComboComponente(
                    produtoId: ci.produtoId,
                    descricao: ci.descricao,
                    quantidade: ci.quantidade,
                    precoVenda: ci.precoVenda,
                  ))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFornecedores() async {
    try {
      final provider = context.read<FornecedoresProvider>();
      await provider.carregarFornecedores();
      if (mounted) {
        setState(() => _fornecedores = provider.fornecedores);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _codigoBarrasCtrl.dispose();
    _codigoInternoCtrl.dispose();
    _precoCustoCtrl.dispose();
    _precoVendaCtrl.dispose();
    _estoqueAtualCtrl.dispose();
    _estoqueMinimoCtrl.dispose();
    _ncmCtrl.dispose();
    _tributacaoCtrl.dispose();
    _detalhesCtrl.dispose();
    _tamanhoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.first.path;
    if (filePath == null) return;

    setState(() => _compressing = true);

    try {
      final fileBytes = await File(filePath).readAsBytes();
      final decoded = img.decodeImage(fileBytes);

      if (decoded == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Formato de imagem nao suportado')),
          );
        }
        return;
      }

      // Resize to max 300px width maintaining aspect ratio
      img.Image resized;
      if (decoded.width > 300) {
        resized = img.copyResize(decoded, width: 300);
      } else {
        resized = decoded;
      }

      // Encode as JPEG with 75% quality
      final compressed = img.encodeJpg(resized, quality: 75);

      if (mounted) {
        setState(() {
          _imageBytes = Uint8List.fromList(compressed);
          _hasNewImage = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar imagem: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _compressing = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'descricao': _descricaoCtrl.text.trim(),
      'codigo_barras': _codigoBarrasCtrl.text.trim().isEmpty
          ? null
          : _codigoBarrasCtrl.text.trim(),
      'codigo_interno': _codigoInternoCtrl.text.trim().isEmpty
          ? null
          : _codigoInternoCtrl.text.trim(),
      'detalhes': _detalhesCtrl.text.trim().isEmpty
          ? null
          : _detalhesCtrl.text.trim(),
      'categoria_id': _categoriaId,
      'ncm_code': _ncmCtrl.text.trim().isEmpty
          ? null
          : _ncmCtrl.text.trim(),
      'tributacao': _tributacaoCtrl.text.trim().isEmpty
          ? null
          : _tributacaoCtrl.text.trim(),
      'fornecedor_id': _fornecedorId,
      'unidade': _unidade,
      'tamanho': _tamanhoCtrl.text.trim().isEmpty ? null : _tamanhoCtrl.text.trim(),
      'preco_custo': double.tryParse(_precoCustoCtrl.text.trim()) ?? 0,
      'preco_venda': double.tryParse(_precoVendaCtrl.text.trim()) ?? 0,
      'estoque_atual': _isCombo ? 0 : (int.tryParse(_estoqueAtualCtrl.text.trim()) ?? 0),
      'estoque_minimo': _isCombo ? 0 : (int.tryParse(_estoqueMinimoCtrl.text.trim()) ?? 0),
      'is_combo': _isCombo,
      if (_isCombo)
        'combo_itens': _comboComponentes
            .map((c) => {'produto_id': c.produtoId, 'quantidade': c.quantidade})
            .toList(),
    };

    try {
      final provider = context.read<ProdutosProvider>();
      int produtoId;

      if (_isEditing) {
        produtoId = widget.produto!.id;
        await provider.atualizarProduto(produtoId, data);
      } else {
        produtoId = await provider.criarProduto(data);
      }

      // Upload image if user picked a new one
      if (_hasNewImage && _imageBytes != null) {
        await provider.uploadImagem(produtoId, base64Encode(_imageBytes!));
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
    final provider = context.watch<ProdutosProvider>();

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 700, maxHeight: _isCombo ? 750 : 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ──
                Text(
                  _isEditing ? 'Editar Produto' : 'Novo Produto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 20),

                // ── Scrollable content ──
                Flexible(
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: form fields
                        Expanded(child: _buildFormFields(provider)),
                        SizedBox(width: 20),
                        // Right: image area
                        _buildImageArea(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // ── Action buttons ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      child: Text('Cancelar'),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saving ? null : _salvar,
                      child: _saving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
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

  String _calcMargemText() {
    final custo = double.tryParse(_precoCustoCtrl.text.trim()) ?? 0;
    final venda = double.tryParse(_precoVendaCtrl.text.trim()) ?? 0;
    if (custo > 0 && venda > 0) {
      final margem = ((venda - custo) / custo) * 100;
      return '${margem.toStringAsFixed(1)}%';
    }
    return '--';
  }

  Widget _buildFormFields(ProdutosProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Descricao *
        TextFormField(
          controller: _descricaoCtrl,
          decoration: InputDecoration(labelText: 'Descricao *'),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo obrigatorio' : null,
        ),
        SizedBox(height: 12),

        // Codigo Barras + Codigo Interno
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _codigoBarrasCtrl,
                decoration: InputDecoration(labelText: 'Codigo Barras'),
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _codigoInternoCtrl,
                decoration: InputDecoration(labelText: 'Codigo Interno'),
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Categoria + Unidade + Tamanho
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildCategoriaField(provider),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildUnidadeField(),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _tamanhoCtrl,
                decoration: InputDecoration(
                  labelText: 'Tamanho',
                  hintText: 'P, M, G, 42...',
                  hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Fornecedor
        _buildFornecedorField(),
        SizedBox(height: 12),

        // Combo toggle
        _buildComboToggle(),
        if (_isCombo) ...[
          SizedBox(height: 12),
          _buildComboComponentes(),
        ],
        SizedBox(height: 12),

        // Preco Custo + Preco Venda + Margem
        Builder(builder: (context) {
          final isAdmin = context.read<AuthProvider>().papelUsuario == 'admin';
          return Row(
            children: [
              if (isAdmin) ...[
                Expanded(
                  child: TextFormField(
                    controller: _precoCustoCtrl,
                    decoration: InputDecoration(labelText: 'Preco Custo *'),
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo obrigatorio' : null,
                  ),
                ),
                SizedBox(width: 12),
              ],
              Expanded(
                child: TextFormField(
                  controller: _precoVendaCtrl,
                  decoration: InputDecoration(labelText: 'Preco Venda *'),
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Campo obrigatorio' : null,
                ),
              ),
              if (isAdmin) ...[
                SizedBox(width: 12),
                // Margem display
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.inputFill,
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Column(
                    children: [
                      Text('Margem',
                          style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      SizedBox(height: 2),
                      Text(
                        _calcMargemText(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _calcMargemText() == '--'
                              ? AppTheme.textMuted
                              : AppTheme.greenSuccess,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        }),
        SizedBox(height: 12),

        // Estoque Atual + Estoque Minimo (hidden for combos)
        if (!_isCombo) Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _estoqueAtualCtrl,
                decoration: InputDecoration(labelText: 'Estoque Atual'),
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _estoqueMinimoCtrl,
                decoration: InputDecoration(labelText: 'Estoque Minimo'),
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // NCM + Tributacao
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ncmCtrl,
                decoration: InputDecoration(
                  labelText: 'NCM',
                  hintText: 'Ex: 6109.10.00',
                  hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _tributacaoCtrl,
                decoration: InputDecoration(
                  labelText: 'Tributacao',
                  hintText: 'Info tributaria',
                  hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Detalhes / Observacoes
        TextFormField(
          controller: _detalhesCtrl,
          decoration: InputDecoration(
            labelText: 'Detalhes / Observacoes',
            alignLabelWithHint: true,
          ),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          maxLines: 3,
          minLines: 2,
        ),
      ],
    );
  }

  Widget _buildCategoriaField(ProdutosProvider provider) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int?>(
            value: _categoriaId,
            decoration: InputDecoration(labelText: 'Categoria'),
            dropdownColor: AppTheme.cardSurface,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Sem categoria'),
              ),
              ...provider.categorias.map(
                (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.nome)),
              ),
            ],
            onChanged: (v) => setState(() => _categoriaId = v),
          ),
        ),
        SizedBox(width: 4),
        Tooltip(
          message: 'Nova categoria',
          child: InkWell(
            onTap: () => _showNovaCategoriaDialog(provider),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Icon(Icons.add, size: 18, color: AppTheme.accent),
            ),
          ),
        ),
      ],
    );
  }

  void _showNovaCategoriaDialog(ProdutosProvider provider) {
    final nomeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Text(
          'Nova Categoria',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: TextField(
          controller: nomeCtrl,
          decoration: InputDecoration(
            labelText: 'Nome da categoria',
            hintText: 'Ex: Bebidas',
          ),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          autofocus: true,
          onSubmitted: (_) => _criarCategoria(ctx, nomeCtrl, provider),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _criarCategoria(ctx, nomeCtrl, provider),
            child: Text('Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _criarCategoria(
    BuildContext dialogContext,
    TextEditingController nomeCtrl,
    ProdutosProvider provider,
  ) async {
    final nome = nomeCtrl.text.trim();
    if (nome.isEmpty) return;

    try {
      final api = provider.api;
      final result = await api.post(
        ApiConfig.categorias,
        body: {'nome': nome},
      );
      final novaCategoria = result['data'] as Map<String, dynamic>;
      final novoId = novaCategoria['id'] is int
          ? novaCategoria['id'] as int
          : int.parse(novaCategoria['id'].toString());

      // Reload categories in the products provider
      await provider.carregarCategorias();

      if (mounted) {
        setState(() => _categoriaId = novoId);
      }
      if (dialogContext.mounted) Navigator.pop(dialogContext);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar categoria: $e')),
        );
      }
    }
  }

  Widget _buildUnidadeField() {
    return DropdownButtonFormField<String>(
      value: _unidade,
      decoration: InputDecoration(labelText: 'Unidade'),
      dropdownColor: AppTheme.cardSurface,
      style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      items: _unidades
          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _unidade = v);
      },
    );
  }

  Widget _buildFornecedorField() {
    return DropdownButtonFormField<int?>(
      value: _fornecedorId,
      decoration: InputDecoration(labelText: 'Fornecedor'),
      dropdownColor: AppTheme.cardSurface,
      style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      isExpanded: true,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Sem fornecedor'),
        ),
        ..._fornecedores.map(
          (f) => DropdownMenuItem<int?>(
            value: f.id,
            child: Text(
              f.nomeFantasia ?? f.razaoSocial,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (v) => setState(() => _fornecedorId = v),
    );
  }

  Widget _buildImageArea() {
    final existingPath = widget.produto?.imagemPath;
    final hasExistingImage = existingPath != null && existingPath.isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: _compressing ? null : _pickImage,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppTheme.inputFill,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: _compressing
                  ? Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _imageBytes != null
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            width: 150,
                            height: 150,
                          ),
                        )
                      : hasExistingImage
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              child: Image.network(
                                ApiConfig.uploadUrl(existingPath),
                                fit: BoxFit.cover,
                                width: 150,
                                height: 150,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholderContent(),
                              ),
                            )
                          : _buildPlaceholderContent(),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          _compressing
              ? 'Comprimindo...'
              : _imageBytes != null
                  ? '${(_imageBytes!.length / 1024).toStringAsFixed(0)} KB'
                  : 'Clique para\nadicionar',
          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          textAlign: TextAlign.center,
        ),
        if (_imageBytes != null || (hasExistingImage && !_hasNewImage))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: _compressing ? null : _pickImage,
              icon: Icon(Icons.refresh, size: 14),
              label: Text('Trocar', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 40, color: AppTheme.textMuted),
        SizedBox(height: 8),
        Text(
          'Imagem',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildComboToggle() {
    return Row(
      children: [
        Switch(
          value: _isCombo,
          activeColor: AppTheme.accent,
          onChanged: (v) => setState(() => _isCombo = v),
        ),
        SizedBox(width: 8),
        Text(
          'Este produto e um combo/kit',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        if (_isCombo && _comboComponentes.isNotEmpty) ...[
          Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              'Soma: R\$ ${_somaComponentes().toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  double _somaComponentes() {
    return _comboComponentes.fold(0.0, (sum, c) => sum + (c.precoVenda * c.quantidade));
  }

  Widget _buildComboComponentes() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.accent),
              SizedBox(width: 6),
              Text(
                'Componentes do Combo',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              Spacer(),
              InkWell(
                onTap: _adicionarComponente,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: AppTheme.accent),
                      SizedBox(width: 4),
                      Text('Adicionar', style: TextStyle(fontSize: 12, color: AppTheme.accent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_comboComponentes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Nenhum componente adicionado',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
            )
          else ...[
            SizedBox(height: 8),
            ..._comboComponentes.asMap().entries.map((entry) {
              final idx = entry.key;
              final comp = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        comp.descricao,
                        style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      height: 30,
                      child: TextFormField(
                        initialValue: comp.quantidade.toStringAsFixed(comp.quantidade == comp.quantidade.toInt() ? 0 : 1),
                        style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (v) {
                          final qty = double.tryParse(v);
                          if (qty != null && qty > 0) {
                            setState(() => _comboComponentes[idx] = comp.copyWith(quantidade: qty));
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'R\$ ${(comp.precoVenda * comp.quantidade).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    SizedBox(width: 4),
                    InkWell(
                      onTap: () => setState(() => _comboComponentes.removeAt(idx)),
                      child: Icon(Icons.close, size: 16, color: AppTheme.error),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _adicionarComponente() async {
    final api = context.read<ProdutosProvider>().api;
    final searchCtrl = TextEditingController();
    List<Produto> resultados = [];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            side: BorderSide(color: AppTheme.border),
          ),
          title: Text(
            'Buscar Produto',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          content: SizedBox(
            width: 400,
            height: 350,
            child: Column(
              children: [
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome, codigo...',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                  onChanged: (v) async {
                    if (v.length < 2) return;
                    try {
                      final result = await api.get(
                        ApiConfig.produtos,
                        queryParams: {'busca': v, 'limit': '20'},
                      );
                      final data = result['data'] as List;
                      final todos = data
                          .map((e) => Produto.fromJson(e as Map<String, dynamic>))
                          .where((p) => !p.isCombo && p.ativo)
                          .where((p) => !_comboComponentes.any((c) => c.produtoId == p.id))
                          .toList();
                      setDialogState(() => resultados = todos);
                    } catch (_) {}
                  },
                ),
                SizedBox(height: 8),
                Expanded(
                  child: resultados.isEmpty
                      ? Center(
                          child: Text(
                            'Digite para buscar produtos',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        )
                      : ListView.builder(
                          itemCount: resultados.length,
                          itemBuilder: (_, i) {
                            final p = resultados[i];
                            return ListTile(
                              dense: true,
                              title: Text(
                                p.descricao,
                                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                              ),
                              subtitle: Text(
                                'R\$ ${p.precoVenda.toStringAsFixed(2)} | Est: ${p.estoqueAtual}',
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                              onTap: () {
                                setState(() {
                                  _comboComponentes.add(_ComboComponente(
                                    produtoId: p.id,
                                    descricao: p.descricao,
                                    quantidade: 1,
                                    precoVenda: p.precoVenda,
                                  ));
                                });
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComboComponente {
  final int produtoId;
  final String descricao;
  final double quantidade;
  final double precoVenda;

  _ComboComponente({
    required this.produtoId,
    required this.descricao,
    required this.quantidade,
    required this.precoVenda,
  });

  _ComboComponente copyWith({double? quantidade}) {
    return _ComboComponente(
      produtoId: produtoId,
      descricao: descricao,
      quantidade: quantidade ?? this.quantidade,
      precoVenda: precoVenda,
    );
  }
}
