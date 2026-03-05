import 'compra_item.dart';

class Compra {
  final int id;
  final int fornecedorId;
  final String? fornecedorNome;
  final String dataCompra;
  final double valorBruto;
  final double valorFinal;
  final String? formaPagamento;
  final String? chaveNfe;
  final bool xmlImportado;
  final String? observacoes;
  final String? criadoEm;
  final List<CompraItem> itens;

  Compra({
    required this.id,
    required this.fornecedorId,
    this.fornecedorNome,
    required this.dataCompra,
    this.valorBruto = 0,
    this.valorFinal = 0,
    this.formaPagamento,
    this.chaveNfe,
    this.xmlImportado = false,
    this.observacoes,
    this.criadoEm,
    this.itens = const [],
  });

  factory Compra.fromJson(Map<String, dynamic> json) {
    final itensList = json['itens'] as List?;
    return Compra(
      id: _parseInt(json['id']),
      fornecedorId: _parseInt(json['fornecedor_id']),
      fornecedorNome: json['fornecedor_nome']?.toString(),
      dataCompra: json['data_compra']?.toString() ?? '',
      valorBruto: _parseDouble(json['valor_bruto']),
      valorFinal: _parseDouble(json['valor_final']),
      formaPagamento: json['forma_pagamento']?.toString(),
      chaveNfe: json['chave_nfe']?.toString(),
      xmlImportado: json['xml_importado'] == true || json['xml_importado'] == 1,
      observacoes: json['observacoes']?.toString(),
      criadoEm: json['criado_em']?.toString(),
      itens: itensList != null
          ? itensList
              .map((e) => CompraItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
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
