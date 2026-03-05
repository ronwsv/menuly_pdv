import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient apiClient;
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userPapelKey = 'user_papel';
  static const _maxDescontoKey = 'user_max_desconto';

  static const _permKeyMap = {
    'perm_pdv': 'user_perm_pdv',
    'perm_produtos': 'user_perm_produtos',
    'perm_estoque': 'user_perm_estoque',
    'perm_vendas': 'user_perm_vendas',
    'perm_compras': 'user_perm_compras',
    'perm_clientes': 'user_perm_clientes',
    'perm_fornecedores': 'user_perm_fornecedores',
    'perm_categorias': 'user_perm_categorias',
    'perm_caixa': 'user_perm_caixa',
    'perm_contas_receber': 'user_perm_contas_receber',
    'perm_contas_pagar': 'user_perm_contas_pagar',
    'perm_crediario': 'user_perm_crediario',
    'perm_servicos': 'user_perm_servicos',
    'perm_ordens_servico': 'user_perm_ordens_servico',
    'perm_devolucoes': 'user_perm_devolucoes',
    'perm_relatorios': 'user_perm_relatorios',
  };

  AuthService(this.apiClient);

  static bool _toBool(dynamic v) => v == 1 || v == '1' || v == true;

  Future<Map<String, dynamic>> login(String login, String senha) async {
    final result = await apiClient.post(ApiConfig.login, body: {
      'login': login,
      'senha': senha,
    });

    final data = result['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final usuario = data['usuario'] as Map<String, dynamic>;

    apiClient.setToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_userIdKey, usuario['id'] as int);
    await prefs.setString(_userNameKey, usuario['nome'] as String);
    await prefs.setString(_userPapelKey, usuario['papel'] as String);
    for (final entry in _permKeyMap.entries) {
      await prefs.setBool(entry.value, _toBool(usuario[entry.key]));
    }
    await prefs.setDouble(
        _maxDescontoKey, (usuario['max_desconto'] as num?)?.toDouble() ?? 0.0);

    return data;
  }

  Future<void> logout() async {
    try {
      await apiClient.post(ApiConfig.logout);
    } catch (_) {}
    apiClient.setToken(null);
    await _clearSavedData();
  }

  Future<bool> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return false;
    apiClient.setToken(token);

    // Valida se o token ainda é aceito pelo backend
    try {
      await apiClient.get(ApiConfig.emitente);
      return true;
    } catch (_) {
      // Token expirado ou servidor reiniciou — limpa sessão
      apiClient.setToken(null);
      await _clearSavedData();
      return false;
    }
  }

  Future<void> _clearSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userPapelKey);
    await prefs.remove(_maxDescontoKey);
    for (final prefsKey in _permKeyMap.values) {
      await prefs.remove(prefsKey);
    }
  }

  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_userIdKey);
    final nome = prefs.getString(_userNameKey);
    final papel = prefs.getString(_userPapelKey);
    if (id == null || nome == null) return null;
    final user = <String, dynamic>{
      'id': id,
      'nome': nome,
      'papel': papel ?? 'operador',
      'max_desconto': prefs.getDouble(_maxDescontoKey) ?? 0.0,
    };
    for (final entry in _permKeyMap.entries) {
      user[entry.key] = prefs.getBool(entry.value) ?? false;
    }
    return user;
  }
}
