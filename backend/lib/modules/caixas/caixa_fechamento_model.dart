class CaixaFechamento {
  final int? id;
  final int caixaId;
  final double saldoInicial;
  final int usuarioId;
  final DateTime dataInicio;
  final DateTime dataFim;
  final double totalEntradas;
  final double totalSaidas;
  final double saldoEsperado;
  final double? saldoInformado;
  final double? diferenca;
  final String? observacoes;
  final DateTime? criadoEm;
  // Joined fields
  final String? nomeUsuario;

  CaixaFechamento({
    this.id,
    required this.caixaId,
    this.saldoInicial = 0,
    required this.usuarioId,
    required this.dataInicio,
    required this.dataFim,
    this.totalEntradas = 0,
    this.totalSaidas = 0,
    this.saldoEsperado = 0,
    this.saldoInformado,
    this.diferenca,
    this.observacoes,
    this.criadoEm,
    this.nomeUsuario,
  });

  factory CaixaFechamento.fromRow(Map<String, String?> row) {
    return CaixaFechamento(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      caixaId: int.parse(row['caixa_id'] ?? '0'),
      saldoInicial: double.parse(row['saldo_inicial'] ?? '0'),
      usuarioId: int.parse(row['usuario_id'] ?? '0'),
      dataInicio: DateTime.parse(row['data_inicio']!),
      dataFim: DateTime.parse(row['data_fim']!),
      totalEntradas: double.parse(row['total_entradas'] ?? '0'),
      totalSaidas: double.parse(row['total_saidas'] ?? '0'),
      saldoEsperado: double.parse(row['saldo_esperado'] ?? '0'),
      saldoInformado: row['saldo_informado'] != null
          ? double.parse(row['saldo_informado']!)
          : null,
      diferenca:
          row['diferenca'] != null ? double.parse(row['diferenca']!) : null,
      observacoes: row['observacoes'],
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
      nomeUsuario: row['nome_usuario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caixa_id': caixaId,
      'saldo_inicial': saldoInicial,
      'usuario_id': usuarioId,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
      'total_entradas': totalEntradas,
      'total_saidas': totalSaidas,
      'saldo_esperado': saldoEsperado,
      'saldo_informado': saldoInformado,
      'diferenca': diferenca,
      'observacoes': observacoes,
      'criado_em': criadoEm?.toIso8601String(),
      'nome_usuario': nomeUsuario,
    };
  }
}
