import 'contas_receber_repository.dart';
import 'conta_receber_model.dart';
import '../../core/exceptions/api_exception.dart';

class ContasReceberService {
  final ContasReceberRepository _repository;

  ContasReceberService(this._repository);

  static const _allowedFields = [
    'descricao',
    'tipo',
    'data_vencimento',
    'valor',
    'informacoes',
    'cliente_id',
    'venda_id',
  ];

  Future<Map<String, dynamic>> listar(Map<String, dynamic> params) async {
    final busca = params['busca'] as String?;
    final status = params['status'] as String?;
    final filtroVencimento = params['filtro_vencimento'] as String?;
    final clienteId = params['cliente_id'] as int?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final rows = await _repository.findAll(
      busca: busca,
      status: status,
      filtroVencimento: filtroVencimento,
      clienteId: clienteId,
      limit: limit,
      offset: offset,
    );

    final total = await _repository.count(
      busca: busca,
      status: status,
      filtroVencimento: filtroVencimento,
      clienteId: clienteId,
    );

    return {
      'items': rows.map((row) => ContaReceber.fromRow(row).toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> obterPorId(int id) async {
    final row = await _repository.findById(id);
    if (row == null) {
      throw NotFoundException('Conta a receber nao encontrada');
    }
    return ContaReceber.fromRow(row).toJson();
  }

  Future<Map<String, dynamic>> criar(Map<String, dynamic> data) async {
    final descricao = data['descricao'] as String?;
    if (descricao == null || descricao.trim().isEmpty) {
      throw ValidationException('Descricao e obrigatoria');
    }

    final dataVencimento = data['data_vencimento'] as String?;
    if (dataVencimento == null || dataVencimento.isEmpty) {
      throw ValidationException('Data de vencimento e obrigatoria');
    }

    final valor = data['valor'];
    if (valor == null) {
      throw ValidationException('Valor e obrigatorio');
    }
    final valorNum = valor is num
        ? valor.toDouble()
        : double.tryParse(valor.toString()) ?? 0;
    if (valorNum <= 0) {
      throw ValidationException('Valor deve ser positivo');
    }

    final dbData = <String, String>{
      'descricao': descricao.trim(),
      'data_vencimento': dataVencimento,
      'valor': valorNum.toStringAsFixed(2),
      'status': 'pendente',
    };

    if (data['tipo'] != null && (data['tipo'] as String).isNotEmpty) {
      dbData['tipo'] = data['tipo'].toString();
    }
    if (data['informacoes'] != null) {
      dbData['informacoes'] = data['informacoes'].toString();
    }
    if (data['cliente_id'] != null) {
      dbData['cliente_id'] = data['cliente_id'].toString();
    }
    if (data['venda_id'] != null) {
      dbData['venda_id'] = data['venda_id'].toString();
    }

    final id = await _repository.create(dbData);
    final criado = await _repository.findById(id);
    return ContaReceber.fromRow(criado!).toJson();
  }

  Future<Map<String, dynamic>> atualizar(
      int id, Map<String, dynamic> data) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Conta a receber nao encontrada');
    }

    if (existing['status'] == 'recebido') {
      throw ValidationException(
          'Nao e possivel editar uma conta ja recebida');
    }

    final updateData = <String, dynamic>{};

    for (final field in _allowedFields) {
      if (data.containsKey(field)) {
        updateData[field] = data[field]?.toString();
      }
    }

    if (data.containsKey('valor')) {
      final valor = data['valor'];
      final valorNum = valor is num
          ? valor.toDouble()
          : double.tryParse(valor?.toString() ?? '') ?? 0;
      if (valorNum <= 0) {
        throw ValidationException('Valor deve ser positivo');
      }
      updateData['valor'] = valorNum.toStringAsFixed(2);
    }

    if (updateData.isNotEmpty) {
      await _repository.update(id, updateData);
    }

    final atualizado = await _repository.findById(id);
    return ContaReceber.fromRow(atualizado!).toJson();
  }

  Future<Map<String, dynamic>> darBaixa(
      int id, Map<String, dynamic> data) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Conta a receber nao encontrada');
    }

    if (existing['status'] == 'recebido') {
      throw ValidationException('Esta conta ja foi recebida');
    }

    if (existing['status'] == 'cancelado') {
      throw ValidationException('Esta conta esta cancelada');
    }

    final formaRecebimento = data['forma_recebimento'] as String?;
    if (formaRecebimento == null || formaRecebimento.isEmpty) {
      throw ValidationException('Forma de recebimento e obrigatoria');
    }

    final dataRecebimento =
        data['data_recebimento'] as String? ??
            DateTime.now().toIso8601String().substring(0, 10);

    await _repository.update(id, {
      'status': 'recebido',
      'data_recebimento': dataRecebimento,
      'forma_recebimento': formaRecebimento,
    });

    final atualizado = await _repository.findById(id);
    return ContaReceber.fromRow(atualizado!).toJson();
  }

  Future<void> cancelar(int id) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Conta a receber nao encontrada');
    }

    if (existing['status'] == 'recebido') {
      throw ValidationException(
          'Nao e possivel cancelar uma conta ja recebida');
    }

    await _repository.update(id, {'status': 'cancelado'});
  }

  Future<void> excluir(int id) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Conta a receber nao encontrada');
    }
    await _repository.delete(id);
  }

  Future<Map<String, dynamic>> totais({int? clienteId}) async {
    final row = await _repository.getTotais(clienteId: clienteId);
    return {
      'total_pendente': double.parse(row['total_pendente'] ?? '0'),
      'total_recebido': double.parse(row['total_recebido'] ?? '0'),
      'total_atrasado': double.parse(row['total_atrasado'] ?? '0'),
      'qtd_pendente': int.parse(row['qtd_pendente'] ?? '0'),
      'qtd_atrasado': int.parse(row['qtd_atrasado'] ?? '0'),
      'qtd_vencendo_hoje': int.parse(row['qtd_vencendo_hoje'] ?? '0'),
    };
  }
}
