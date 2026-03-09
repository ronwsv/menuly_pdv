import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/consignacao.dart';

class ConsignacoesProvider extends ChangeNotifier {
  final ApiClient _api;

  List<Consignacao> _consignacoes = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = false;
  String? _error;

  String? _tipo;
  String? _status;

  ConsignacoesProvider(this._api);

  List<Consignacao> get consignacoes => _consignacoes;
  int get total => _total;
  int get page => _page;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get tipo => _tipo;
  String? get status => _status;

  void setTipo(String? tipo) {
    _tipo = tipo;
    _page = 1;
    carregarConsignacoes();
  }

  void setStatus(String? status) {
    _status = status;
    _page = 1;
    carregarConsignacoes();
  }

  void setPage(int page) {
    _page = page;
    carregarConsignacoes();
  }

  void limparFiltros() {
    _tipo = null;
    _status = null;
    _page = 1;
    carregarConsignacoes();
  }

  Future<void> carregarConsignacoes() async {
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
          await _api.get(ApiConfig.consignacoes, queryParams: params);
      final list = result['data'] as List;
      _consignacoes =
          list.map((e) => Consignacao.fromJson(e as Map<String, dynamic>)).toList();
      final pagination = result['pagination'] as Map<String, dynamic>?;
      _total = pagination?['total'] as int? ?? _consignacoes.length;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Consignacao?> obterConsignacao(int id) async {
    try {
      final result = await _api.get(ApiConfig.consignacaoById(id));
      final data = result['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return Consignacao.fromJson(data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Consignacao?> criarConsignacao(Map<String, dynamic> data) async {
    try {
      final result = await _api.post(ApiConfig.consignacoes, body: data);
      await carregarConsignacoes();
      final d = result['data'] as Map<String, dynamic>?;
      if (d == null) return null;
      return Consignacao.fromJson(d);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> registrarAcerto(int id, Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConfig.consignacaoAcerto(id), body: data);
      await carregarConsignacoes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelarConsignacao(int id) async {
    try {
      await _api.post(ApiConfig.consignacaoCancelar(id), body: {});
      await carregarConsignacoes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
