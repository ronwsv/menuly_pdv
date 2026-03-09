class ComboItemInfo {
  final int produtoId;
  final String descricao;
  final double quantidade;
  final double precoVenda;
  final double precoCusto;
  final int estoqueAtual;

  ComboItemInfo({
    required this.produtoId,
    required this.descricao,
    required this.quantidade,
    required this.precoVenda,
    this.precoCusto = 0,
    this.estoqueAtual = 0,
  });

  factory ComboItemInfo.fromJson(Map<String, dynamic> json) {
    return ComboItemInfo(
      produtoId: Produto._parseInt(json['produto_id']),
      descricao: json['produto_descricao']?.toString() ?? json['descricao']?.toString() ?? '',
      quantidade: Produto._parseDouble(json['quantidade']),
      precoVenda: Produto._parseDouble(json['produto_preco_venda'] ?? json['preco_venda']),
      precoCusto: Produto._parseDouble(json['produto_preco_custo'] ?? json['preco_custo']),
      estoqueAtual: Produto._parseInt(json['produto_estoque_atual'] ?? json['estoque_atual']),
    );
  }

  Map<String, dynamic> toJson() => {
    'produto_id': produtoId,
    'quantidade': quantidade,
  };
}

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
  final String? tamanho;
  final double precoCusto;
  final double precoVenda;
  final double? precoAtacado;
  final int? qtdMinimaAtacado;
  final double margemLucro;
  final int estoqueAtual;
  final int estoqueMinimo;
  final bool ativo;
  final bool bloqueado;
  final bool isCombo;
  final String? imagemPath;
  final List<ComboItemInfo>? comboItens;
  final int? estoqueDisponivel;

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
    this.tamanho,
    this.precoCusto = 0,
    required this.precoVenda,
    this.precoAtacado,
    this.qtdMinimaAtacado,
    this.margemLucro = 0,
    this.estoqueAtual = 0,
    this.estoqueMinimo = 0,
    this.ativo = true,
    this.bloqueado = false,
    this.isCombo = false,
    this.imagemPath,
    this.comboItens,
    this.estoqueDisponivel,
  });

  bool get estoqueBaixo => estoqueMinimo > 0 && estoqueAtual < estoqueMinimo;

  int get estoqueEfetivo => isCombo ? (estoqueDisponivel ?? 0) : estoqueAtual;

  factory Produto.fromJson(Map<String, dynamic> json) {
    List<ComboItemInfo>? comboItens;
    if (json['combo_itens'] != null) {
      comboItens = (json['combo_itens'] as List)
          .map((e) => ComboItemInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }

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
      tamanho: json['tamanho']?.toString(),
      precoCusto: _parseDouble(json['preco_custo']),
      precoVenda: _parseDouble(json['preco_venda']),
      precoAtacado: json['preco_atacado'] != null && json['preco_atacado'] != 0
          ? _parseDouble(json['preco_atacado'])
          : null,
      qtdMinimaAtacado: json['qtd_minima_atacado'] != null && json['qtd_minima_atacado'] != 0
          ? _parseInt(json['qtd_minima_atacado'])
          : null,
      margemLucro: _parseDouble(json['margem_lucro']),
      estoqueAtual: _parseInt(json['estoque_atual']),
      estoqueMinimo: _parseInt(json['estoque_minimo']),
      ativo: json['ativo'] == 1 || json['ativo'] == '1' || json['ativo'] == true,
      bloqueado: json['bloqueado'] == 1 || json['bloqueado'] == '1' || json['bloqueado'] == true,
      isCombo: json['is_combo'] == 1 || json['is_combo'] == '1' || json['is_combo'] == true,
      imagemPath: json['imagem_path']?.toString(),
      comboItens: comboItens,
      estoqueDisponivel: json['estoque_disponivel'] != null ? _parseInt(json['estoque_disponivel']) : null,
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
    'tamanho': tamanho,
    'preco_custo': precoCusto,
    'preco_venda': precoVenda,
    'preco_atacado': precoAtacado ?? 0,
    'qtd_minima_atacado': qtdMinimaAtacado ?? 0,
    'estoque_atual': estoqueAtual,
    'estoque_minimo': estoqueMinimo,
    'is_combo': isCombo,
    if (isCombo && comboItens != null)
      'combo_itens': comboItens!.map((e) => e.toJson()).toList(),
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
