class Usuario {
  final int id;
  final String nome;
  final String login;
  final String papel;

  Usuario({
    required this.id,
    required this.nome,
    required this.login,
    required this.papel,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nome: json['nome']?.toString() ?? '',
      login: json['login']?.toString() ?? '',
      papel: json['papel']?.toString() ?? 'operador',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'login': login,
    'papel': papel,
  };
}
