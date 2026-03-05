import 'clientes_repository.dart';
import 'cliente_model.dart';
import '../../core/exceptions/api_exception.dart';

class ClientesService {
  final ClientesRepository _repository;

  ClientesService(this._repository);

  static const _allowedFields = [
    'nome',
    'tipo_pessoa',
    'cpf_cnpj',
    'inscricao_estadual',
    'telefone',
    'email',
    'cep',
    'endereco',
    'numero',
    'bairro',
    'cidade',
    'estado',
    'limite_credito',
    'outros_dados',
  ];

  Future<Map<String, dynamic>> listar(Map<String, dynamic> params) async {
    final busca = params['busca'] as String?;
    final ativo = params['ativo'] as bool?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final rows = await _repository.findAll(
      busca: busca,
      ativo: ativo,
      limit: limit,
      offset: offset,
    );

    final total = await _repository.count(
      busca: busca,
      ativo: ativo,
    );

    return {
      'items': rows.map((row) => Cliente.fromRow(row).toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> obterPorId(int id) async {
    final row = await _repository.findById(id);

    if (row == null) {
      throw NotFoundException('Cliente não encontrado');
    }

    return Cliente.fromRow(row).toJson();
  }

  Future<Map<String, dynamic>> criar(Map<String, dynamic> data) async {
    final nome = data['nome'] as String?;

    if (nome == null || nome.trim().isEmpty) {
      throw ValidationException('O campo nome é obrigatório');
    }

    // Verificar CPF/CNPJ único se fornecido
    final cpfCnpj = data['cpf_cnpj'] as String?;
    if (cpfCnpj != null && cpfCnpj.isNotEmpty) {
      final existente = await _repository.findByCpfCnpj(cpfCnpj);
      if (existente != null) {
        throw ValidationException('Já existe um cliente com este CPF/CNPJ');
      }
    }

    // Montar dados para inserção
    final dbData = <String, String>{};

    for (final field in _allowedFields) {
      if (data.containsKey(field) && data[field] != null) {
        dbData[field] = data[field].toString();
      }
    }

    final id = await _repository.create(dbData);

    final criado = await _repository.findById(id);
    return Cliente.fromRow(criado!).toJson();
  }

  Future<Map<String, dynamic>> atualizar(int id, Map<String, dynamic> data) async {
    final existing = await _repository.findById(id);

    if (existing == null) {
      throw NotFoundException('Cliente não encontrado');
    }

    // Verificar CPF/CNPJ único se está sendo alterado
    if (data.containsKey('cpf_cnpj')) {
      final cpfCnpj = data['cpf_cnpj'] as String?;
      if (cpfCnpj != null && cpfCnpj.isNotEmpty) {
        final existente = await _repository.findByCpfCnpj(cpfCnpj);
        if (existente != null && int.parse(existente['id']!) != id) {
          throw ValidationException('Já existe um cliente com este CPF/CNPJ');
        }
      }
    }

    // Filtrar apenas campos permitidos
    final updateData = <String, dynamic>{};

    for (final field in _allowedFields) {
      if (data.containsKey(field)) {
        updateData[field] = data[field]?.toString();
      }
    }

    if (updateData.isNotEmpty) {
      await _repository.update(id, updateData);
    }

    final atualizado = await _repository.findById(id);
    return Cliente.fromRow(atualizado!).toJson();
  }

  Future<void> excluir(int id) async {
    final existing = await _repository.findById(id);

    if (existing == null) {
      throw NotFoundException('Cliente não encontrado');
    }

    await _repository.delete(id);
  }
}
