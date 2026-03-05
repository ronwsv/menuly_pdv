class Fornecedor {
  final int? id;
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
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  Fornecedor({
    this.id,
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
    this.criadoEm,
    this.atualizadoEm,
  });

  factory Fornecedor.fromRow(Map<String, String?> row) {
    return Fornecedor(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      razaoSocial: row['razao_social']!,
      nomeFantasia: row['nome_fantasia'],
      cnpj: row['cnpj'],
      inscricaoEstadual: row['inscricao_estadual'],
      inscricaoMunicipal: row['inscricao_municipal'],
      telefone: row['telefone'],
      email: row['email'],
      contato: row['contato'],
      endereco: row['endereco'],
      numero: row['numero'],
      bairro: row['bairro'],
      cidade: row['cidade'],
      estado: row['estado'],
      cep: row['cep'],
      observacoes: row['observacoes'],
      ativo: row['ativo'] != null ? int.parse(row['ativo']!) == 1 : true,
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
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }
}
