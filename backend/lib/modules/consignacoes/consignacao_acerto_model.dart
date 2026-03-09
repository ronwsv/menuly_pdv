class ConsignacaoAcerto {
  final int? id;
  final int consignacaoId;
  final int usuarioId;
  final double valorVendido;
  final String? formaPagamento;
  final String? observacoes;
  final DateTime? criadoEm;

  ConsignacaoAcerto({
    this.id,
    required this.consignacaoId,
    required this.usuarioId,
    this.valorVendido = 0,
    this.formaPagamento,
    this.observacoes,
    this.criadoEm,
  });

  factory ConsignacaoAcerto.fromRow(Map<String, String?> row) {
    return ConsignacaoAcerto(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      consignacaoId: int.parse(row['consignacao_id'] ?? '0'),
      usuarioId: int.parse(row['usuario_id'] ?? '0'),
      valorVendido: double.parse(row['valor_vendido'] ?? '0'),
      formaPagamento: row['forma_pagamento'],
      observacoes: row['observacoes'],
      criadoEm: row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consignacao_id': consignacaoId,
      'usuario_id': usuarioId,
      'valor_vendido': valorVendido,
      'forma_pagamento': formaPagamento,
      'observacoes': observacoes,
      'criado_em': criadoEm?.toIso8601String(),
    };
  }
}
