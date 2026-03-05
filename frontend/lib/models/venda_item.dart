class VendaItem {
  final int? id;
  final int? vendaId;
  final int produtoId;
  final String produtoDescricao;
  final int quantidade;
  final double precoUnitario;
  final double desconto;
  final double subtotal;

  VendaItem({
    this.id,
    this.vendaId,
    required this.produtoId,
    required this.produtoDescricao,
    required this.quantidade,
    required this.precoUnitario,
    this.desconto = 0,
    required this.subtotal,
  });

  factory VendaItem.fromJson(Map<String, dynamic> json) {
    return VendaItem(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      vendaId: json['venda_id'] != null ? _parseInt(json['venda_id']) : null,
      produtoId: _parseInt(json['produto_id']),
      produtoDescricao: json['produto_descricao']?.toString() ?? json['descricao']?.toString() ?? '',
      quantidade: _parseInt(json['quantidade']),
      precoUnitario: _parseDouble(json['preco_unitario']),
      desconto: _parseDouble(json['desconto']),
      subtotal: _parseDouble(json['subtotal']),
    );
  }

  Map<String, dynamic> toJson() => {
    'produto_id': produtoId,
    'quantidade': quantidade,
    'preco_unitario': precoUnitario,
    'desconto': desconto,
  };

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
