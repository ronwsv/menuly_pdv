class Categoria {
  final int id;
  final String nome;
  final bool ativo;

  Categoria({required this.id, required this.nome, required this.ativo});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nome: json['nome']?.toString() ?? '',
      ativo: json['ativo'] == 1 || json['ativo'] == '1' || json['ativo'] == true,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'ativo': ativo};
}
