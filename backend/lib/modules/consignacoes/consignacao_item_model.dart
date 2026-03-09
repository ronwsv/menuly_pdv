class ConsignacaoItem {
  final int? id;
  final int consignacaoId;
  final int produtoId;
  final double quantidade;
  final double quantidadeVendida;
  final double quantidadeDevolvida;
  final double precoUnitario;
  final String? produtoDescricao;
  final String? produtoTamanho;

  ConsignacaoItem({
    this.id,
    required this.consignacaoId,
    required this.produtoId,
    required this.quantidade,
    this.quantidadeVendida = 0,
    this.quantidadeDevolvida = 0,
    required this.precoUnitario,
    this.produtoDescricao,
    this.produtoTamanho,
  });

  double get quantidadePendente =>
      quantidade - quantidadeVendida - quantidadeDevolvida;

  double get total => quantidade * precoUnitario;

  factory ConsignacaoItem.fromRow(Map<String, String?> row) {
    return ConsignacaoItem(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      consignacaoId: int.parse(row['consignacao_id'] ?? '0'),
      produtoId: int.parse(row['produto_id'] ?? '0'),
      quantidade: double.parse(row['quantidade'] ?? '0'),
      quantidadeVendida: double.parse(row['quantidade_vendida'] ?? '0'),
      quantidadeDevolvida: double.parse(row['quantidade_devolvida'] ?? '0'),
      precoUnitario: double.parse(row['preco_unitario'] ?? '0'),
      produtoDescricao: row['produto_descricao'],
      produtoTamanho: row['produto_tamanho'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consignacao_id': consignacaoId,
      'produto_id': produtoId,
      'quantidade': quantidade,
      'quantidade_vendida': quantidadeVendida,
      'quantidade_devolvida': quantidadeDevolvida,
      'quantidade_pendente': quantidadePendente,
      'preco_unitario': precoUnitario,
      'total': total,
      'produto_descricao': produtoDescricao,
      'produto_tamanho': produtoTamanho,
    };
  }
}
