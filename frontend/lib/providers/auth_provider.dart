import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _token;
  Map<String, dynamic>? _usuario;
  String? _error;

  AuthProvider(this._authService) {
    _init();
  }

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  Map<String, dynamic>? get usuario => _usuario;
  String? get error => _error;
  String get nomeUsuario => _usuario?['nome']?.toString() ?? 'Operador';
  String get papelUsuario => _usuario?['papel']?.toString() ?? 'operador';

  // Permission getters
  bool get permPdv => _permBool('perm_pdv');
  bool get permProdutos => _permBool('perm_produtos');
  bool get permEstoque => _permBool('perm_estoque');
  bool get permVendas => _permBool('perm_vendas');
  bool get permCompras => _permBool('perm_compras');
  bool get permClientes => _permBool('perm_clientes');
  bool get permFornecedores => _permBool('perm_fornecedores');
  bool get permCategorias => _permBool('perm_categorias');
  bool get permCaixa => _permBool('perm_caixa');
  bool get permContasReceber => _permBool('perm_contas_receber');
  bool get permContasPagar => _permBool('perm_contas_pagar');
  bool get permCrediario => _permBool('perm_crediario');
  bool get permServicos => _permBool('perm_servicos');
  bool get permOrdensServico => _permBool('perm_ordens_servico');
  bool get permDevolucoes => _permBool('perm_devolucoes');
  bool get permRelatorios => _permBool('perm_relatorios');
  double get maxDesconto =>
      (_usuario?['max_desconto'] as num?)?.toDouble() ?? 0.0;

  bool _permBool(String key) {
    final v = _usuario?[key];
    return v == true || v == 1 || v == '1';
  }

  /// Returns true if the current user can access the menu at [index].
  bool temPermissaoMenu(int index) {
    final papel = papelUsuario;

    // Admin: everything
    if (papel == 'admin') return true;

    // Gerente: everything except Configuracoes
    if (papel == 'gerente') return index != 17;

    // Operador / Vendedor: each module has its own permission
    // PDV é sempre acessível — é a ferramenta essencial de vendas
    return switch (index) {
      0 => true, // Dashboard
      1 => true, // PDV (sempre acessível para vender)
      2 => permProdutos, // Produtos
      3 => permEstoque, // Estoque
      4 => permVendas, // Vendas
      5 => permCompras, // Compras
      6 => permClientes, // Clientes
      7 => permFornecedores, // Fornecedores
      8 => permCategorias, // Categorias
      9 => permCaixa, // Caixas
      10 => permContasReceber, // Contas a Receber
      11 => permContasPagar, // Contas a Pagar
      12 => permCrediario, // Crediario
      13 => permServicos, // Servicos
      14 => permOrdensServico, // Ordens de Servico
      15 => permDevolucoes, // Devolucoes
      16 => permRelatorios, // Relatorios
      17 => false, // Configuracoes (admin only)
      _ => false,
    };
  }

  Future<void> _init() async {
    final restored = await _authService.tryRestoreSession();
    if (restored) {
      _usuario = await _authService.getSavedUser();
      _isAuthenticated = _usuario != null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String login, String senha) async {
    _error = null;
    // Não chamar notifyListeners() aqui — causa rebuild do Consumer
    // no app.dart que recria LoginScreen e limpa os campos de texto.

    try {
      final data = await _authService.login(login, senha);
      _token = data['token'] as String?;
      final usuario = data['usuario'] as Map<String, dynamic>?;
      // Normalize permission values to bool for consistency
      if (usuario != null) {
        for (final key in [
          'perm_pdv', 'perm_produtos', 'perm_estoque', 'perm_vendas',
          'perm_compras', 'perm_clientes', 'perm_fornecedores',
          'perm_categorias', 'perm_caixa', 'perm_contas_receber',
          'perm_contas_pagar', 'perm_crediario', 'perm_servicos',
          'perm_ordens_servico', 'perm_devolucoes', 'perm_relatorios',
        ]) {
          usuario[key] = _normBool(usuario[key]);
        }
      }
      _usuario = usuario;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  static bool _normBool(dynamic v) => v == 1 || v == '1' || v == true;

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _token = null;
    _usuario = null;
    notifyListeners();
  }
}
