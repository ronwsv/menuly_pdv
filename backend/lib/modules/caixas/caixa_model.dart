class Caixa {
  final int? id;
  final String nome;
  final String? descricao;
  final double saldoAtual;
  final bool ativo;
  final String status; // 'aberto' or 'fechado'
  final DateTime? criadoEm;

  Caixa({
    this.id,
    required this.nome,
    this.descricao,
    this.saldoAtual = 0,
    this.ativo = true,
    this.status = 'fechado',
    this.criadoEm,
  });

  factory Caixa.fromRow(Map<String, String?> row) {
    return Caixa(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      nome: row['nome'] ?? '',
      descricao: row['descricao'],
      saldoAtual: double.parse(row['saldo_atual'] ?? '0'),
      ativo: row['ativo'] == '1',
      status: row['status'] ?? 'fechado',
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'saldo_atual': saldoAtual,
      'ativo': ativo,
      'status': status,
      'criado_em': criadoEm?.toIso8601String(),
    };
  }
}
