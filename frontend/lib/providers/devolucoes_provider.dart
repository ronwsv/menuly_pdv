import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';

class DevolucoesProvider extends ChangeNotifier {
  final ApiClient _api;

  List<Map<String, dynamic>> _devolucoes = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = false;
  String? _error;

  // Filtros
  String? _tipo;
  String? _status;

  DevolucoesProvider(this._api);

  List<Map<String, dynamic>> get devolucoes => _devolucoes;
  int get total => _total;
  int get page => _page;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get tipo => _tipo;
  String? get status => _status;

  void setTipo(String? tipo) {
    _tipo = tipo;
    _page = 1;
    carregarDevolucoes();
  }

  void setStatus(String? status) {
    _status = status;
    _page = 1;
    carregarDevolucoes();
  }

  void limparFiltros() {
    _tipo = null;
    _status = null;
    _page = 1;
    carregarDevolucoes();
  }

  Future<void> carregarDevolucoes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{
        'page': _page.toString(),
        'per_page': '50',
      };
      if (_tipo != null) params['tipo'] = _tipo!;
      if (_status != null) params['status'] = _status!;

      final result =
          await _api.get(ApiConfig.devolucoes, queryParams: params);
      _devolucoes =
          (result['data'] as List).cast<Map<String, dynamic>>();
      _total = result['total'] as int? ?? _devolucoes.length;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> obterDevolucao(int id) async {
    try {
      final result = await _api.get(ApiConfig.devolucaoById(id));
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> buscarVenda(String numero) async {
    try {
      final result = await _api.get(ApiConfig.devolucaoBuscarVenda(numero));
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> buscarVendasPorValor(double valor) async {
    try {
      final result =
          await _api.get(ApiConfig.devolucaoBuscarVendasPorValor(valor));
      return (result['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<Map<String, dynamic>?> criarDevolucao(
      Map<String, dynamic> data) async {
    try {
      final result = await _api.post(ApiConfig.devolucoes, body: data);
      await carregarDevolucoes();
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── Créditos ──

  Future<Map<String, dynamic>?> obterSaldoCliente(int clienteId) async {
    try {
      final result = await _api.get(ApiConfig.creditosCliente(clienteId));
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> utilizarCredito(
      int creditoId, double valor) async {
    try {
      final result = await _api.post(
        ApiConfig.creditoUtilizar(creditoId),
        body: {'valor': valor},
      );
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<Map<String, dynamic>?> totaisCreditos() async {
    try {
      final result = await _api.get(ApiConfig.creditosTotais);
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }
}
