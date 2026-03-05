class Caixa {
  final int id;
  final String nome;
  final double saldoAtual;
  final bool ativo;
  final String status; // 'aberto' or 'fechado'

  Caixa({
    required this.id,
    required this.nome,
    this.saldoAtual = 0,
    this.ativo = true,
    this.status = 'fechado',
  });

  bool get isAberto => status == 'aberto';
  bool get isFechado => status == 'fechado';

  factory Caixa.fromJson(Map<String, dynamic> json) {
    return Caixa(
      id: _parseInt(json['id']),
      nome: json['nome']?.toString() ?? '',
      saldoAtual: _parseDouble(json['saldo_atual']),
      ativo: json['ativo'] == 1 || json['ativo'] == '1' || json['ativo'] == true,
      status: json['status']?.toString() ?? 'fechado',
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
