import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/compra.dart';

class ComprasProvider extends ChangeNotifier {
  final ApiClient _api;

  List<Compra> _compras = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = false;
  String? _error;
  int? _fornecedorId;
  String? _dataInicio;
  String? _dataFim;

  ComprasProvider(this._api);

  List<Compra> get compras => _compras;
  int get total => _total;
  int get page => _page;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setFiltros({int? fornecedorId, String? dataInicio, String? dataFim}) {
    _fornecedorId = fornecedorId;
    _dataInicio = dataInicio;
    _dataFim = dataFim;
  }

  Future<void> carregarCompras([int page = 1]) async {
    _isLoading = true;
    _error = null;
    _page = page;
    notifyListeners();

    try {
      final params = <String, String>{
        'page': page.toString(),
        'per_page': '50',
      };
      if (_fornecedorId != null) {
        params['fornecedor_id'] = _fornecedorId.toString();
      }
      if (_dataInicio != null) params['data_inicio'] = _dataInicio!;
      if (_dataFim != null) params['data_fim'] = _dataFim!;

      final result = await _api.get(ApiConfig.compras, queryParams: params);
      final data = result['data'] as List;
      _compras =
          data.map((e) => Compra.fromJson(e as Map<String, dynamic>)).toList();
      _total = result['total'] as int? ?? _compras.length;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Compra> obterCompra(int id) async {
    final result = await _api.get(ApiConfig.compraById(id));
    return Compra.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<void> criarCompra(Map<String, dynamic> data) async {
    await _api.post(ApiConfig.compras, body: data);
    await carregarCompras();
  }

  Future<void> atualizarCompra(int id, Map<String, dynamic> data) async {
    await _api.put(ApiConfig.compraById(id), body: data);
    await carregarCompras();
  }

  Future<void> excluirCompra(int id) async {
    await _api.delete(ApiConfig.compraById(id));
    await carregarCompras();
  }

  Future<Map<String, dynamic>> importarXml(String xmlContent) async {
    final result = await _api.post(
      ApiConfig.comprasImportarXml,
      body: {'xml_content': xmlContent},
    );
    return result['data'] as Map<String, dynamic>;
  }
}
