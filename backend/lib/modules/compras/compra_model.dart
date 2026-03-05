class Compra {
  final int? id;
  final int fornecedorId;
  final DateTime dataCompra;
  final double valorBruto;
  final double valorFinal;
  final String? formaPagamento;
  final String? chaveNfe;
  final bool xmlImportado;
  final String? observacoes;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  // Campos extras de JOIN
  final String? fornecedorNome;

  Compra({
    this.id,
    required this.fornecedorId,
    required this.dataCompra,
    this.valorBruto = 0,
    this.valorFinal = 0,
    this.formaPagamento,
    this.chaveNfe,
    this.xmlImportado = false,
    this.observacoes,
    this.criadoEm,
    this.atualizadoEm,
    this.fornecedorNome,
  });

  factory Compra.fromRow(Map<String, String?> row) {
    return Compra(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      fornecedorId: int.parse(row['fornecedor_id'] ?? '0'),
      dataCompra: DateTime.parse(row['data_compra'] ?? DateTime.now().toIso8601String()),
      valorBruto: double.parse(row['valor_bruto'] ?? '0'),
      valorFinal: double.parse(row['valor_final'] ?? '0'),
      formaPagamento: row['forma_pagamento'],
      chaveNfe: row['chave_nfe'],
      xmlImportado: row['xml_importado'] == '1',
      observacoes: row['observacoes'],
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
      atualizadoEm: row['atualizado_em'] != null
          ? DateTime.parse(row['atualizado_em']!)
          : null,
      fornecedorNome: row['fornecedor_nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fornecedor_id': fornecedorId,
      'data_compra': dataCompra.toIso8601String(),
      'valor_bruto': valorBruto,
      'valor_final': valorFinal,
      'forma_pagamento': formaPagamento,
      'chave_nfe': chaveNfe,
      'xml_importado': xmlImportado,
      'observacoes': observacoes,
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
      if (fornecedorNome != null) 'fornecedor_nome': fornecedorNome,
    };
  }
}
