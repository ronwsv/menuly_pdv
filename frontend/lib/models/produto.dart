class Produto {
  final int id;
  final String descricao;
  final String? codigoBarras;
  final String? codigoInterno;
  final String? detalhes;
  final int? categoriaId;
  final String? categoriaNome;
  final String? ncmCode;
  final String? tributacao;
  final int? fornecedorId;
  final String? fornecedorNome;
  final String unidade;
  final double precoCusto;
  final double precoVenda;
  final double margemLucro;
  final int estoqueAtual;
  final int estoqueMinimo;
  final bool ativo;
  final bool bloqueado;
  final String? imagemPath;

  Produto({
    required this.id,
    required this.descricao,
    this.codigoBarras,
    this.codigoInterno,
    this.detalhes,
    this.categoriaId,
    this.categoriaNome,
    this.ncmCode,
    this.tributacao,
    this.fornecedorId,
    this.fornecedorNome,
    this.unidade = 'un',
    this.precoCusto = 0,
    required this.precoVenda,
    this.margemLucro = 0,
    this.estoqueAtual = 0,
    this.estoqueMinimo = 0,
    this.ativo = true,
    this.bloqueado = false,
    this.imagemPath,
  });

  bool get estoqueBaixo => estoqueMinimo > 0 && estoqueAtual < estoqueMinimo;

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: _parseInt(json['id']),
      descricao: json['descricao']?.toString() ?? '',
      codigoBarras: json['codigo_barras']?.toString(),
      codigoInterno: json['codigo_interno']?.toString(),
      detalhes: json['detalhes']?.toString(),
      categoriaId: json['categoria_id'] != null ? _parseInt(json['categoria_id']) : null,
      categoriaNome: json['categoria_nome']?.toString(),
      ncmCode: json['ncm_code']?.toString(),
      tributacao: json['tributacao']?.toString(),
      fornecedorId: json['fornecedor_id'] != null ? _parseInt(json['fornecedor_id']) : null,
      fornecedorNome: json['fornecedor_nome']?.toString(),
      unidade: json['unidade']?.toString() ?? 'un',
      precoCusto: _parseDouble(json['preco_custo']),
      precoVenda: _parseDouble(json['preco_venda']),
      margemLucro: _parseDouble(json['margem_lucro']),
      estoqueAtual: _parseInt(json['estoque_atual']),
      estoqueMinimo: _parseInt(json['estoque_minimo']),
      ativo: json['ativo'] == 1 || json['ativo'] == '1' || json['ativo'] == true,
      bloqueado: json['bloqueado'] == 1 || json['bloqueado'] == '1' || json['bloqueado'] == true,
      imagemPath: json['imagem_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'descricao': descricao,
    'codigo_barras': codigoBarras,
    'codigo_interno': codigoInterno,
    'detalhes': detalhes,
    'categoria_id': categoriaId,
    'ncm_code': ncmCode,
    'tributacao': tributacao,
    'fornecedor_id': fornecedorId,
    'unidade': unidade,
    'preco_custo': precoCusto,
    'preco_venda': precoVenda,
    'estoque_atual': estoqueAtual,
    'estoque_minimo': estoqueMinimo,
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
