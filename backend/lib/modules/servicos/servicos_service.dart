import 'servicos_repository.dart';
import 'servico_model.dart';
import '../../core/exceptions/api_exception.dart';

class ServicosService {
  final ServicosRepository _repository;

  ServicosService(this._repository);

  static const _allowedFields = [
    'descricao',
    'preco',
    'comissao_fixa',
    'outros_dados',
    'ativo',
  ];

  Future<Map<String, dynamic>> listar(Map<String, dynamic> params) async {
    final busca = params['busca'] as String?;
    final ativoStr = params['ativo'] as String?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    bool? ativo;
    if (ativoStr == '1' || ativoStr == 'true') ativo = true;
    if (ativoStr == '0' || ativoStr == 'false') ativo = false;

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
      'items': rows.map((row) => Servico.fromRow(row).toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> obterPorId(int id) async {
    final row = await _repository.findById(id);
    if (row == null) {
      throw NotFoundException('Servico nao encontrado');
    }
    return Servico.fromRow(row).toJson();
  }

  Future<Map<String, dynamic>> criar(Map<String, dynamic> data) async {
    final descricao = data['descricao'] as String?;
    if (descricao == null || descricao.trim().isEmpty) {
      throw ValidationException('Descricao e obrigatoria');
    }

    final preco = data['preco'];
    if (preco == null) {
      throw ValidationException('Preco e obrigatorio');
    }
    final precoNum = preco is num
        ? preco.toDouble()
        : double.tryParse(preco.toString()) ?? 0;
    if (precoNum < 0) {
      throw ValidationException('Preco deve ser positivo');
    }

    final comissao = data['comissao_fixa'];
    final comissaoNum = comissao != null
        ? (comissao is num
            ? comissao.toDouble()
            : double.tryParse(comissao.toString()) ?? 0)
        : 0.0;

    final dbData = <String, String>{
      'descricao': descricao.trim(),
      'preco': precoNum.toStringAsFixed(2),
      'comissao_fixa': comissaoNum.toStringAsFixed(2),
      'ativo': '1',
    };

    if (data['outros_dados'] != null &&
        (data['outros_dados'] as String).isNotEmpty) {
      dbData['outros_dados'] = data['outros_dados'].toString();
    }

    final id = await _repository.create(dbData);
    final criado = await _repository.findById(id);
    return Servico.fromRow(criado!).toJson();
  }

  Future<Map<String, dynamic>> atualizar(
      int id, Map<String, dynamic> data) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Servico nao encontrado');
    }

    final updateData = <String, dynamic>{};

    for (final field in _allowedFields) {
      if (data.containsKey(field)) {
        updateData[field] = data[field]?.toString();
      }
    }

    if (data.containsKey('preco')) {
      final preco = data['preco'];
      final precoNum = preco is num
          ? preco.toDouble()
          : double.tryParse(preco?.toString() ?? '') ?? 0;
      if (precoNum < 0) {
        throw ValidationException('Preco deve ser positivo');
      }
      updateData['preco'] = precoNum.toStringAsFixed(2);
    }

    if (data.containsKey('comissao_fixa')) {
      final comissao = data['comissao_fixa'];
      final comissaoNum = comissao is num
          ? comissao.toDouble()
          : double.tryParse(comissao?.toString() ?? '') ?? 0;
      updateData['comissao_fixa'] = comissaoNum.toStringAsFixed(2);
    }

    if (data.containsKey('ativo')) {
      final ativo = data['ativo'];
      updateData['ativo'] =
          (ativo == true || ativo == 1 || ativo == '1') ? '1' : '0';
    }

    if (updateData.isNotEmpty) {
      await _repository.update(id, updateData);
    }

    final atualizado = await _repository.findById(id);
    return Servico.fromRow(atualizado!).toJson();
  }

  Future<void> excluir(int id) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Servico nao encontrado');
    }
    await _repository.delete(id);
  }

  Future<void> inativar(int id) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Servico nao encontrado');
    }
    await _repository.update(id, {'ativo': '0'});
  }
}
