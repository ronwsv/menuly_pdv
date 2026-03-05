class VendaItem {
  final int? id;
  final int vendaId;
  final int? produtoId;
  final int? servicoId;
  final double quantidade;
  final double precoUnitario;
  final double desconto;
  final double total;
  final DateTime? criadoEm;

  // Campos extras de JOIN
  final String? produtoDescricao;

  VendaItem({
    this.id,
    required this.vendaId,
    this.produtoId,
    this.servicoId,
    required this.quantidade,
    required this.precoUnitario,
    this.desconto = 0,
    required this.total,
    this.criadoEm,
    this.produtoDescricao,
  });

  factory VendaItem.fromRow(Map<String, String?> row) {
    return VendaItem(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      vendaId: int.parse(row['venda_id'] ?? '0'),
      produtoId:
          row['produto_id'] != null ? int.parse(row['produto_id']!) : null,
      servicoId:
          row['servico_id'] != null ? int.parse(row['servico_id']!) : null,
      quantidade: double.parse(row['quantidade'] ?? '0'),
      precoUnitario: double.parse(row['preco_unitario'] ?? '0'),
      desconto: double.parse(row['desconto'] ?? '0'),
      total: double.parse(row['total'] ?? '0'),
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
      produtoDescricao: row['produto_descricao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venda_id': vendaId,
      'produto_id': produtoId,
      'servico_id': servicoId,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'desconto': desconto,
      'total': total,
      'criado_em': criadoEm?.toIso8601String(),
      if (produtoDescricao != null) 'produto_descricao': produtoDescricao,
    };
  }
}
