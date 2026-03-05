import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/cliente.dart';

class ClientesProvider extends ChangeNotifier {
  final ApiClient _api;

  List<Cliente> _clientes = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = false;
  String? _error;
  String? _busca;

  ClientesProvider(this._api);

  List<Cliente> get clientes => _clientes;
  int get total => _total;
  int get page => _page;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> carregarClientes({int page = 1}) async {
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

      final result = await _api.get(ApiConfig.clientes, queryParams: params);
      final data = result['data'] as List;
      _clientes = data.map((e) => Cliente.fromJson(e as Map<String, dynamic>)).toList();
      _total = result['total'] as int? ?? _clientes.length;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setBusca(String? busca) {
    _busca = busca;
  }

  Future<void> criarCliente(Map<String, dynamic> data) async {
    await _api.post(ApiConfig.clientes, body: data);
    await carregarClientes();
  }

  Future<void> atualizarCliente(int id, Map<String, dynamic> data) async {
    await _api.put(ApiConfig.clienteById(id), body: data);
    await carregarClientes(page: _page);
  }

  Future<void> excluirCliente(int id) async {
    await _api.delete(ApiConfig.clienteById(id));
    await carregarClientes(page: _page);
  }
}
