class Produto {
  final int? id;
  final String? codigoBarras;
  final String? codigoInterno;
  final String descricao;
  final String? detalhes;
  final int? categoriaId;
  final String? ncmCode;
  final String? tributacao;
  final int? fornecedorId;
  final double precoCusto;
  final double precoVenda;
  final double? margemLucro;
  final String unidade;
  final String? tamanho;
  final int estoqueAtual;
  final int estoqueMinimo;
  final String? imagemPath;
  final String? thumbnailPath;
  final bool ativo;
  final String? categoriaNome;
  final String? fornecedorNome;
  final bool bloqueado;
  final bool isCombo;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  Produto({
    this.id,
    this.codigoBarras,
    this.codigoInterno,
    required this.descricao,
    this.detalhes,
    this.categoriaId,
    this.ncmCode,
    this.tributacao,
    this.fornecedorId,
    required this.precoCusto,
    required this.precoVenda,
    this.margemLucro,
    required this.unidade,
    this.tamanho,
    required this.estoqueAtual,
    required this.estoqueMinimo,
    this.imagemPath,
    this.thumbnailPath,
    this.categoriaNome,
    this.fornecedorNome,
    this.ativo = true,
    this.bloqueado = false,
    this.isCombo = false,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory Produto.fromRow(Map<String, String?> row) {
    return Produto(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      codigoBarras: row['codigo_barras'],
      codigoInterno: row['codigo_interno'],
      descricao: row['descricao'] ?? '',
      detalhes: row['detalhes'],
      categoriaId: row['categoria_id'] != null
          ? int.parse(row['categoria_id']!)
          : null,
      ncmCode: row['ncm_code'],
      tributacao: row['tributacao'],
      fornecedorId: row['fornecedor_id'] != null
          ? int.parse(row['fornecedor_id']!)
          : null,
      precoCusto: double.parse(row['preco_custo'] ?? '0'),
      precoVenda: double.parse(row['preco_venda'] ?? '0'),
      margemLucro: row['margem_lucro'] != null
          ? double.parse(row['margem_lucro']!)
          : null,
      unidade: row['unidade'] ?? 'un',
      tamanho: row['tamanho'],
      estoqueAtual: int.parse(row['estoque_atual'] ?? '0'),
      estoqueMinimo: int.parse(row['estoque_minimo'] ?? '0'),
      imagemPath: row['imagem_path'],
      thumbnailPath: row['thumbnail_path'],
      categoriaNome: row['categoria_nome'],
      fornecedorNome: row['fornecedor_nome'],
      ativo: row['ativo'] == '1',
      bloqueado: row['bloqueado'] == '1',
      isCombo: row['is_combo'] == '1',
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
      atualizadoEm: row['atualizado_em'] != null
          ? DateTime.parse(row['atualizado_em']!)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_barras': codigoBarras,
      'codigo_interno': codigoInterno,
      'descricao': descricao,
      'detalhes': detalhes,
      'categoria_id': categoriaId,
      'categoria_nome': categoriaNome,
      'fornecedor_nome': fornecedorNome,
      'ncm_code': ncmCode,
      'tributacao': tributacao,
      'fornecedor_id': fornecedorId,
      'preco_custo': precoCusto,
      'preco_venda': precoVenda,
      'margem_lucro': margemLucro,
      'unidade': unidade,
      'tamanho': tamanho,
      'estoque_atual': estoqueAtual,
      'estoque_minimo': estoqueMinimo,
      'imagem_path': imagemPath,
      'thumbnail_path': thumbnailPath,
      'ativo': ativo,
      'bloqueado': bloqueado,
      'is_combo': isCombo,
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }
}
