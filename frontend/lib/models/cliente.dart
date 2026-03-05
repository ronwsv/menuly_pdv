class Cliente {
  final int id;
  final String nome;
  final String tipoPessoa;
  final String? cpfCnpj;
  final String? inscricaoEstadual;
  final String? telefone;
  final String? email;
  final String? cep;
  final String? endereco;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final double limiteCredito;
  final String? outrosDados;
  final bool ativo;

  Cliente({
    required this.id,
    required this.nome,
    this.tipoPessoa = 'F',
    this.cpfCnpj,
    this.inscricaoEstadual,
    this.telefone,
    this.email,
    this.cep,
    this.endereco,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.limiteCredito = 0.0,
    this.outrosDados,
    this.ativo = true,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: _parseInt(json['id']),
      nome: json['nome']?.toString() ?? '',
      tipoPessoa: json['tipo_pessoa']?.toString() ?? 'F',
      cpfCnpj: json['cpf_cnpj']?.toString(),
      inscricaoEstadual: json['inscricao_estadual']?.toString(),
      telefone: json['telefone']?.toString(),
      email: json['email']?.toString(),
      cep: json['cep']?.toString(),
      endereco: json['endereco']?.toString(),
      numero: json['numero']?.toString(),
      bairro: json['bairro']?.toString(),
      cidade: json['cidade']?.toString(),
      estado: json['estado']?.toString(),
      limiteCredito: _parseDouble(json['limite_credito']),
      outrosDados: json['outros_dados']?.toString(),
      ativo: json['ativo'] == 1 || json['ativo'] == '1' || json['ativo'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'tipo_pessoa': tipoPessoa,
    'cpf_cnpj': cpfCnpj,
    'inscricao_estadual': inscricaoEstadual,
    'telefone': telefone,
    'email': email,
    'cep': cep,
    'endereco': endereco,
    'numero': numero,
    'bairro': bairro,
    'cidade': cidade,
    'estado': estado,
    'limite_credito': limiteCredito,
    'outros_dados': outrosDados,
    'ativo': ativo,
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
