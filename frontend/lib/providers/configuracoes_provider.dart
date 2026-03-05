import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/configuracao.dart';

class ConfiguracoesProvider extends ChangeNotifier {
  final ApiClient _api;

  List<Configuracao> _configs = [];
  List<Usuario> _usuarios = [];
  bool _isLoading = false;
  String? _error;

  ConfiguracoesProvider(this._api);

  List<Configuracao> get configs => _configs;
  List<Usuario> get usuarios => _usuarios;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String getConfig(String chave, [String defaultValue = '']) {
    final cfg = _configs.where((c) => c.chave == chave);
    if (cfg.isEmpty) return defaultValue;
    return cfg.first.valor ?? defaultValue;
  }

  Future<void> carregarConfigs({String? grupo}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (grupo != null && grupo.isNotEmpty) params['grupo'] = grupo;

      final result = await _api.get(ApiConfig.configuracoes, queryParams: params);
      final data = result['data'] as List;
      _configs = data.map((e) => Configuracao.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> salvarConfig(String chave, String valor) async {
    await _api.put(ApiConfig.configuracaoByChave(chave), body: {'valor': valor});
    await carregarConfigs();
  }

  Future<void> salvarConfigs(List<Map<String, dynamic>> configs) async {
    await _api.post(ApiConfig.configuracoesBatch, body: {'configs': configs});
    await carregarConfigs();
  }

  Future<void> carregarUsuarios() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.get(ApiConfig.usuarios);
      final data = result['data'] as List;
      _usuarios = data.map((e) => Usuario.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> criarUsuario(Map<String, dynamic> data) async {
    await _api.post(ApiConfig.usuarios, body: data);
    await carregarUsuarios();
  }

  Future<void> atualizarUsuario(int id, Map<String, dynamic> data) async {
    await _api.put(ApiConfig.usuarioById(id), body: data);
    await carregarUsuarios();
  }
}
