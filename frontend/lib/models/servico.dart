class Servico {
  final int id;
  final String descricao;
  final double preco;
  final double comissaoFixa;
  final String? outrosDados;
  final bool ativo;
  final String criadoEm;

  Servico({
    required this.id,
    required this.descricao,
    this.preco = 0,
    this.comissaoFixa = 0,
    this.outrosDados,
    this.ativo = true,
    required this.criadoEm,
  });

  factory Servico.fromJson(Map<String, dynamic> json) {
    return Servico(
      id: _parseInt(json['id']),
      descricao: json['descricao']?.toString() ?? '',
      preco: _parseDouble(json['preco']),
      comissaoFixa: _parseDouble(json['comissao_fixa']),
      outrosDados: json['outros_dados']?.toString(),
      ativo: json['ativo'] == true || json['ativo'] == 1,
      criadoEm: json['criado_em']?.toString() ?? '',
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
