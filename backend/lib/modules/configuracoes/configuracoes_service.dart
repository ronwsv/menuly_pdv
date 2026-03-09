import 'configuracoes_repository.dart';
import 'configuracao_model.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/helpers/password_hasher.dart';

class ConfiguracoesService {
  final ConfiguracoesRepository _repository;

  ConfiguracoesService(this._repository);

  // ─── Configuracoes ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listarConfigs({String? grupo}) async {
    final rows = await _repository.findAll(grupo: grupo);

    return rows.map((row) => Configuracao.fromRow(row).toJson()).toList();
  }

  Future<Map<String, dynamic>> obterConfig(String chave) async {
    final row = await _repository.findByChave(chave);

    if (row == null) {
      throw NotFoundException('Configuracao nao encontrada');
    }

    return Configuracao.fromRow(row).toJson();
  }

  Future<Map<String, dynamic>> salvarConfig(Map<String, dynamic> data) async {
    final chave = data['chave'] as String?;

    if (chave == null || chave.trim().isEmpty) {
      throw ValidationException('O campo chave e obrigatorio');
    }

    final valor = data['valor'] as String?;
    final grupo = data['grupo'] as String?;
    final descricao = data['descricao'] as String?;

    await _repository.upsert(chave, valor, grupo: grupo, descricao: descricao);

    final salva = await _repository.findByChave(chave);
    return Configuracao.fromRow(salva!).toJson();
  }

  Future<List<Map<String, dynamic>>> salvarConfigs(
      List<Map<String, dynamic>> configs) async {
    final resultados = <Map<String, dynamic>>[];

    for (final data in configs) {
      final resultado = await salvarConfig(data);
      resultados.add(resultado);
    }

    return resultados;
  }

  /// Converte um valor para string compatível com MySQL.
  /// Booleans viram '1'/'0' para colunas TINYINT.
  static String _toDbStr(dynamic value) {
    if (value is bool) return value ? '1' : '0';
    return value.toString();
  }

  // ─── Usuarios ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listarUsuarios() async {
    final rows = await _repository.findAllUsuarios();

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row);
      map.remove('senha_hash');
      return map;
    }).toList();
  }

  Future<Map<String, dynamic>> obterUsuario(int id) async {
    final row = await _repository.findUsuarioById(id);

    if (row == null) {
      throw NotFoundException('Usuario nao encontrado');
    }

    final map = Map<String, dynamic>.from(row);
    map.remove('senha_hash');
    return map;
  }

  Future<Map<String, dynamic>> criarUsuario(Map<String, dynamic> data) async {
    final login = data['login'] as String?;

    if (login == null || login.trim().isEmpty) {
      throw ValidationException('O campo login e obrigatorio');
    }

    final senha = data['senha'] as String?;

    if (senha == null || senha.trim().isEmpty) {
      throw ValidationException('O campo senha e obrigatorio');
    }

    final nome = data['nome'] as String?;

    if (nome == null || nome.trim().isEmpty) {
      throw ValidationException('O campo nome e obrigatorio');
    }

    final existe = await _repository.existsByLogin(login);

    if (existe) {
      throw ValidationException('Ja existe um usuario com este login');
    }

    final senhaHash = PasswordHasher.hash(senha);

    final insertData = <String, String>{
      'login': login,
      'senha_hash': senhaHash,
      'nome': nome,
    };

    if (data.containsKey('papel')) {
      insertData['papel'] = data['papel'] as String;
    }
    if (data.containsKey('max_desconto')) {
      insertData['max_desconto'] = data['max_desconto'].toString();
    }
    for (final permKey in [
      'perm_pdv', 'perm_produtos', 'perm_estoque', 'perm_vendas',
      'perm_compras', 'perm_clientes', 'perm_fornecedores', 'perm_categorias',
      'perm_caixa', 'perm_contas_receber', 'perm_contas_pagar',
      'perm_crediario', 'perm_servicos', 'perm_ordens_servico',
      'perm_devolucoes', 'perm_consignacoes', 'perm_relatorios',
    ]) {
      if (data.containsKey(permKey)) {
        insertData[permKey] = _toDbStr(data[permKey]);
      }
    }
    if (data.containsKey('ativo')) {
      insertData['ativo'] = _toDbStr(data['ativo']);
    }
    if (data.containsKey('auto_login')) {
      insertData['auto_login'] = _toDbStr(data['auto_login']);
    }
    if (data.containsKey('comissao_percentual') && data['comissao_percentual'] != null) {
      insertData['comissao_percentual'] = data['comissao_percentual'].toString();
    }

    final id = await _repository.createUsuario(insertData);

    final criado = await _repository.findUsuarioById(id);
    final map = Map<String, dynamic>.from(criado!);
    map.remove('senha_hash');
    return map;
  }

  Future<Map<String, dynamic>> atualizarUsuario(
      int id, Map<String, dynamic> data) async {
    final existing = await _repository.findUsuarioById(id);

    if (existing == null) {
      throw NotFoundException('Usuario nao encontrado');
    }

    if (data.containsKey('login')) {
      final login = data['login'] as String;
      final existe = await _repository.existsByLogin(login, excludeId: id);

      if (existe) {
        throw ValidationException('Ja existe um usuario com este login');
      }
    }

    final updateData = <String, dynamic>{};

    for (final entry in data.entries) {
      if (entry.key == 'id' || entry.key == 'criado_em' || entry.key == 'atualizado_em') continue;
      if (entry.key == 'senha') {
        updateData['senha_hash'] = PasswordHasher.hash(entry.value as String);
      } else if (entry.value == null) {
        updateData[entry.key] = null;
      } else if (entry.value is bool) {
        updateData[entry.key] = (entry.value as bool) ? '1' : '0';
      } else {
        updateData[entry.key] = entry.value.toString();
      }
    }

    await _repository.updateUsuario(id, updateData);

    final atualizado = await _repository.findUsuarioById(id);
    final map = Map<String, dynamic>.from(atualizado!);
    map.remove('senha_hash');
    return map;
  }
}
