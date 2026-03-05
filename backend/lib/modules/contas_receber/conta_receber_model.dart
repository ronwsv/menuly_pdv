class ContaReceber {
  final int? id;
  final String descricao;
  final String? tipo;
  final String status;
  final DateTime dataVencimento;
  final double valor;
  final String? informacoes;
  final DateTime? dataRecebimento;
  final String? formaRecebimento;
  final int? clienteId;
  final int? vendaId;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  // Joins
  final String? clienteNome;

  ContaReceber({
    this.id,
    required this.descricao,
    this.tipo,
    this.status = 'pendente',
    required this.dataVencimento,
    required this.valor,
    this.informacoes,
    this.dataRecebimento,
    this.formaRecebimento,
    this.clienteId,
    this.vendaId,
    this.criadoEm,
    this.atualizadoEm,
    this.clienteNome,
  });

  factory ContaReceber.fromRow(Map<String, String?> row) {
    return ContaReceber(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      descricao: row['descricao'] ?? '',
      tipo: row['tipo'],
      status: row['status'] ?? 'pendente',
      dataVencimento: DateTime.parse(row['data_vencimento']!),
      valor: row['valor'] != null ? double.parse(row['valor']!) : 0,
      informacoes: row['informacoes'],
      dataRecebimento: row['data_recebimento'] != null
          ? DateTime.parse(row['data_recebimento']!)
          : null,
      formaRecebimento: row['forma_recebimento'],
      clienteId:
          row['cliente_id'] != null ? int.parse(row['cliente_id']!) : null,
      vendaId: row['venda_id'] != null ? int.parse(row['venda_id']!) : null,
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
      atualizadoEm: row['atualizado_em'] != null
          ? DateTime.parse(row['atualizado_em']!)
          : null,
      clienteNome: row['cliente_nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'tipo': tipo,
      'status': status,
      'data_vencimento': dataVencimento.toIso8601String().substring(0, 10),
      'valor': valor,
      'informacoes': informacoes,
      'data_recebimento':
          dataRecebimento?.toIso8601String().substring(0, 10),
      'forma_recebimento': formaRecebimento,
      'cliente_id': clienteId,
      'venda_id': vendaId,
      'cliente_nome': clienteNome,
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }
}
