class Venda {
  final int id;
  final String numero;
  final String tipo;
  final String status;
  final int? clienteId;
  final int? usuarioId;
  final String? formaPagamento;
  final double subtotal;
  final double desconto;
  final double total;
  final double? valorRecebido;
  final double? troco;
  final int totalItens;
  final int? caixaId;
  final String? observacoes;
  final String criadoEm;

  Venda({
    required this.id,
    required this.numero,
    required this.tipo,
    required this.status,
    this.clienteId,
    this.usuarioId,
    this.formaPagamento,
    this.subtotal = 0,
    this.desconto = 0,
    this.total = 0,
    this.totalItens = 0,
    this.valorRecebido,
    this.troco,
    this.caixaId,
    this.observacoes,
    required this.criadoEm,
  });

  factory Venda.fromJson(Map<String, dynamic> json) {
    return Venda(
      id: _parseInt(json['id']),
      numero: json['numero']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'Venda',
      status: json['status']?.toString() ?? 'finalizada',
      clienteId: json['cliente_id'] != null ? _parseInt(json['cliente_id']) : null,
      usuarioId: json['usuario_id'] != null ? _parseInt(json['usuario_id']) : null,
      formaPagamento: json['forma_pagamento']?.toString(),
      subtotal: _parseDouble(json['subtotal']),
      desconto: _parseDouble(json['desconto']),
      total: _parseDouble(json['total']),
      totalItens: json['total_itens'] != null ? _parseInt(json['total_itens']) : 0,
      valorRecebido: json['valor_recebido'] != null ? _parseDouble(json['valor_recebido']) : null,
      troco: json['troco'] != null ? _parseDouble(json['troco']) : null,
      caixaId: json['caixa_id'] != null ? _parseInt(json['caixa_id']) : null,
      observacoes: json['observacoes']?.toString(),
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
