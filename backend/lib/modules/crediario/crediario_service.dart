import 'crediario_repository.dart';
import 'crediario_model.dart';
import '../../core/exceptions/api_exception.dart';

class CrediarioService {
  final CrediarioRepository _repository;

  CrediarioService(this._repository);

  Future<Map<String, dynamic>> listar(Map<String, dynamic> params) async {
    final busca = params['busca'] as String?;
    final status = params['status'] as String?;
    final clienteId = params['cliente_id'] as int?;
    final vendaId = params['venda_id'] as int?;
    final filtroVencimento = params['filtro_vencimento'] as String?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final rows = await _repository.findAll(
      busca: busca,
      status: status,
      clienteId: clienteId,
      vendaId: vendaId,
      filtroVencimento: filtroVencimento,
      limit: limit,
      offset: offset,
    );

    final total = await _repository.count(
      busca: busca,
      status: status,
      clienteId: clienteId,
      filtroVencimento: filtroVencimento,
    );

    return {
      'items':
          rows.map((row) => CrediarioParcela.fromRow(row).toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> obterPorId(int id) async {
    final row = await _repository.findById(id);
    if (row == null) {
      throw NotFoundException('Parcela nao encontrada');
    }
    return CrediarioParcela.fromRow(row).toJson();
  }

  Future<Map<String, dynamic>> pagar(
      int id, Map<String, dynamic> data) async {
    final row = await _repository.findById(id);
    if (row == null) {
      throw NotFoundException('Parcela nao encontrada');
    }

    if (row['status'] == 'pago') {
      throw ValidationException('Esta parcela ja foi paga');
    }

    if (row['status'] == 'cancelado') {
      throw ValidationException('Esta parcela esta cancelada');
    }

    final formaPagamento = data['forma_pagamento'] as String?;
    if (formaPagamento == null || formaPagamento.isEmpty) {
      throw ValidationException('Forma de pagamento e obrigatoria');
    }

    final dataPagamento = data['data_pagamento'] as String? ??
        DateTime.now().toIso8601String().substring(0, 10);

    await _repository.update(id, {
      'status': 'pago',
      'data_pagamento': dataPagamento,
      'forma_pagamento': formaPagamento,
    });

    final atualizado = await _repository.findById(id);
    return CrediarioParcela.fromRow(atualizado!).toJson();
  }

  Future<Map<String, dynamic>> totais({int? clienteId}) async {
    final row = await _repository.getTotais(clienteId: clienteId);
    return {
      'total_pendente': double.parse(row['total_pendente'] ?? '0'),
      'total_pago': double.parse(row['total_pago'] ?? '0'),
      'total_atrasado': double.parse(row['total_atrasado'] ?? '0'),
      'qtd_pendente': int.parse(row['qtd_pendente'] ?? '0'),
      'qtd_pago': int.parse(row['qtd_pago'] ?? '0'),
      'qtd_atrasado': int.parse(row['qtd_atrasado'] ?? '0'),
    };
  }

  Future<Map<String, dynamic>> verificarLimiteCliente(int clienteId) async {
    final cliente = await _repository.getCliente(clienteId);
    if (cliente == null) {
      throw NotFoundException('Cliente nao encontrado');
    }

    final limiteCredito = double.parse(cliente['limite_credito'] ?? '0');
    final saldoDevedor = await _repository.getSaldoDevedorCliente(clienteId);
    final temAtrasadas =
        await _repository.clienteTemParcelasAtrasadas(clienteId);
    final limiteDisponivel = limiteCredito - saldoDevedor;

    return {
      'cliente_id': clienteId,
      'cliente_nome': cliente['nome'],
      'limite_credito': limiteCredito,
      'saldo_devedor': saldoDevedor,
      'limite_disponivel': limiteDisponivel < 0 ? 0.0 : limiteDisponivel,
      'tem_parcelas_atrasadas': temAtrasadas,
      'bloqueado': temAtrasadas,
    };
  }

  Future<void> cancelarParcelasVenda(int vendaId) async {
    await _repository.cancelarParcelasVenda(vendaId);
  }

  /// Gera parcelas de crediario para uma venda.
  /// Chamado por VendasService quando forma_pagamento == 'crediario'.
  Future<List<Map<String, dynamic>>> gerarParcelas({
    required int vendaId,
    required int clienteId,
    required double totalVenda,
    required int numeroParcelas,
  }) async {
    // Verificar limite
    final cliente = await _repository.getCliente(clienteId);
    if (cliente == null) {
      throw ValidationException('Cliente nao encontrado para crediario');
    }

    final limiteCredito = double.parse(cliente['limite_credito'] ?? '0');
    final saldoDevedor = await _repository.getSaldoDevedorCliente(clienteId);
    final limiteDisponivel = limiteCredito - saldoDevedor;

    if (limiteCredito > 0 && totalVenda > limiteDisponivel) {
      throw ValidationException(
        'Limite de credito insuficiente. '
        'Disponivel: R\$ ${limiteDisponivel.toStringAsFixed(2)}, '
        'Necessario: R\$ ${totalVenda.toStringAsFixed(2)}',
      );
    }

    // Verificar parcelas atrasadas
    final temAtrasadas =
        await _repository.clienteTemParcelasAtrasadas(clienteId);
    if (temAtrasadas) {
      throw ValidationException(
        'Cliente possui parcelas em atraso. '
        'Nao e possivel realizar venda no crediario.',
      );
    }

    // Gerar parcelas
    final valorParcela = totalVenda / numeroParcelas;
    final parcelas = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 1; i <= numeroParcelas; i++) {
      final vencimento = DateTime(now.year, now.month + i, now.day);

      final parcelaId = await _repository.create({
        'venda_id': vendaId.toString(),
        'cliente_id': clienteId.toString(),
        'numero_parcela': i.toString(),
        'total_parcelas': numeroParcelas.toString(),
        'valor': valorParcela.toStringAsFixed(2),
        'data_vencimento':
            '${vencimento.year}-${vencimento.month.toString().padLeft(2, '0')}-${vencimento.day.toString().padLeft(2, '0')}',
        'status': 'pendente',
      });

      final parcela = await _repository.findById(parcelaId);
      if (parcela != null) {
        parcelas.add(CrediarioParcela.fromRow(parcela).toJson());
      }
    }

    return parcelas;
  }
}
