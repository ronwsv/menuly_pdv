import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';

class EstoqueProvider extends ChangeNotifier {
  final ApiClient _api;

  List<Map<String, dynamic>> _posicao = [];
  List<Map<String, dynamic>> _abaixoMinimo = [];
  List<Map<String, dynamic>> _historico = [];
  bool _isLoading = false;
  String? _error;

  EstoqueProvider(this._api);

  List<Map<String, dynamic>> get posicao => _posicao;
  List<Map<String, dynamic>> get abaixoMinimo => _abaixoMinimo;
  List<Map<String, dynamic>> get historico => _historico;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> carregarPosicao() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.get(ApiConfig.estoquePosicao);
      _posicao = (result['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> carregarAbaixoMinimo() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.get(ApiConfig.estoqueAbaixoMinimo);
      _abaixoMinimo = (result['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> carregarHistorico({
    int? produtoId,
    String? tipo,
    String? ocorrencia,
    String? dataInicio,
    String? dataFim,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (produtoId != null) params['produto_id'] = produtoId.toString();
      if (tipo != null && tipo.isNotEmpty) params['tipo'] = tipo;
      if (ocorrencia != null && ocorrencia.isNotEmpty) {
        params['ocorrencia'] = ocorrencia;
      }
      if (dataInicio != null) params['data_inicio'] = dataInicio;
      if (dataFim != null) params['data_fim'] = dataFim;

      final result =
          await _api.get(ApiConfig.estoqueHistorico, queryParams: params);
      _historico = (result['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> registrarMovimento(
      Map<String, dynamic> data) async {
    final result = await _api.post(ApiConfig.estoqueMovimentos, body: data);
    return result;
  }
}
