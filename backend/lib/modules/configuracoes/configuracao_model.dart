class Configuracao {
  final int? id;
  final String chave;
  final String? valor;
  final String? grupo;
  final String? descricao;
  final DateTime? criadoEm;

  Configuracao({
    this.id,
    required this.chave,
    this.valor,
    this.grupo,
    this.descricao,
    this.criadoEm,
  });

  factory Configuracao.fromRow(Map<String, String?> row) {
    return Configuracao(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      chave: row['chave']!,
      valor: row['valor'],
      grupo: row['grupo'],
      descricao: row['descricao'],
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chave': chave,
      'valor': valor,
      'grupo': grupo,
      'descricao': descricao,
      'criado_em': criadoEm?.toIso8601String(),
    };
  }
}
