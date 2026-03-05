import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/crediario_parcela.dart';

class CrediarioProvider extends ChangeNotifier {
  final ApiClient _api;

  List<CrediarioParcela> _parcelas = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = false;
  String? _error;
  String? _busca;
  String? _statusFiltro;
  String? _filtroVencimento;
  Map<String, dynamic>? _totais;

  CrediarioProvider(this._api);

  List<CrediarioParcela> get parcelas => _parcelas;
  int get total => _total;
  int get page => _page;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFiltro => _statusFiltro;
  String? get filtroVencimento => _filtroVencimento;
  Map<String, dynamic>? get totais => _totais;

  Future<void> carregarParcelas({int page = 1}) async {
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
      if (_statusFiltro != null && _statusFiltro!.isNotEmpty) {
        params['status'] = _statusFiltro!;
      }
      if (_filtroVencimento != null && _filtroVencimento!.isNotEmpty) {
        params['filtro_vencimento'] = _filtroVencimento!;
      }

      final result =
          await _api.get(ApiConfig.crediario, queryParams: params);
      final data = result['data'] as List;
      _parcelas = data
          .map((e) => CrediarioParcela.fromJson(e as Map<String, dynamic>))
          .toList();
      _total = result['total'] as int? ?? _parcelas.length;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> carregarTotais() async {
    try {
      final result = await _api.get(ApiConfig.crediarioTotais);
      _totais = result['data'] as Map<String, dynamic>?;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setBusca(String? busca) {
    _busca = busca;
  }

  void setStatusFiltro(String? status) {
    _statusFiltro = status;
    _filtroVencimento = null;
  }

  void setFiltroVencimento(String? filtro) {
    _filtroVencimento = filtro;
    _statusFiltro = null;
  }

  void limparFiltros() {
    _busca = null;
    _statusFiltro = null;
    _filtroVencimento = null;
  }

  Future<void> pagarParcela(
      int id, String formaPagamento, String? dataPagamento) async {
    await _api.post(ApiConfig.crediarioPagar(id), body: {
      'forma_pagamento': formaPagamento,
      if (dataPagamento != null) 'data_pagamento': dataPagamento,
    });
    await carregarParcelas(page: _page);
    await carregarTotais();
  }

  Future<Map<String, dynamic>?> verificarLimiteCliente(int clienteId) async {
    try {
      final result = await _api.get(ApiConfig.crediarioLimiteCliente(clienteId));
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
}
