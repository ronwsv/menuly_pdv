import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';

class RelatoriosProvider extends ChangeNotifier {
  final ApiClient _api;

  Map<String, dynamic> _vendasResumo = {};
  List<Map<String, dynamic>> _produtosMaisVendidos = [];
  bool _isLoading = false;
  String? _error;

  RelatoriosProvider(this._api);

  Map<String, dynamic> get vendasResumo => _vendasResumo;
  List<Map<String, dynamic>> get produtosMaisVendidos => _produtosMaisVendidos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> carregarResumoVendas({String? periodo}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (periodo != null && periodo.isNotEmpty) params['periodo'] = periodo;

      final result = await _api.get(ApiConfig.vendas, queryParams: params);
      final vendas = result['data'] as List;

      double totalVendas = 0;
      int quantidadeVendas = 0;
      double ticketMedio = 0;

      for (final venda in vendas) {
        final map = venda as Map<String, dynamic>;
        final total = _parseDouble(map['total']);
        totalVendas += total;
        quantidadeVendas++;
      }

      if (quantidadeVendas > 0) {
        ticketMedio = totalVendas / quantidadeVendas;
      }

      _vendasResumo = {
        'total_vendas': totalVendas,
        'quantidade_vendas': quantidadeVendas,
        'ticket_medio': ticketMedio,
      };
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> carregarProdutosMaisVendidos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.get(ApiConfig.estoquePosicao);
      final posicao = (result['data'] as List).cast<Map<String, dynamic>>();

      // Sort by movement (lower stock relative to minimum suggests higher sales)
      final produtosResult = await _api.get(ApiConfig.produtos, queryParams: {'limit': '100'});
      final produtos = (produtosResult['data'] as List).cast<Map<String, dynamic>>();

      // Build a map of stock positions by product id
      final estoqueMap = <int, Map<String, dynamic>>{};
      for (final item in posicao) {
        final id = _parseInt(item['produto_id'] ?? item['id']);
        estoqueMap[id] = item;
      }

      // Combine product info with stock data for reporting
      _produtosMaisVendidos = produtos.map((p) {
        final id = _parseInt(p['id']);
        final estoque = estoqueMap[id];
        return {
          'id': id,
          'descricao': p['descricao'],
          'preco_venda': p['preco_venda'],
          'estoque_atual': estoque?['estoque_atual'] ?? p['estoque_atual'] ?? 0,
          'categoria_nome': p['categoria_nome'],
        };
      }).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
