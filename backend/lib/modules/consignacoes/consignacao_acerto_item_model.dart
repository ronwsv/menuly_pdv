class ConsignacaoAcertoItem {
  final int? id;
  final int acertoId;
  final int consignacaoItemId;
  final double quantidadeVendida;
  final double quantidadeDevolvida;
  final double valor;

  ConsignacaoAcertoItem({
    this.id,
    required this.acertoId,
    required this.consignacaoItemId,
    this.quantidadeVendida = 0,
    this.quantidadeDevolvida = 0,
    this.valor = 0,
  });

  factory ConsignacaoAcertoItem.fromRow(Map<String, String?> row) {
    return ConsignacaoAcertoItem(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      acertoId: int.parse(row['acerto_id'] ?? '0'),
      consignacaoItemId: int.parse(row['consignacao_item_id'] ?? '0'),
      quantidadeVendida: double.parse(row['quantidade_vendida'] ?? '0'),
      quantidadeDevolvida: double.parse(row['quantidade_devolvida'] ?? '0'),
      valor: double.parse(row['valor'] ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'acerto_id': acertoId,
      'consignacao_item_id': consignacaoItemId,
      'quantidade_vendida': quantidadeVendida,
      'quantidade_devolvida': quantidadeDevolvida,
      'valor': valor,
    };
  }
}
