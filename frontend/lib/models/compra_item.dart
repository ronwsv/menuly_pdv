class CompraItem {
  final int? id;
  final int? compraId;
  final int produtoId;
  final String? produtoDescricao;
  final double quantidade;
  final double precoUnitario;
  final double total;

  CompraItem({
    this.id,
    this.compraId,
    required this.produtoId,
    this.produtoDescricao,
    required this.quantidade,
    required this.precoUnitario,
    required this.total,
  });

  factory CompraItem.fromJson(Map<String, dynamic> json) {
    return CompraItem(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      compraId: json['compra_id'] != null ? _parseInt(json['compra_id']) : null,
      produtoId: _parseInt(json['produto_id']),
      produtoDescricao: json['produto_descricao']?.toString(),
      quantidade: _parseDouble(json['quantidade']),
      precoUnitario: _parseDouble(json['preco_unitario']),
      total: _parseDouble(json['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produto_id': produtoId,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'total': total,
    };
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
