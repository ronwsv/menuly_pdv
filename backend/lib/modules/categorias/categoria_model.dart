class Categoria {
  final int? id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final DateTime? criadoEm;

  Categoria({
    this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.criadoEm,
  });

  factory Categoria.fromRow(Map<String, String?> row) {
    return Categoria(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      nome: row['nome']!,
      descricao: row['descricao'],
      ativo: row['ativo'] != null ? int.parse(row['ativo']!) == 1 : true,
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'criado_em': criadoEm?.toIso8601String(),
    };
  }
}
