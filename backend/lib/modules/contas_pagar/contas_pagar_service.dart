import 'contas_pagar_repository.dart';
import 'conta_pagar_model.dart';
import '../../core/exceptions/api_exception.dart';

class ContasPagarService {
  final ContasPagarRepository _repository;

  ContasPagarService(this._repository);

  static const _allowedFields = [
    'descricao',
    'tipo',
    'data_vencimento',
    'valor',
    'informacoes',
    'fornecedor_id',
    'compra_id',
  ];

  Future<Map<String, dynamic>> listar(Map<String, dynamic> params) async {
    final busca = params['busca'] as String?;
    final status = params['status'] as String?;
    final filtroVencimento = params['filtro_vencimento'] as String?;
    final fornecedorId = params['fornecedor_id'] as int?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final rows = await _repository.findAll(
      busca: busca,
      status: status,
      filtroVencimento: filtroVencimento,
      fornecedorId: fornecedorId,
      limit: limit,
      offset: offset,
    );

    final total = await _repository.count(
      busca: busca,
      status: status,
      filtroVencimento: filtroVencimento,
      fornecedorId: fornecedorId,
    );

    return {
      'items': rows.map((row) => ContaPagar.fromRow(row).toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> obterPorId(int id) async {
    final row = await _repository.findById(id);
    if (row == null) {
      throw NotFoundException('Conta a pagar nao encontrada');
    }
    return ContaPagar.fromRow(row).toJson();
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
    if (data['fornecedor_id'] != null) {
      dbData['fornecedor_id'] = data['fornecedor_id'].toString();
    }
    if (data['compra_id'] != null) {
      dbData['compra_id'] = data['compra_id'].toString();
    }

    final id = await _repository.create(dbData);
    final criado = await _repository.findById(id);
    return ContaPagar.fromRow(criado!).toJson();
  }

  Future<Map<String, dynamic>> atualizar(
      int id, Map<String, dynamic> data) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Conta a pagar nao encontrada');
    }

    if (existing['status'] == 'pago') {
      throw ValidationException(
          'Nao e possivel editar uma conta ja paga');
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
    return ContaPagar.fromRow(atualizado!).toJson();
  }

  Future<Map<String, dynamic>> darBaixa(
      int id, Map<String, dynamic> data) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Conta a pagar nao encontrada');
    }

    if (existing['status'] == 'pago') {
      throw ValidationException('Esta conta ja foi paga');
    }

    if (existing['status'] == 'cancelado') {
      throw ValidationException('Esta conta esta cancelada');
    }

    final formaPagamento = data['forma_pagamento'] as String?;
    if (formaPagamento == null || formaPagamento.isEmpty) {
      throw ValidationException('Forma de pagamento e obrigatoria');
    }

    final dataPagamento =
        data['data_pagamento'] as String? ??
            DateTime.now().toIso8601String().substring(0, 10);

    await _repository.update(id, {
      'status': 'pago',
      'data_pagamento': dataPagamento,
      'forma_pagamento': formaPagamento,
    });

    final atualizado = await _repository.findById(id);
    return ContaPagar.fromRow(atualizado!).toJson();
  }

  Future<void> cancelar(int id) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Conta a pagar nao encontrada');
    }

    if (existing['status'] == 'pago') {
      throw ValidationException(
          'Nao e possivel cancelar uma conta ja paga');
    }

    await _repository.update(id, {'status': 'cancelado'});
  }

  Future<void> excluir(int id) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Conta a pagar nao encontrada');
    }
    await _repository.delete(id);
  }

  Future<Map<String, dynamic>> totais({int? fornecedorId}) async {
    final row = await _repository.getTotais(fornecedorId: fornecedorId);
    return {
      'total_pendente': double.parse(row['total_pendente'] ?? '0'),
      'total_pago': double.parse(row['total_pago'] ?? '0'),
      'total_atrasado': double.parse(row['total_atrasado'] ?? '0'),
      'qtd_pendente': int.parse(row['qtd_pendente'] ?? '0'),
      'qtd_atrasado': int.parse(row['qtd_atrasado'] ?? '0'),
      'qtd_vencendo_hoje': int.parse(row['qtd_vencendo_hoje'] ?? '0'),
    };
  }
}
