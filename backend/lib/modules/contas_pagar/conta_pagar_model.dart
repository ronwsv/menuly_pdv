class ContaPagar {
  final int? id;
  final String descricao;
  final String? tipo;
  final String status;
  final DateTime dataVencimento;
  final double valor;
  final String? informacoes;
  final DateTime? dataPagamento;
  final String? formaPagamento;
  final int? fornecedorId;
  final int? compraId;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  // Joins
  final String? fornecedorNome;

  ContaPagar({
    this.id,
    required this.descricao,
    this.tipo,
    this.status = 'pendente',
    required this.dataVencimento,
    required this.valor,
    this.informacoes,
    this.dataPagamento,
    this.formaPagamento,
    this.fornecedorId,
    this.compraId,
    this.criadoEm,
    this.atualizadoEm,
    this.fornecedorNome,
  });

  factory ContaPagar.fromRow(Map<String, String?> row) {
    return ContaPagar(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      descricao: row['descricao'] ?? '',
      tipo: row['tipo'],
      status: row['status'] ?? 'pendente',
      dataVencimento: DateTime.parse(row['data_vencimento']!),
      valor: row['valor'] != null ? double.parse(row['valor']!) : 0,
      informacoes: row['informacoes'],
      dataPagamento: row['data_pagamento'] != null
          ? DateTime.parse(row['data_pagamento']!)
          : null,
      formaPagamento: row['forma_pagamento'],
      fornecedorId:
          row['fornecedor_id'] != null ? int.parse(row['fornecedor_id']!) : null,
      compraId:
          row['compra_id'] != null ? int.parse(row['compra_id']!) : null,
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
      atualizadoEm: row['atualizado_em'] != null
          ? DateTime.parse(row['atualizado_em']!)
          : null,
      fornecedorNome: row['fornecedor_nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'tipo': tipo,
      'status': status,
      'data_vencimento': dataVencimento.toIso8601String().substring(0, 10),
      'valor': valor,
      'informacoes': informacoes,
      'data_pagamento':
          dataPagamento?.toIso8601String().substring(0, 10),
      'forma_pagamento': formaPagamento,
      'fornecedor_id': fornecedorId,
      'compra_id': compraId,
      'fornecedor_nome': fornecedorNome,
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }
}
