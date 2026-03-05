import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/caixa.dart';
import '../models/caixa_movimento.dart';

class CaixasProvider extends ChangeNotifier {
  final ApiClient _api;

  List<Caixa> _caixas = [];
  Caixa? _caixaSelecionada;
  List<CaixaMovimento> _movimentos = [];
  int _totalMovimentos = 0;
  Map<String, dynamic>? _resumo;
  bool _isLoading = false;
  String? _error;

  CaixasProvider(this._api);

  List<Caixa> get caixas => _caixas;
  Caixa? get caixaSelecionada => _caixaSelecionada;
  List<CaixaMovimento> get movimentos => _movimentos;
  int get totalMovimentos => _totalMovimentos;
  Map<String, dynamic>? get resumo => _resumo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> carregarCaixas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.get(ApiConfig.caixas);
      final data = result['data'] as List;
      _caixas = data.map((e) => Caixa.fromJson(e as Map<String, dynamic>)).toList();
      if (_caixaSelecionada != null) {
        // Refresh selected caixa from the new list to avoid stale status
        final id = _caixaSelecionada!.id;
        _caixaSelecionada = _caixas.firstWhere(
          (c) => c.id == id,
          orElse: () => _caixas.first,
        );
      } else if (_caixas.isNotEmpty) {
        _caixaSelecionada = _caixas.first;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void selecionarCaixa(Caixa caixa) {
    _caixaSelecionada = caixa;
    notifyListeners();
  }

  Future<void> carregarMovimentos({int? caixaId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final id = caixaId ?? _caixaSelecionada?.id;
      final params = <String, String>{};
      if (id != null) params['caixa_id'] = id.toString();
      final result = await _api.get(ApiConfig.caixaMovimentos, queryParams: params);
      final data = result['data'] as List;
      _movimentos = data.map((e) => CaixaMovimento.fromJson(e as Map<String, dynamic>)).toList();
      _totalMovimentos = result['total'] as int? ?? _movimentos.length;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> carregarResumo(int caixaId) async {
    _error = null;
    try {
      final result = await _api.get(ApiConfig.caixaResumo(caixaId));
      _resumo = result['data'] as Map<String, dynamic>?;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> lancamento({
    required int caixaId,
    required String tipo,
    required double valor,
    required String descricao,
  }) async {
    _error = null;
    try {
      await _api.post(ApiConfig.caixaLancamento, body: {
        'caixa_id': caixaId,
        'tipo': tipo,
        'valor': valor,
        'descricao': descricao,
      });
      await carregarCaixas();
      await carregarMovimentos(caixaId: caixaId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> transferencia({
    required int caixaOrigemId,
    required int caixaDestinoId,
    required double valor,
    String? descricao,
  }) async {
    _error = null;
    try {
      await _api.post(ApiConfig.caixaTransferencia, body: {
        'caixa_origem_id': caixaOrigemId,
        'caixa_destino_id': caixaDestinoId,
        'valor': valor,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
      });
      await carregarCaixas();
      await carregarMovimentos(caixaId: caixaOrigemId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> carregarFechamento(
    int caixaId, {
    String? dataInicio,
    String? dataFim,
  }) async {
    try {
      final params = <String, String>{};
      if (dataInicio != null) params['data_inicio'] = dataInicio;
      if (dataFim != null) params['data_fim'] = dataFim;
      final result = await _api.get(
        ApiConfig.caixaFechamento(caixaId),
        queryParams: params,
      );
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> importarCsvBatch({
    required int caixaId,
    required List<Map<String, dynamic>> itens,
  }) async {
    try {
      final result = await _api.post(ApiConfig.caixaLancamentoBatch, body: {
        'caixa_id': caixaId,
        'itens': itens,
      });
      await carregarCaixas();
      await carregarMovimentos(caixaId: caixaId);
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> abrirCaixa({
    required int caixaId,
    required double valorInicial,
  }) async {
    _error = null;
    try {
      await _api.post(ApiConfig.caixaAbrir(caixaId), body: {
        'valor_inicial': valorInicial,
      });
      await carregarCaixas();
      await carregarMovimentos(caixaId: caixaId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> fecharCaixa({
    required int caixaId,
    required String dataInicio,
    required String dataFim,
    double? saldoInformado,
    String? observacoes,
  }) async {
    _error = null;
    try {
      final body = <String, dynamic>{
        'data_inicio': dataInicio,
        'data_fim': dataFim,
      };
      if (saldoInformado != null) body['saldo_informado'] = saldoInformado;
      if (observacoes != null && observacoes.isNotEmpty) {
        body['observacoes'] = observacoes;
      }
      final result = await _api.post(ApiConfig.caixaFechar(caixaId), body: body);
      await carregarCaixas();
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> carregarFechamentos(int caixaId) async {
    try {
      final result = await _api.get(ApiConfig.caixaFechamentos(caixaId));
      final data = result['data'] as List?;
      return data?.cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
