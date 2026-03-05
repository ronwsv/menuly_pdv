class Fornecedor {
  final int id;
  final String razaoSocial;
  final String? nomeFantasia;
  final String? cnpj;
  final String? inscricaoEstadual;
  final String? inscricaoMunicipal;
  final String? telefone;
  final String? email;
  final String? contato;
  final String? endereco;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? cep;
  final String? observacoes;
  final bool ativo;

  Fornecedor({
    required this.id,
    required this.razaoSocial,
    this.nomeFantasia,
    this.cnpj,
    this.inscricaoEstadual,
    this.inscricaoMunicipal,
    this.telefone,
    this.email,
    this.contato,
    this.endereco,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.cep,
    this.observacoes,
    this.ativo = true,
  });

  factory Fornecedor.fromJson(Map<String, dynamic> json) {
    return Fornecedor(
      id: _parseInt(json['id']),
      razaoSocial: json['razao_social']?.toString() ?? '',
      nomeFantasia: json['nome_fantasia']?.toString(),
      cnpj: json['cnpj']?.toString(),
      inscricaoEstadual: json['inscricao_estadual']?.toString(),
      inscricaoMunicipal: json['inscricao_municipal']?.toString(),
      telefone: json['telefone']?.toString(),
      email: json['email']?.toString(),
      contato: json['contato']?.toString(),
      endereco: json['endereco']?.toString(),
      numero: json['numero']?.toString(),
      bairro: json['bairro']?.toString(),
      cidade: json['cidade']?.toString(),
      estado: json['estado']?.toString(),
      cep: json['cep']?.toString(),
      observacoes: json['observacoes']?.toString(),
      ativo: json['ativo'] == 1 || json['ativo'] == '1' || json['ativo'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'razao_social': razaoSocial,
    'nome_fantasia': nomeFantasia,
    'cnpj': cnpj,
    'inscricao_estadual': inscricaoEstadual,
    'inscricao_municipal': inscricaoMunicipal,
    'telefone': telefone,
    'email': email,
    'contato': contato,
    'endereco': endereco,
    'numero': numero,
    'bairro': bairro,
    'cidade': cidade,
    'estado': estado,
    'cep': cep,
    'observacoes': observacoes,
    'ativo': ativo,
  };

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
