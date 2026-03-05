class Cliente {
  final int? id;
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
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  Cliente({
    this.id,
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
    this.limiteCredito = 0.00,
    this.outrosDados,
    this.ativo = true,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory Cliente.fromRow(Map<String, String?> row) {
    return Cliente(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      nome: row['nome']!,
      tipoPessoa: row['tipo_pessoa'] ?? 'F',
      cpfCnpj: row['cpf_cnpj'],
      inscricaoEstadual: row['inscricao_estadual'],
      telefone: row['telefone'],
      email: row['email'],
      cep: row['cep'],
      endereco: row['endereco'],
      numero: row['numero'],
      bairro: row['bairro'],
      cidade: row['cidade'],
      estado: row['estado'],
      limiteCredito: row['limite_credito'] != null
          ? double.parse(row['limite_credito']!)
          : 0.00,
      outrosDados: row['outros_dados'],
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
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }
}
