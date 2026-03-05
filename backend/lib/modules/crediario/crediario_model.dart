class CrediarioParcela {
  final int? id;
  final int vendaId;
  final int clienteId;
  final int numeroParcela;
  final int totalParcelas;
  final double valor;
  final DateTime dataVencimento;
  final String status;
  final DateTime? dataPagamento;
  final String? formaPagamento;
  final String? observacoes;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  // Joins
  final String? clienteNome;
  final String? vendaNumero;

  CrediarioParcela({
    this.id,
    required this.vendaId,
    required this.clienteId,
    required this.numeroParcela,
    required this.totalParcelas,
    required this.valor,
    required this.dataVencimento,
    this.status = 'pendente',
    this.dataPagamento,
    this.formaPagamento,
    this.observacoes,
    this.criadoEm,
    this.atualizadoEm,
    this.clienteNome,
    this.vendaNumero,
  });

  factory CrediarioParcela.fromRow(Map<String, String?> row) {
    return CrediarioParcela(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      vendaId: row['venda_id'] != null ? int.parse(row['venda_id']!) : 0,
      clienteId:
          row['cliente_id'] != null ? int.parse(row['cliente_id']!) : 0,
      numeroParcela: row['numero_parcela'] != null
          ? int.parse(row['numero_parcela']!)
          : 0,
      totalParcelas: row['total_parcelas'] != null
          ? int.parse(row['total_parcelas']!)
          : 0,
      valor: row['valor'] != null ? double.parse(row['valor']!) : 0,
      dataVencimento: DateTime.parse(row['data_vencimento']!),
      status: row['status'] ?? 'pendente',
      dataPagamento: row['data_pagamento'] != null
          ? DateTime.parse(row['data_pagamento']!)
          : null,
      formaPagamento: row['forma_pagamento'],
      observacoes: row['observacoes'],
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
      atualizadoEm: row['atualizado_em'] != null
          ? DateTime.parse(row['atualizado_em']!)
          : null,
      clienteNome: row['cliente_nome'],
      vendaNumero: row['venda_numero'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venda_id': vendaId,
      'cliente_id': clienteId,
      'numero_parcela': numeroParcela,
      'total_parcelas': totalParcelas,
      'valor': valor,
      'data_vencimento': dataVencimento.toIso8601String().substring(0, 10),
      'status': status,
      'data_pagamento':
          dataPagamento?.toIso8601String().substring(0, 10),
      'forma_pagamento': formaPagamento,
      'observacoes': observacoes,
      'cliente_nome': clienteNome,
      'venda_numero': vendaNumero,
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }
}
