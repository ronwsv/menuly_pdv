import 'categorias_repository.dart';
import 'categoria_model.dart';
import '../../core/exceptions/api_exception.dart';

class CategoriasService {
  final CategoriasRepository _repository;

  CategoriasService(this._repository);

  Future<List<Map<String, dynamic>>> listar() async {
    final rows = await _repository.findAll();

    return rows.map((row) => Categoria.fromRow(row).toJson()).toList();
  }

  Future<Map<String, dynamic>> obterPorId(int id) async {
    final row = await _repository.findById(id);

    if (row == null) {
      throw NotFoundException('Categoria não encontrada');
    }

    return Categoria.fromRow(row).toJson();
  }

  Future<Map<String, dynamic>> criar(Map<String, dynamic> data) async {
    final nome = data['nome'] as String?;

    if (nome == null || nome.trim().isEmpty) {
      throw ValidationException('O campo nome é obrigatório');
    }

    final existe = await _repository.existsByNome(nome);

    if (existe) {
      throw ValidationException('Já existe uma categoria com este nome');
    }

    final descricao = data['descricao'] as String?;
    final id = await _repository.create(nome, descricao);

    final criada = await _repository.findById(id);
    return Categoria.fromRow(criada!).toJson();
  }

  Future<Map<String, dynamic>> atualizar(int id, Map<String, dynamic> data) async {
    final existing = await _repository.findById(id);

    if (existing == null) {
      throw NotFoundException('Categoria não encontrada');
    }

    if (data.containsKey('nome')) {
      final nome = data['nome'] as String;
      final existe = await _repository.existsByNome(nome, excludeId: id);

      if (existe) {
        throw ValidationException('Já existe uma categoria com este nome');
      }
    }

    await _repository.update(id, data);

    final atualizada = await _repository.findById(id);
    return Categoria.fromRow(atualizada!).toJson();
  }

  Future<void> excluir(int id) async {
    final existing = await _repository.findById(id);

    if (existing == null) {
      throw NotFoundException('Categoria não encontrada');
    }

    await _repository.delete(id);
  }
}
