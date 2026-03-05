class OrdemServico {
  final int id;
  final String numero;
  final int prestadorId;
  final int clienteId;
  final String dataInicio;
  final String? dataTermino;
  final String? detalhes;
  final String? pedido;
  final String status;
  final String? formaPagamento;
  final double subtotal;
  final double desconto;
  final double total;
  final String? textoPadrao;
  final String? observacoes;
  final String? clienteNome;
  final String? prestadorNome;
  final String criadoEm;

  OrdemServico({
    required this.id,
    required this.numero,
    required this.prestadorId,
    required this.clienteId,
    required this.dataInicio,
    this.dataTermino,
    this.detalhes,
    this.pedido,
    this.status = 'aberta',
    this.formaPagamento,
    this.subtotal = 0,
    this.desconto = 0,
    this.total = 0,
    this.textoPadrao,
    this.observacoes,
    this.clienteNome,
    this.prestadorNome,
    required this.criadoEm,
  });

  factory OrdemServico.fromJson(Map<String, dynamic> json) {
    return OrdemServico(
      id: _parseInt(json['id']),
      numero: json['numero']?.toString() ?? '',
      prestadorId: _parseInt(json['prestador_id']),
      clienteId: _parseInt(json['cliente_id']),
      dataInicio: json['data_inicio']?.toString() ?? '',
      dataTermino: json['data_termino']?.toString(),
      detalhes: json['detalhes']?.toString(),
      pedido: json['pedido']?.toString(),
      status: json['status']?.toString() ?? 'aberta',
      formaPagamento: json['forma_pagamento']?.toString(),
      subtotal: _parseDouble(json['subtotal']),
      desconto: _parseDouble(json['desconto']),
      total: _parseDouble(json['total']),
      textoPadrao: json['texto_padrao']?.toString(),
      observacoes: json['observacoes']?.toString(),
      clienteNome: json['cliente_nome']?.toString(),
      prestadorNome: json['prestador_nome']?.toString(),
      criadoEm: json['criado_em']?.toString() ?? '',
    );
  }

  bool get isAberta => status == 'aberta';
  bool get isEmAndamento => status == 'em_andamento';
  bool get isFinalizada => status == 'finalizada';
  bool get isCancelada => status == 'cancelada';

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
