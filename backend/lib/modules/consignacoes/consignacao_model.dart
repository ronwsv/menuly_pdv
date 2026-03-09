class Consignacao {
  final int? id;
  final String numero;
  final String tipo; // 'saida' or 'entrada'
  final int? clienteId;
  final int? fornecedorId;
  final int usuarioId;
  final String status; // 'aberta', 'parcial', 'fechada', 'cancelada'
  final int totalItens;
  final double valorTotal;
  final double valorAcertado;
  final String? observacoes;
  final String? clienteNome;
  final String? fornecedorNome;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  Consignacao({
    this.id,
    required this.numero,
    required this.tipo,
    this.clienteId,
    this.fornecedorId,
    required this.usuarioId,
    this.status = 'aberta',
    this.totalItens = 0,
    this.valorTotal = 0,
    this.valorAcertado = 0,
    this.observacoes,
    this.clienteNome,
    this.fornecedorNome,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory Consignacao.fromRow(Map<String, String?> row) {
    return Consignacao(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      numero: row['numero'] ?? '',
      tipo: row['tipo'] ?? 'saida',
      clienteId: row['cliente_id'] != null ? int.parse(row['cliente_id']!) : null,
      fornecedorId: row['fornecedor_id'] != null ? int.parse(row['fornecedor_id']!) : null,
      usuarioId: int.parse(row['usuario_id'] ?? '0'),
      status: row['status'] ?? 'aberta',
      totalItens: int.parse(row['total_itens'] ?? '0'),
      valorTotal: double.parse(row['valor_total'] ?? '0'),
      valorAcertado: double.parse(row['valor_acertado'] ?? '0'),
      observacoes: row['observacoes'],
      clienteNome: row['cliente_nome'],
      fornecedorNome: row['fornecedor_nome'],
      criadoEm: row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
      atualizadoEm: row['atualizado_em'] != null ? DateTime.parse(row['atualizado_em']!) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'tipo': tipo,
      'cliente_id': clienteId,
      'fornecedor_id': fornecedorId,
      'usuario_id': usuarioId,
      'status': status,
      'total_itens': totalItens,
      'valor_total': valorTotal,
      'valor_acertado': valorAcertado,
      'observacoes': observacoes,
      'cliente_nome': clienteNome,
      'fornecedor_nome': fornecedorNome,
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }
}
