import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/fornecedor.dart';

class FornecedoresProvider extends ChangeNotifier {
  final ApiClient _api;

  List<Fornecedor> _fornecedores = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = false;
  String? _error;
  String? _busca;

  FornecedoresProvider(this._api);

  List<Fornecedor> get fornecedores => _fornecedores;
  int get total => _total;
  int get page => _page;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> carregarFornecedores({int page = 1}) async {
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

      final result = await _api.get(ApiConfig.fornecedores, queryParams: params);
      final data = result['data'] as List;
      _fornecedores = data.map((e) => Fornecedor.fromJson(e as Map<String, dynamic>)).toList();
      _total = result['total'] as int? ?? _fornecedores.length;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setBusca(String? busca) {
    _busca = busca;
  }

  Future<void> criarFornecedor(Map<String, dynamic> data) async {
    await _api.post(ApiConfig.fornecedores, body: data);
    await carregarFornecedores();
  }

  Future<void> atualizarFornecedor(int id, Map<String, dynamic> data) async {
    await _api.put(ApiConfig.fornecedorById(id), body: data);
    await carregarFornecedores(page: _page);
  }

  Future<void> excluirFornecedor(int id) async {
    await _api.delete(ApiConfig.fornecedorById(id));
    await carregarFornecedores(page: _page);
  }
}
