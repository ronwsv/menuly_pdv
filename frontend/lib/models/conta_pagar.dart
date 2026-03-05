class ContaPagar {
  final int id;
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
  final String? fornecedorNome;
  final DateTime? criadoEm;

  ContaPagar({
    required this.id,
    required this.descricao,
    this.tipo,
    required this.status,
    required this.dataVencimento,
    required this.valor,
    this.informacoes,
    this.dataPagamento,
    this.formaPagamento,
    this.fornecedorId,
    this.compraId,
    this.fornecedorNome,
    this.criadoEm,
  });

  factory ContaPagar.fromJson(Map<String, dynamic> json) {
    return ContaPagar(
      id: _parseInt(json['id']),
      descricao: json['descricao']?.toString() ?? '',
      tipo: json['tipo']?.toString(),
      status: json['status']?.toString() ?? 'pendente',
      dataVencimento: DateTime.parse(json['data_vencimento'].toString()),
      valor: _parseDouble(json['valor']),
      informacoes: json['informacoes']?.toString(),
      dataPagamento: json['data_pagamento'] != null
          ? DateTime.tryParse(json['data_pagamento'].toString())
          : null,
      formaPagamento: json['forma_pagamento']?.toString(),
      fornecedorId:
          json['fornecedor_id'] != null ? _parseInt(json['fornecedor_id']) : null,
      compraId: json['compra_id'] != null ? _parseInt(json['compra_id']) : null,
      fornecedorNome: json['fornecedor_nome']?.toString(),
      criadoEm: json['criado_em'] != null
          ? DateTime.tryParse(json['criado_em'].toString())
          : null,
    );
  }

  bool get isPendente => status == 'pendente';
  bool get isPago => status == 'pago';
  bool get isCancelado => status == 'cancelado';

  bool get isAtrasado =>
      isPendente && dataVencimento.isBefore(DateTime.now());

  bool get isVenceHoje {
    final now = DateTime.now();
    return isPendente &&
        dataVencimento.year == now.year &&
        dataVencimento.month == now.month &&
        dataVencimento.day == now.day;
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
