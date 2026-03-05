class CompraItem {
  final int? id;
  final int compraId;
  final int produtoId;
  final double quantidade;
  final double precoUnitario;
  final double total;
  final DateTime? criadoEm;

  // Campos extras de JOIN
  final String? produtoDescricao;

  CompraItem({
    this.id,
    required this.compraId,
    required this.produtoId,
    required this.quantidade,
    required this.precoUnitario,
    required this.total,
    this.criadoEm,
    this.produtoDescricao,
  });

  factory CompraItem.fromRow(Map<String, String?> row) {
    return CompraItem(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      compraId: int.parse(row['compra_id'] ?? '0'),
      produtoId: int.parse(row['produto_id'] ?? '0'),
      quantidade: double.parse(row['quantidade'] ?? '0'),
      precoUnitario: double.parse(row['preco_unitario'] ?? '0'),
      total: double.parse(row['total'] ?? '0'),
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
      produtoDescricao: row['produto_descricao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'compra_id': compraId,
      'produto_id': produtoId,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'total': total,
      'criado_em': criadoEm?.toIso8601String(),
      if (produtoDescricao != null) 'produto_descricao': produtoDescricao,
    };
  }
}
