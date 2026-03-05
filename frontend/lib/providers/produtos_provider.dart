import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/produto.dart';
import '../models/categoria.dart';

class ProdutosProvider extends ChangeNotifier {
  final ApiClient _api;

  List<Produto> _produtos = [];
  List<Categoria> _categorias = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = false;
  String? _error;
  String? _busca;
  int? _categoriaFiltro;

  ProdutosProvider(this._api);

  ApiClient get api => _api;
  List<Produto> get produtos => _produtos;
  List<Categoria> get categorias => _categorias;
  int get total => _total;
  int get page => _page;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> carregarProdutos({int page = 1}) async {
    _isLoading = true;
    _error = null;
    _page = page;
    notifyListeners();

    try {
      final params = <String, String>{
        'limit': '50',
        'offset': ((page - 1) * 50).toString(),
      };
      if (_busca != null && _busca!.isNotEmpty) params['busca'] = _busca!;
      if (_categoriaFiltro != null) params['categoria_id'] = _categoriaFiltro.toString();

      final result = await _api.get(ApiConfig.produtos, queryParams: params);
      final data = result['data'] as List;
      _produtos = data.map((e) => Produto.fromJson(e as Map<String, dynamic>)).toList();
      _total = result['total'] as int? ?? _produtos.length;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> carregarCategorias() async {
    try {
      final result = await _api.get(ApiConfig.categorias);
      final data = result['data'] as List;
      _categorias = data.map((e) => Categoria.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (_) {}
  }

  void setBusca(String? busca) {
    _busca = busca;
  }

  void setCategoriaFiltro(int? categoriaId) {
    _categoriaFiltro = categoriaId;
  }

  Future<int> criarProduto(Map<String, dynamic> data) async {
    final result = await _api.post(ApiConfig.produtos, body: data);
    final produto = Produto.fromJson(result['data'] as Map<String, dynamic>);
    await carregarProdutos();
    return produto.id;
  }

  Future<void> atualizarProduto(int id, Map<String, dynamic> data) async {
    await _api.put(ApiConfig.produtoById(id), body: data);
    await carregarProdutos(page: _page);
  }

  Future<void> uploadImagem(int id, String base64Image) async {
    await _api.post(
      ApiConfig.produtoImagem(id),
      body: {'imagem_base64': base64Image},
    );
    await carregarProdutos(page: _page);
  }

  Future<Map<String, dynamic>> batchEstoqueMinimo(int valor) async {
    final result = await _api.patch(
      ApiConfig.produtosBatchEstoqueMinimo,
      body: {'estoque_minimo': valor},
    );
    await carregarProdutos(page: _page);
    return result;
  }

  Future<Map<String, dynamic>> batchMargem(double margem) async {
    final result = await _api.patch(
      ApiConfig.produtosBatchMargem,
      body: {'margem': margem},
    );
    await carregarProdutos(page: _page);
    return result;
  }

  /// Gera um arquivo CSV modelo e abre dialog para salvar.
  /// Usa ; como separador e BOM UTF-8 para compatibilidade com Excel pt-BR.
  Future<String?> gerarModeloCSV() async {
    const sep = ';';
    final header = [
      'descricao', 'preco_venda', 'preco_custo', 'codigo_barras',
      'codigo_interno', 'unidade', 'estoque_atual', 'estoque_minimo',
      'ncm_code', 'tributacao', 'detalhes',
    ].join(sep);
    final exemplo = [
      'Produto Exemplo', '29.90', '15.00', '7890123456789',
      'PROD001', 'un', '50', '10', '6109.10.00', '', 'Observacoes aqui',
    ].join(sep);
    final csv = '$header\n$exemplo\n';

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Salvar Modelo CSV',
      fileName: 'modelo_produtos.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (path == null) return null;

    final filePath = path.endsWith('.csv') ? path : '$path.csv';
    // BOM UTF-8 para Excel reconhecer encoding + conteúdo
    final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(csv)];
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }

  /// Importa produtos a partir de lista de maps (já parseada do CSV).
  Future<Map<String, dynamic>> importarCSV(
      List<Map<String, dynamic>> dados) async {
    final result = await _api.postJson(
      ApiConfig.produtosImportar,
      body: dados,
    );
    await carregarProdutos();
    return result['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> rankingGeral({int limit = 20}) async {
    final result = await _api.get(
      ApiConfig.produtosRankingGeral,
      queryParams: {'limit': limit.toString()},
    );
    return (result['data'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> rankingPorData({
    required String dataInicio,
    required String dataFim,
    int limit = 20,
  }) async {
    final result = await _api.get(
      ApiConfig.produtosRankingPorData,
      queryParams: {
        'data_inicio': dataInicio,
        'data_fim': dataFim,
        'limit': limit.toString(),
      },
    );
    return (result['data'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}
