import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/servico.dart';

class ServicosProvider extends ChangeNotifier {
  final ApiClient _api;

  List<Servico> _servicos = [];
  int _total = 0;
  bool _isLoading = false;
  String? _error;
  String? _busca;
  String? _ativoFiltro;

  ServicosProvider(this._api);

  List<Servico> get servicos => _servicos;
  int get total => _total;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> carregarServicos({
    String? busca,
    String? ativo,
  }) async {
    _isLoading = true;
    _error = null;
    if (busca != null) _busca = busca;
    if (ativo != null) _ativoFiltro = ativo;
    notifyListeners();

    try {
      final params = <String, String>{
        'per_page': '100',
        'page': '1',
      };
      if (_busca != null && _busca!.isNotEmpty) params['busca'] = _busca!;
      if (_ativoFiltro != null) params['ativo'] = _ativoFiltro!;

      final result = await _api.get(ApiConfig.servicos, queryParams: params);
      final data = result['data'] as List;
      _servicos = data
          .map((e) => Servico.fromJson(e as Map<String, dynamic>))
          .toList();
      _total = result['pagination']?['total'] as int? ?? _servicos.length;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setBusca(String? busca) {
    _busca = busca;
  }

  void setAtivoFiltro(String? ativo) {
    _ativoFiltro = ativo;
  }

  void limparFiltros() {
    _busca = null;
    _ativoFiltro = null;
  }

  Future<bool> criarServico(Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConfig.servicos, body: data);
      await carregarServicos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> atualizarServico(int id, Map<String, dynamic> data) async {
    try {
      await _api.put(ApiConfig.servicoById(id), body: data);
      await carregarServicos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> excluirServico(int id) async {
    try {
      await _api.delete(ApiConfig.servicoById(id));
      await carregarServicos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> inativarServico(int id) async {
    try {
      await _api.post(ApiConfig.servicoInativar(id));
      await carregarServicos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
