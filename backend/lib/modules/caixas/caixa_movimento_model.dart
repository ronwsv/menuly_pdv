class CaixaMovimento {
  final int? id;
  final int caixaId;
  final String descricao;
  final double valor;
  final String tipo;
  final String? categoria;
  final int? referenciaId;
  final String? referenciaTipo;
  final int? usuarioId;
  final String? observacoes;
  final DateTime? criadoEm;

  CaixaMovimento({
    this.id,
    required this.caixaId,
    required this.descricao,
    required this.valor,
    required this.tipo,
    this.categoria,
    this.referenciaId,
    this.referenciaTipo,
    this.usuarioId,
    this.observacoes,
    this.criadoEm,
  });

  factory CaixaMovimento.fromRow(Map<String, String?> row) {
    return CaixaMovimento(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      caixaId: int.parse(row['caixa_id'] ?? '0'),
      descricao: row['descricao'] ?? '',
      valor: double.parse(row['valor'] ?? '0'),
      tipo: row['tipo'] ?? 'entrada',
      categoria: row['categoria'],
      referenciaId: row['referencia_id'] != null
          ? int.parse(row['referencia_id']!)
          : null,
      referenciaTipo: row['referencia_tipo'],
      usuarioId:
          row['usuario_id'] != null ? int.parse(row['usuario_id']!) : null,
      observacoes: row['observacoes'],
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caixa_id': caixaId,
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo,
      'categoria': categoria,
      'referencia_id': referenciaId,
      'referencia_tipo': referenciaTipo,
      'usuario_id': usuarioId,
      'observacoes': observacoes,
      'criado_em': criadoEm?.toIso8601String(),
    };
  }
}
