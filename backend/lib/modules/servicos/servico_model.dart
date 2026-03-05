class Servico {
  final int? id;
  final String descricao;
  final double preco;
  final double comissaoFixa;
  final String? outrosDados;
  final bool ativo;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  Servico({
    this.id,
    required this.descricao,
    required this.preco,
    this.comissaoFixa = 0,
    this.outrosDados,
    this.ativo = true,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory Servico.fromRow(Map<String, String?> row) {
    return Servico(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      descricao: row['descricao'] ?? '',
      preco: row['preco'] != null ? double.parse(row['preco']!) : 0,
      comissaoFixa: row['comissao_fixa'] != null
          ? double.parse(row['comissao_fixa']!)
          : 0,
      outrosDados: row['outros_dados'],
      ativo: row['ativo'] == '1',
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
      'descricao': descricao,
      'preco': preco,
      'comissao_fixa': comissaoFixa,
      'outros_dados': outrosDados,
      'ativo': ativo,
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }
}
