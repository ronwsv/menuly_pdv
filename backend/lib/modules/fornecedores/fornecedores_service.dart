import 'fornecedores_repository.dart';
import 'fornecedor_model.dart';
import '../../core/exceptions/api_exception.dart';

class FornecedoresService {
  final FornecedoresRepository _repository;

  FornecedoresService(this._repository);

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
      'items': rows.map((row) => Fornecedor.fromRow(row).toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> obterPorId(int id) async {
    final row = await _repository.findById(id);

    if (row == null) {
      throw NotFoundException('Fornecedor não encontrado');
    }

    return Fornecedor.fromRow(row).toJson();
  }

  Future<Map<String, dynamic>> criar(Map<String, dynamic> data) async {
    final razaoSocial = data['razao_social'] as String?;

    if (razaoSocial == null || razaoSocial.trim().isEmpty) {
      throw ValidationException('O campo razão social é obrigatório');
    }

    final cnpj = data['cnpj'] as String?;

    if (cnpj != null && cnpj.trim().isNotEmpty) {
      final existe = await _repository.existsByCnpj(cnpj);

      if (existe) {
        throw ValidationException('Já existe um fornecedor com este CNPJ');
      }
    }

    final allowedFields = [
      'razao_social',
      'nome_fantasia',
      'cnpj',
      'inscricao_estadual',
      'inscricao_municipal',
      'telefone',
      'email',
      'contato',
      'endereco',
      'numero',
      'bairro',
      'cidade',
      'estado',
      'cep',
      'observacoes',
    ];

    final dbData = <String, String>{};

    for (final field in allowedFields) {
      if (data.containsKey(field) && data[field] != null) {
        dbData[field] = data[field].toString();
      }
    }

    final id = await _repository.create(dbData);

    final criado = await _repository.findById(id);
    return Fornecedor.fromRow(criado!).toJson();
  }

  Future<Map<String, dynamic>> atualizar(
      int id, Map<String, dynamic> data) async {
    final existing = await _repository.findById(id);

    if (existing == null) {
      throw NotFoundException('Fornecedor não encontrado');
    }

    if (data.containsKey('cnpj')) {
      final cnpj = data['cnpj'] as String?;

      if (cnpj != null && cnpj.trim().isNotEmpty) {
        final existe = await _repository.existsByCnpj(cnpj, excludeId: id);

        if (existe) {
          throw ValidationException('Já existe um fornecedor com este CNPJ');
        }
      }
    }

    final allowedFields = [
      'razao_social',
      'nome_fantasia',
      'cnpj',
      'inscricao_estadual',
      'inscricao_municipal',
      'telefone',
      'email',
      'contato',
      'endereco',
      'numero',
      'bairro',
      'cidade',
      'estado',
      'cep',
      'observacoes',
    ];

    final dbData = <String, String>{};

    for (final field in allowedFields) {
      if (data.containsKey(field) && data[field] != null) {
        dbData[field] = data[field].toString();
      }
    }

    if (dbData.isNotEmpty) {
      await _repository.update(id, dbData);
    }

    final atualizado = await _repository.findById(id);
    return Fornecedor.fromRow(atualizado!).toJson();
  }

  Future<void> excluir(int id) async {
    final existing = await _repository.findById(id);

    if (existing == null) {
      throw NotFoundException('Fornecedor não encontrado');
    }

    await _repository.delete(id);
  }
}
