class ComboItem {
  final int? id;
  final int comboId;
  final int produtoId;
  final double quantidade;
  final String? produtoDescricao;
  final double? produtoPrecoVenda;
  final double? produtoPrecoCusto;
  final int? produtoEstoqueAtual;

  ComboItem({
    this.id,
    required this.comboId,
    required this.produtoId,
    required this.quantidade,
    this.produtoDescricao,
    this.produtoPrecoVenda,
    this.produtoPrecoCusto,
    this.produtoEstoqueAtual,
  });

  factory ComboItem.fromRow(Map<String, String?> row) {
    return ComboItem(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      comboId: int.parse(row['combo_id'] ?? '0'),
      produtoId: int.parse(row['produto_id'] ?? '0'),
      quantidade: double.parse(row['quantidade'] ?? '1'),
      produtoDescricao: row['produto_descricao'],
      produtoPrecoVenda: row['produto_preco_venda'] != null
          ? double.parse(row['produto_preco_venda']!)
          : null,
      produtoPrecoCusto: row['produto_preco_custo'] != null
          ? double.parse(row['produto_preco_custo']!)
          : null,
      produtoEstoqueAtual: row['produto_estoque_atual'] != null
          ? int.parse(row['produto_estoque_atual']!)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'combo_id': comboId,
      'produto_id': produtoId,
      'quantidade': quantidade,
      'produto_descricao': produtoDescricao,
      'produto_preco_venda': produtoPrecoVenda,
      'produto_preco_custo': produtoPrecoCusto,
      'produto_estoque_atual': produtoEstoqueAtual,
    };
  }
}
