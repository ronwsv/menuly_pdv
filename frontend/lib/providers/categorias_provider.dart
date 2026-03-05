import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/categoria.dart';

class CategoriasProvider extends ChangeNotifier {
  final ApiClient _api;

  List<Categoria> _categorias = [];
  bool _isLoading = false;
  String? _error;

  CategoriasProvider(this._api);

  List<Categoria> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> carregarCategorias() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.get(ApiConfig.categorias);
      final data = result['data'] as List;
      _categorias =
          data.map((e) => Categoria.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Categoria> criarCategoria(Map<String, dynamic> data) async {
    final result = await _api.post(ApiConfig.categorias, body: data);
    final categoria =
        Categoria.fromJson(result['data'] as Map<String, dynamic>);
    await carregarCategorias();
    return categoria;
  }

  Future<void> atualizarCategoria(int id, Map<String, dynamic> data) async {
    await _api.put(ApiConfig.categoriaById(id), body: data);
    await carregarCategorias();
  }

  Future<void> excluirCategoria(int id) async {
    await _api.delete(ApiConfig.categoriaById(id));
    await carregarCategorias();
  }
}
