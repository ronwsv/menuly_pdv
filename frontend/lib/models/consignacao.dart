class ConsignacaoItem {
  final int id;
  final int produtoId;
  final String? produtoDescricao;
  final String? produtoTamanho;
  final double quantidade;
  final double quantidadeVendida;
  final double quantidadeDevolvida;
  final double precoUnitario;

  ConsignacaoItem({
    required this.id,
    required this.produtoId,
    this.produtoDescricao,
    this.produtoTamanho,
    required this.quantidade,
    this.quantidadeVendida = 0,
    this.quantidadeDevolvida = 0,
    required this.precoUnitario,
  });

  double get quantidadePendente =>
      quantidade - quantidadeVendida - quantidadeDevolvida;

  double get total => quantidade * precoUnitario;

  factory ConsignacaoItem.fromJson(Map<String, dynamic> json) {
    return ConsignacaoItem(
      id: _parseInt(json['id']),
      produtoId: _parseInt(json['produto_id']),
      produtoDescricao: json['produto_descricao']?.toString(),
      produtoTamanho: json['produto_tamanho']?.toString(),
      quantidade: _parseDouble(json['quantidade']),
      quantidadeVendida: _parseDouble(json['quantidade_vendida']),
      quantidadeDevolvida: _parseDouble(json['quantidade_devolvida']),
      precoUnitario: _parseDouble(json['preco_unitario']),
    );
  }

  Map<String, dynamic> toJson() => {
        'produto_id': produtoId,
        'quantidade': quantidade,
        'preco_unitario': precoUnitario,
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

class ConsignacaoAcerto {
  final int id;
  final int consignacaoId;
  final double valorVendido;
  final String? formaPagamento;
  final String? observacoes;
  final DateTime? criadoEm;

  ConsignacaoAcerto({
    required this.id,
    required this.consignacaoId,
    required this.valorVendido,
    this.formaPagamento,
    this.observacoes,
    this.criadoEm,
  });

  factory ConsignacaoAcerto.fromJson(Map<String, dynamic> json) {
    return ConsignacaoAcerto(
      id: ConsignacaoItem._parseInt(json['id']),
      consignacaoId: ConsignacaoItem._parseInt(json['consignacao_id']),
      valorVendido: ConsignacaoItem._parseDouble(json['valor_vendido']),
      formaPagamento: json['forma_pagamento']?.toString(),
      observacoes: json['observacoes']?.toString(),
      criadoEm: json['criado_em'] != null
          ? DateTime.tryParse(json['criado_em'].toString())
          : null,
    );
  }
}

class Consignacao {
  final int id;
  final String numero;
  final String tipo;
  final String status;
  final int? clienteId;
  final int? fornecedorId;
  final String? clienteNome;
  final String? fornecedorNome;
  final int totalItens;
  final double valorTotal;
  final double valorAcertado;
  final String? observacoes;
  final DateTime? criadoEm;
  final List<ConsignacaoItem>? itens;
  final List<ConsignacaoAcerto>? acertos;

  Consignacao({
    required this.id,
    required this.numero,
    required this.tipo,
    required this.status,
    this.clienteId,
    this.fornecedorId,
    this.clienteNome,
    this.fornecedorNome,
    this.totalItens = 0,
    this.valorTotal = 0,
    this.valorAcertado = 0,
    this.observacoes,
    this.criadoEm,
    this.itens,
    this.acertos,
  });

  String get parceiro => tipo == 'saida'
      ? (clienteNome ?? 'Sem cliente')
      : (fornecedorNome ?? 'Sem fornecedor');

  factory Consignacao.fromJson(Map<String, dynamic> json) {
    List<ConsignacaoItem>? itens;
    if (json['itens'] != null) {
      itens = (json['itens'] as List)
          .map((e) => ConsignacaoItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<ConsignacaoAcerto>? acertos;
    if (json['acertos'] != null) {
      acertos = (json['acertos'] as List)
          .map((e) => ConsignacaoAcerto.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Consignacao(
      id: ConsignacaoItem._parseInt(json['id']),
      numero: json['numero']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'saida',
      status: json['status']?.toString() ?? 'aberta',
      clienteId: json['cliente_id'] != null
          ? ConsignacaoItem._parseInt(json['cliente_id'])
          : null,
      fornecedorId: json['fornecedor_id'] != null
          ? ConsignacaoItem._parseInt(json['fornecedor_id'])
          : null,
      clienteNome: json['cliente_nome']?.toString(),
      fornecedorNome: json['fornecedor_nome']?.toString(),
      totalItens: ConsignacaoItem._parseInt(json['total_itens']),
      valorTotal: ConsignacaoItem._parseDouble(json['valor_total']),
      valorAcertado: ConsignacaoItem._parseDouble(json['valor_acertado']),
      observacoes: json['observacoes']?.toString(),
      criadoEm: json['criado_em'] != null
          ? DateTime.tryParse(json['criado_em'].toString())
          : null,
      itens: itens,
      acertos: acertos,
    );
  }
}
