import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/produto.dart';

class CartItem {
  final int produtoId;
  final String descricao;
  final String? codigoBarras;
  final double precoVenda;
  final double? precoAtacado;
  final int? qtdMinimaAtacado;
  int quantidade;
  final String unidade;

  CartItem({
    required this.produtoId,
    required this.descricao,
    this.codigoBarras,
    required this.precoVenda,
    this.precoAtacado,
    this.qtdMinimaAtacado,
    this.quantidade = 1,
    this.unidade = 'un',
  });

  bool get isAtacado =>
      precoAtacado != null &&
      precoAtacado! > 0 &&
      qtdMinimaAtacado != null &&
      qtdMinimaAtacado! > 0 &&
      quantidade >= qtdMinimaAtacado!;

  double get precoUnitario => isAtacado ? precoAtacado! : precoVenda;

  double get subtotal => precoUnitario * quantidade;
}

class PdvProvider extends ChangeNotifier {
  final ApiClient _api;

  final List<CartItem> _itens = [];
  double _desconto = 0;
  bool _descontoPercentual = false;
  Produto? _produtoAtual;
  String? _error;
  bool _isLoading = false;

  Map<String, dynamic>? _emitente;

  // Crediario
  int? _clienteId;
  String? _clienteNome;

  // Vendedor
  int? _vendedorId;
  String? _vendedorNome;

  PdvProvider(this._api);

  Map<String, dynamic>? get emitente => _emitente;
  int? get clienteId => _clienteId;
  String? get clienteNome => _clienteNome;
  int? get vendedorId => _vendedorId;
  String? get vendedorNome => _vendedorNome;
  List<CartItem> get itens => List.unmodifiable(_itens);
  int get totalItens => _itens.fold(0, (sum, item) => sum + item.quantidade);
  double get subtotal => _itens.fold(0.0, (sum, item) => sum + item.subtotal);
  double get descontoValor {
    if (_descontoPercentual) {
      return subtotal * (_desconto / 100);
    }
    return _desconto;
  }
  double get total => (subtotal - descontoValor).clamp(0, double.infinity);
  double get desconto => _desconto;
  bool get descontoPercentual => _descontoPercentual;
  Produto? get produtoAtual => _produtoAtual;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isEmpty => _itens.isEmpty;

  Future<void> carregarEmitente() async {
    try {
      final result = await _api.get(ApiConfig.emitente);
      _emitente = result['data'] as Map<String, dynamic>?;
    } catch (_) {}
  }

