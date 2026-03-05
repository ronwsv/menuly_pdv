class HistoricoEstoque {
  final int? id;
  final int produtoId;
  final String tipo;
  final String ocorrencia;
  final double quantidade;
  final int? referenciaId;
  final String? referenciaTipo;
  final String? observacoes;
  final int? usuarioId;
  final DateTime? criadoEm;

  HistoricoEstoque({
    this.id,
    required this.produtoId,
    required this.tipo,
    required this.ocorrencia,
    required this.quantidade,
    this.referenciaId,
    this.referenciaTipo,
    this.observacoes,
    this.usuarioId,
    this.criadoEm,
  });

  factory HistoricoEstoque.fromRow(Map<String, String?> row) {
    return HistoricoEstoque(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      produtoId: int.parse(row['produto_id'] ?? '0'),
      tipo: row['tipo'] ?? '',
      ocorrencia: row['ocorrencia'] ?? '',
      quantidade: double.parse(row['quantidade'] ?? '0'),
      referenciaId: row['referencia_id'] != null
          ? int.parse(row['referencia_id']!)
          : null,
      referenciaTipo: row['referencia_tipo'],
      observacoes: row['observacoes'],
      usuarioId:
          row['usuario_id'] != null ? int.parse(row['usuario_id']!) : null,
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produto_id': produtoId,
      'tipo': tipo,
      'ocorrencia': ocorrencia,
      'quantidade': quantidade,
      'referencia_id': referenciaId,
      'referencia_tipo': referenciaTipo,
      'observacoes': observacoes,
      'usuario_id': usuarioId,
      'criado_em': criadoEm?.toIso8601String(),
    };
  }
}
