import 'auth_repository.dart';
import '../../core/helpers/password_hasher.dart';
import '../../core/helpers/token_manager.dart';
import '../../core/exceptions/api_exception.dart';

class AuthService {
  final AuthRepository _repository;

  AuthService(this._repository);

  Future<Map<String, dynamic>> login(String login, String senha) async {
    final usuario = await _repository.findByLogin(login);

    if (usuario == null) {
      throw UnauthorizedException('Usuário não encontrado');
    }

    final senhaValida = PasswordHasher.verify(senha, usuario['senha_hash']!);

    if (!senhaValida) {
      throw UnauthorizedException('Senha incorreta');
    }

    final userId = int.parse(usuario['id']!);
    final papel = usuario['papel']!;
    final token = TokenManager.generateToken(userId, papel);

    return {
      'token': token,
      'usuario': {
        'id': userId,
        'nome': usuario['nome'],
        'login': usuario['login'],
        'papel': usuario['papel'],
        'perm_pdv': int.tryParse(usuario['perm_pdv'] ?? '1') ?? 1,
        'perm_produtos': int.tryParse(usuario['perm_produtos'] ?? '0') ?? 0,
        'perm_estoque': int.tryParse(usuario['perm_estoque'] ?? '0') ?? 0,
        'perm_vendas': int.tryParse(usuario['perm_vendas'] ?? '0') ?? 0,
        'perm_compras': int.tryParse(usuario['perm_compras'] ?? '0') ?? 0,
        'perm_clientes': int.tryParse(usuario['perm_clientes'] ?? '1') ?? 1,
        'perm_fornecedores': int.tryParse(usuario['perm_fornecedores'] ?? '0') ?? 0,
        'perm_categorias': int.tryParse(usuario['perm_categorias'] ?? '0') ?? 0,
        'perm_caixa': int.tryParse(usuario['perm_caixa'] ?? '0') ?? 0,
        'perm_contas_receber': int.tryParse(usuario['perm_contas_receber'] ?? '0') ?? 0,
        'perm_contas_pagar': int.tryParse(usuario['perm_contas_pagar'] ?? '0') ?? 0,
        'perm_crediario': int.tryParse(usuario['perm_crediario'] ?? '0') ?? 0,
        'perm_servicos': int.tryParse(usuario['perm_servicos'] ?? '0') ?? 0,
        'perm_ordens_servico': int.tryParse(usuario['perm_ordens_servico'] ?? '0') ?? 0,
        'perm_devolucoes': int.tryParse(usuario['perm_devolucoes'] ?? '0') ?? 0,
        'perm_relatorios': int.tryParse(usuario['perm_relatorios'] ?? '0') ?? 0,
        'max_desconto': double.tryParse(usuario['max_desconto'] ?? '0') ?? 0.0,
      },
    };
  }

  Future<void> logout(String token) async {
    TokenManager.revokeToken(token);
  }

  Future<bool> validarAdmin(String login, String senha) async {
    final admin = await _repository.findAdminByLogin(login);

    if (admin == null) {
      throw UnauthorizedException('Administrador não encontrado');
    }

    final senhaValida = PasswordHasher.verify(senha, admin['senha_hash']!);

    if (!senhaValida) {
      throw UnauthorizedException('Senha incorreta');
    }

    return true;
  }

  Future<void> alterarSenha(
    int userId,
    String senhaAtual,
    String novaSenha,
  ) async {
    final usuario = await _repository.findById(userId);

    if (usuario == null) {
      throw NotFoundException('Usuário não encontrado');
    }

    final senhaValida = PasswordHasher.verify(senhaAtual, usuario['senha_hash']!);

    if (!senhaValida) {
      throw UnauthorizedException('Senha atual incorreta');
    }

    final novoHash = PasswordHasher.hash(novaSenha);
    await _repository.updatePassword(userId, novoHash);
  }
}