  Future<Produto?> buscarProdutoPorBarcode(String codigo) async {
    _error = null;
    try {
      final result = await _api.get(ApiConfig.produtoByBarcode(codigo));
      final data = result['data'] as Map<String, dynamic>;
      return Produto.fromJson(data);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<List<Produto>> buscarProdutos(String busca) async {
    try {
      debugPrint('[PDV] buscarProdutos("$busca") token=${_api.token != null ? "SET" : "NULL"}');
      final result = await _api.get(ApiConfig.produtos, queryParams: {'busca': busca, 'ativo': '1'});
      final data = result['data'] as List;
      debugPrint('[PDV] buscarProdutos retornou ${data.length} resultados');
      return data.map((e) => Produto.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[PDV] buscarProdutos ERRO: $e');
      _error = 'Erro ao buscar produtos: $e';
      notifyListeners();
      return [];
    }
  }

  void adicionarProduto(Produto produto, {int quantidade = 1}) {
    final existente = _itens.indexWhere((item) => item.produtoId == produto.id);
    if (existente >= 0) {
      _itens[existente].quantidade += quantidade;
    } else {
      _itens.add(CartItem(
        produtoId: produto.id,
        descricao: produto.descricao,
        codigoBarras: produto.codigoBarras,
        precoVenda: produto.precoVenda,
        precoAtacado: produto.precoAtacado,
        qtdMinimaAtacado: produto.qtdMinimaAtacado,
        quantidade: quantidade,
        unidade: produto.unidade,
      ));
    }
    _produtoAtual = produto;
    notifyListeners();
  }

  void removerUltimoItem() {
    if (_itens.isNotEmpty) {
      _itens.removeLast();
      _produtoAtual = null;
      notifyListeners();
    }
  }

  void removerItem(int index) {
    if (index >= 0 && index < _itens.length) {
      _itens.removeAt(index);
      if (_itens.isEmpty) _produtoAtual = null;
      notifyListeners();
    }
  }

  void alterarQuantidade(int index, int novaQuantidade) {
    if (index >= 0 && index < _itens.length && novaQuantidade > 0) {
      _itens[index].quantidade = novaQuantidade;
      notifyListeners();
    }
  }

  void aplicarDesconto(double valor, {bool percentual = false}) {
    _desconto = valor;
    _descontoPercentual = percentual;
    notifyListeners();
  }

  void setCliente(int id, String nome) {
    _clienteId = id;
    _clienteNome = nome;
    notifyListeners();
  }

  void limparCliente() {
    _clienteId = null;
    _clienteNome = null;
    notifyListeners();
  }

  void setVendedor(int id, String nome) {
    _vendedorId = id;
    _vendedorNome = nome;
    notifyListeners();
  }

  void limparVendedor() {
    _vendedorId = null;
    _vendedorNome = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> verificarLimiteCrediario(int clienteId) async {
    try {
      final result = await _api.get(ApiConfig.crediarioLimiteCliente(clienteId));
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  void limparCarrinho() {
    _itens.clear();
    _desconto = 0;
    _descontoPercentual = false;
    _produtoAtual = null;
    _clienteId = null;
    _clienteNome = null;
    _vendedorId = null;
    _vendedorNome = null;
    _error = null;
    notifyListeners();
  }

  /// Importa itens de um orçamento para o carrinho (substitui itens atuais).
  void importarOrcamento({
    required List<Map<String, dynamic>> itens,
    int? clienteId,
    String? clienteNome,
    double desconto = 0,
  }) {
    _itens.clear();
    for (final item in itens) {
      final prodId = item['produto_id'];
      if (prodId == null) continue;
      _itens.add(CartItem(
        produtoId: prodId is int ? prodId : int.tryParse(prodId.toString()) ?? 0,
        descricao: item['produto_descricao']?.toString() ?? item['descricao']?.toString() ?? '',
        precoVenda: _toDouble(item['preco_unitario']),
        precoAtacado: item['preco_atacado'] != null ? _toDouble(item['preco_atacado']) : null,
        qtdMinimaAtacado: item['qtd_minima_atacado'] != null ? _toInt(item['qtd_minima_atacado']) : null,
        quantidade: _toInt(item['quantidade']),
        unidade: item['unidade']?.toString() ?? 'un',
      ));
    }
    _desconto = desconto;
    _descontoPercentual = false;
    if (clienteId != null) {
      _clienteId = clienteId;
      _clienteNome = clienteNome;
    }
    _produtoAtual = null;
    _error = null;
    notifyListeners();
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 1;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 1;
  }

  Future<Map<String, dynamic>?> finalizarVenda({
    required List<Map<String, dynamic>> pagamentos,
    double? valorRecebido,
    int caixaId = 1,
    int? crediarioParcelas,
  }) async {
    if (_itens.isEmpty) return null;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'tipo': 'Venda',
        'caixa_id': caixaId,
        'desconto_valor': descontoValor,
        'pagamentos': pagamentos,
        'itens': _itens.map((item) => {
          'produto_id': item.produtoId,
          'quantidade': item.quantidade,
          'preco_unitario': item.precoUnitario,
          'is_atacado': item.isAtacado,
        }).toList(),
      };
      if (valorRecebido != null) {
        body['valor_recebido'] = valorRecebido;
      }
      if (_clienteId != null) {
        body['cliente_id'] = _clienteId;
      }
      if (_vendedorId != null) {
        body['vendedor_id'] = _vendedorId;
      }
      final temCrediario =
          pagamentos.any((p) => p['forma_pagamento'] == 'crediario');
      if (temCrediario && crediarioParcelas != null) {
        body['crediario_parcelas'] = crediarioParcelas;
      }

      final result = await _api.post(ApiConfig.vendas, body: body);
      limparCarrinho();
      _isLoading = false;
      notifyListeners();
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> salvarOrcamento() async {
    if (_itens.isEmpty) return null;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'tipo': 'Orcamento',
        'desconto_valor': descontoValor,
        'itens': _itens.map((item) => {
          'produto_id': item.produtoId,
          'quantidade': item.quantidade,
          'preco_unitario': item.precoUnitario,
          'is_atacado': item.isAtacado,
        }).toList(),
      };
      if (_clienteId != null) {
        body['cliente_id'] = _clienteId;
      }
      if (_vendedorId != null) {
        body['vendedor_id'] = _vendedorId;
      }

      final result = await _api.post(ApiConfig.vendas, body: body);
      limparCarrinho();
      _isLoading = false;
      notifyListeners();
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
