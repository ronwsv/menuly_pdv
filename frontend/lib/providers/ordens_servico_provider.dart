import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/ordem_servico.dart';

class OrdensServicoProvider extends ChangeNotifier {
  final ApiClient _api;

  List<OrdemServico> _ordens = [];
  int _total = 0;
  bool _isLoading = false;
  String? _error;
  String? _busca;
  String? _statusFiltro;

  OrdensServicoProvider(this._api);

  List<OrdemServico> get ordens => _ordens;
  int get total => _total;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFiltro => _statusFiltro;

  Future<void> carregarOrdens({
    String? busca,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    if (busca != null) _busca = busca;
    if (status != null) _statusFiltro = status;
    notifyListeners();

    try {
      final params = <String, String>{
        'per_page': '100',
        'page': '1',
      };
      if (_busca != null && _busca!.isNotEmpty) params['busca'] = _busca!;
      if (_statusFiltro != null && _statusFiltro!.isNotEmpty) {
        params['status'] = _statusFiltro!;
      }

      final result =
          await _api.get(ApiConfig.ordensServico, queryParams: params);
      final data = result['data'] as List;
      _ordens = data
          .map((e) => OrdemServico.fromJson(e as Map<String, dynamic>))
          .toList();
      _total = result['pagination']?['total'] as int? ?? _ordens.length;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setBusca(String? busca) {
    _busca = busca;
  }

  void setStatusFiltro(String? status) {
    _statusFiltro = status;
  }

  void limparFiltros() {
    _busca = null;
    _statusFiltro = null;
  }

  Future<Map<String, dynamic>?> obterOrdem(int id) async {
    try {
      final result = await _api.get(ApiConfig.ordemServicoById(id));
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> criarOrdem(Map<String, dynamic> data) async {
    try {
      final result = await _api.post(ApiConfig.ordensServico, body: data);
      await carregarOrdens();
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> atualizarOrdem(int id, Map<String, dynamic> data) async {
    try {
      await _api.put(ApiConfig.ordemServicoById(id), body: data);
      await carregarOrdens();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> adicionarItemServico(
      int osId, Map<String, dynamic> data) async {
    try {
      final result =
          await _api.post(ApiConfig.osAdicionarItemServico(osId), body: data);
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> removerItemServico(
      int osId, int itemId) async {
    try {
      final result =
          await _api.delete(ApiConfig.osRemoverItemServico(osId, itemId));
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> adicionarItemProduto(
      int osId, Map<String, dynamic> data) async {
    try {
      final result =
          await _api.post(ApiConfig.osAdicionarItemProduto(osId), body: data);
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> removerItemProduto(
      int osId, int itemId) async {
    try {
      final result =
          await _api.delete(ApiConfig.osRemoverItemProduto(osId, itemId));
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> finalizarOrdem(int id, Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConfig.osFinalizar(id), body: data);
      await carregarOrdens();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelarOrdem(int id) async {
    try {
      await _api.post(ApiConfig.osCancelar(id));
      await carregarOrdens();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> excluirOrdem(int id) async {
    try {
      await _api.delete(ApiConfig.ordemServicoById(id));
      await carregarOrdens();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
