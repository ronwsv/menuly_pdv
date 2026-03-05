class ContaReceber {
  final int id;
  final String descricao;
  final String? tipo;
  final String status;
  final DateTime dataVencimento;
  final double valor;
  final String? informacoes;
  final DateTime? dataRecebimento;
  final String? formaRecebimento;
  final int? clienteId;
  final int? vendaId;
  final String? clienteNome;
  final DateTime? criadoEm;

  ContaReceber({
    required this.id,
    required this.descricao,
    this.tipo,
    required this.status,
    required this.dataVencimento,
    required this.valor,
    this.informacoes,
    this.dataRecebimento,
    this.formaRecebimento,
    this.clienteId,
    this.vendaId,
    this.clienteNome,
    this.criadoEm,
  });

  factory ContaReceber.fromJson(Map<String, dynamic> json) {
    return ContaReceber(
      id: _parseInt(json['id']),
      descricao: json['descricao']?.toString() ?? '',
      tipo: json['tipo']?.toString(),
      status: json['status']?.toString() ?? 'pendente',
      dataVencimento: DateTime.parse(json['data_vencimento'].toString()),
      valor: _parseDouble(json['valor']),
      informacoes: json['informacoes']?.toString(),
      dataRecebimento: json['data_recebimento'] != null
          ? DateTime.tryParse(json['data_recebimento'].toString())
          : null,
      formaRecebimento: json['forma_recebimento']?.toString(),
      clienteId: json['cliente_id'] != null ? _parseInt(json['cliente_id']) : null,
      vendaId: json['venda_id'] != null ? _parseInt(json['venda_id']) : null,
      clienteNome: json['cliente_nome']?.toString(),
      criadoEm: json['criado_em'] != null
          ? DateTime.tryParse(json['criado_em'].toString())
          : null,
    );
  }

  bool get isPendente => status == 'pendente';
  bool get isRecebido => status == 'recebido';
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
