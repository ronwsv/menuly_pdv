import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/venda.dart';

class VendasProvider extends ChangeNotifier {
  final ApiClient _api;

  List<Venda> _vendas = [];
  int _total = 0;
  bool _isLoading = false;
  String? _error;
  String? _busca;
  String? _tipoFiltro;
  String? _statusFiltro;
  String? _dataInicio;
  String? _dataFim;

  VendasProvider(this._api);

  List<Venda> get vendas => _vendas;
  int get total => _total;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get tipoFiltro => _tipoFiltro;
  String? get statusFiltro => _statusFiltro;

  Future<void> carregarVendas({
    String? tipo,
    String? status,
    String? dataInicio,
    String? dataFim,
    String? busca,
  }) async {
    _isLoading = true;
    _error = null;
    if (tipo != null) _tipoFiltro = tipo;
    if (status != null) _statusFiltro = status;
    if (dataInicio != null) _dataInicio = dataInicio;
    if (dataFim != null) _dataFim = dataFim;
    if (busca != null) _busca = busca;
    notifyListeners();

    try {
      final params = <String, String>{
        'limit': '50',
        'offset': '0',
      };
      if (_tipoFiltro != null) params['tipo'] = _tipoFiltro!;
      if (_statusFiltro != null) params['status'] = _statusFiltro!;
      if (_dataInicio != null) params['data_inicio'] = _dataInicio!;
      if (_dataFim != null) params['data_fim'] = _dataFim!;

      final result = await _api.get(ApiConfig.vendas, queryParams: params);
      final data = result['data'] as List;
      var vendas = data
          .map((e) => Venda.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filtro local por numero (busca)
      if (_busca != null && _busca!.isNotEmpty) {
        final b = _busca!.toLowerCase();
        vendas = vendas
            .where((v) => v.numero.toLowerCase().contains(b))
            .toList();
      }

      _vendas = vendas;
      _total = result['total'] as int? ?? _vendas.length;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setTipoFiltro(String? tipo) {
    _tipoFiltro = tipo;
  }

  void setStatusFiltro(String? status) {
    _statusFiltro = status;
  }

  void setBusca(String? busca) {
    _busca = busca;
  }

  void setDataRange(String? inicio, String? fim) {
    _dataInicio = inicio;
    _dataFim = fim;
  }

  void limparFiltros() {
    _tipoFiltro = null;
    _statusFiltro = null;
    _dataInicio = null;
    _dataFim = null;
    _busca = null;
  }

  Future<Map<String, dynamic>?> obterVenda(int id) async {
    try {
      final result = await _api.get(ApiConfig.vendaById(id));
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelarVenda(int id) async {
    try {
      await _api.post(ApiConfig.vendaCancelar(id));
      await carregarVendas();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> criarOrcamento({
    required List<Map<String, dynamic>> itens,
    int? clienteId,
    double desconto = 0,
  }) async {
    try {
      final body = <String, dynamic>{
        'tipo': 'Orcamento',
        'desconto': desconto,
        'itens': itens,
      };
      if (clienteId != null) body['cliente_id'] = clienteId;

      final result = await _api.post(ApiConfig.vendas, body: body);
      await carregarVendas();
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> converterOrcamento(
    int id, {
    required String formaPagamento,
    double? valorRecebido,
  }) async {
    try {
      final result = await _api.post(ApiConfig.vendaConverter(id), body: {
        'forma_pagamento': formaPagamento,
        if (valorRecebido != null) 'valor_recebido': valorRecebido,
      });
      await carregarVendas();
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
