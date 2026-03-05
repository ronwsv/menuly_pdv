class CrediarioParcela {
  final int id;
  final int vendaId;
  final int clienteId;
  final int numeroParcela;
  final int totalParcelas;
  final double valor;
  final DateTime dataVencimento;
  final String status;
  final DateTime? dataPagamento;
  final String? formaPagamento;
  final String? clienteNome;
  final String? vendaNumero;
  final DateTime? criadoEm;

  CrediarioParcela({
    required this.id,
    required this.vendaId,
    required this.clienteId,
    required this.numeroParcela,
    required this.totalParcelas,
    required this.valor,
    required this.dataVencimento,
    required this.status,
    this.dataPagamento,
    this.formaPagamento,
    this.clienteNome,
    this.vendaNumero,
    this.criadoEm,
  });

  factory CrediarioParcela.fromJson(Map<String, dynamic> json) {
    return CrediarioParcela(
      id: _parseInt(json['id']),
      vendaId: _parseInt(json['venda_id']),
      clienteId: _parseInt(json['cliente_id']),
      numeroParcela: _parseInt(json['numero_parcela']),
      totalParcelas: _parseInt(json['total_parcelas']),
      valor: _parseDouble(json['valor']),
      dataVencimento: DateTime.parse(json['data_vencimento'].toString()),
      status: json['status']?.toString() ?? 'pendente',
      dataPagamento: json['data_pagamento'] != null
          ? DateTime.tryParse(json['data_pagamento'].toString())
          : null,
      formaPagamento: json['forma_pagamento']?.toString(),
      clienteNome: json['cliente_nome']?.toString(),
      vendaNumero: json['venda_numero']?.toString(),
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

  String get parcelaLabel => '$numeroParcela/$totalParcelas';

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
