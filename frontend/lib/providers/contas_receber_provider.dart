import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/conta_receber.dart';

class ContasReceberProvider extends ChangeNotifier {
  final ApiClient _api;

  List<ContaReceber> _contas = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = false;
  String? _error;
  String? _busca;
  String? _statusFiltro;
  String? _filtroVencimento;
  Map<String, dynamic>? _totais;

  ContasReceberProvider(this._api);

  List<ContaReceber> get contas => _contas;
  int get total => _total;
  int get page => _page;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFiltro => _statusFiltro;
  String? get filtroVencimento => _filtroVencimento;
  Map<String, dynamic>? get totais => _totais;

  Future<void> carregarContas({int page = 1}) async {
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
          await _api.get(ApiConfig.contasReceber, queryParams: params);
      final data = result['data'] as List;
      _contas = data
          .map((e) => ContaReceber.fromJson(e as Map<String, dynamic>))
          .toList();
      _total = result['total'] as int? ?? _contas.length;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> carregarTotais() async {
    try {
      final result = await _api.get(ApiConfig.contasReceberTotais);
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

  Future<void> criarConta(Map<String, dynamic> data) async {
    await _api.post(ApiConfig.contasReceber, body: data);
    await carregarContas();
    await carregarTotais();
  }

  Future<void> atualizarConta(int id, Map<String, dynamic> data) async {
    await _api.put(ApiConfig.contaReceberById(id), body: data);
    await carregarContas(page: _page);
    await carregarTotais();
  }

  Future<void> darBaixa(
      int id, String formaRecebimento, String? dataRecebimento) async {
    await _api.post(ApiConfig.contaReceberBaixa(id), body: {
      'forma_recebimento': formaRecebimento,
      if (dataRecebimento != null) 'data_recebimento': dataRecebimento,
    });
    await carregarContas(page: _page);
    await carregarTotais();
  }

  Future<void> cancelarConta(int id) async {
    await _api.post(ApiConfig.contaReceberCancelar(id), body: {});
    await carregarContas(page: _page);
    await carregarTotais();
  }

  Future<void> excluirConta(int id) async {
    await _api.delete(ApiConfig.contaReceberById(id));
    await carregarContas(page: _page);
    await carregarTotais();
  }
}
