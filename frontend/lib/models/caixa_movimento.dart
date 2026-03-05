class CaixaMovimento {
  final int id;
  final int caixaId;
  final String tipo;
  final double valor;
  final String? descricao;
  final String? formaPagamento;
  final int? vendaId;
  final int? usuarioId;
  final String criadoEm;

  CaixaMovimento({
    required this.id,
    required this.caixaId,
    required this.tipo,
    required this.valor,
    this.descricao,
    this.formaPagamento,
    this.vendaId,
    this.usuarioId,
    required this.criadoEm,
  });

  factory CaixaMovimento.fromJson(Map<String, dynamic> json) {
    return CaixaMovimento(
      id: _parseInt(json['id']),
      caixaId: _parseInt(json['caixa_id']),
      tipo: json['tipo']?.toString() ?? '',
      valor: _parseDouble(json['valor']),
      descricao: json['descricao']?.toString(),
      formaPagamento: json['forma_pagamento']?.toString(),
      vendaId: json['venda_id'] != null ? _parseInt(json['venda_id']) : null,
      usuarioId: json['usuario_id'] != null ? _parseInt(json['usuario_id']) : null,
      criadoEm: json['criado_em']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
