class OrdemServico {
  final int? id;
  final String numero;
  final int prestadorId;
  final int clienteId;
  final DateTime dataInicio;
  final DateTime? dataTermino;
  final String? detalhes;
  final String? pedido;
  final String status;
  final String? formaPagamento;
  final double subtotal;
  final double desconto;
  final double total;
  final String? textoPadrao;
  final String? observacoes;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  // Joins
  final String? clienteNome;
  final String? prestadorNome;

  OrdemServico({
    this.id,
    required this.numero,
    required this.prestadorId,
    required this.clienteId,
    required this.dataInicio,
    this.dataTermino,
    this.detalhes,
    this.pedido,
    this.status = 'aberta',
    this.formaPagamento,
    this.subtotal = 0,
    this.desconto = 0,
    this.total = 0,
    this.textoPadrao,
    this.observacoes,
    this.criadoEm,
    this.atualizadoEm,
    this.clienteNome,
    this.prestadorNome,
  });

  factory OrdemServico.fromRow(Map<String, String?> row) {
    return OrdemServico(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      numero: row['numero'] ?? '',
      prestadorId: row['prestador_id'] != null
          ? int.parse(row['prestador_id']!)
          : 0,
      clienteId:
          row['cliente_id'] != null ? int.parse(row['cliente_id']!) : 0,
      dataInicio: DateTime.parse(row['data_inicio']!),
      dataTermino: row['data_termino'] != null
          ? DateTime.parse(row['data_termino']!)
          : null,
      detalhes: row['detalhes'],
      pedido: row['pedido'],
      status: row['status'] ?? 'aberta',
      formaPagamento: row['forma_pagamento'],
      subtotal:
          row['subtotal'] != null ? double.parse(row['subtotal']!) : 0,
      desconto:
          row['desconto'] != null ? double.parse(row['desconto']!) : 0,
      total: row['total'] != null ? double.parse(row['total']!) : 0,
      textoPadrao: row['texto_padrao'],
      observacoes: row['observacoes'],
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
      atualizadoEm: row['atualizado_em'] != null
          ? DateTime.parse(row['atualizado_em']!)
          : null,
      clienteNome: row['cliente_nome'],
      prestadorNome: row['prestador_nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'prestador_id': prestadorId,
      'cliente_id': clienteId,
      'data_inicio': dataInicio.toIso8601String(),
      'data_termino': dataTermino?.toIso8601String(),
      'detalhes': detalhes,
      'pedido': pedido,
      'status': status,
      'forma_pagamento': formaPagamento,
      'subtotal': subtotal,
      'desconto': desconto,
      'total': total,
      'texto_padrao': textoPadrao,
      'observacoes': observacoes,
      'cliente_nome': clienteNome,
      'prestador_nome': prestadorNome,
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }
}

class OsItemServico {
  final int? id;
  final int ordemServicoId;
  final int servicoId;
  final double quantidade;
  final double precoUnitario;
  final double total;
  final String? servicoDescricao;

  OsItemServico({
    this.id,
    required this.ordemServicoId,
    required this.servicoId,
    this.quantidade = 1,
    required this.precoUnitario,
    required this.total,
    this.servicoDescricao,
  });

  factory OsItemServico.fromRow(Map<String, String?> row) {
    return OsItemServico(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      ordemServicoId: row['ordem_servico_id'] != null
          ? int.parse(row['ordem_servico_id']!)
          : 0,
      servicoId:
          row['servico_id'] != null ? int.parse(row['servico_id']!) : 0,
      quantidade:
          row['quantidade'] != null ? double.parse(row['quantidade']!) : 1,
      precoUnitario: row['preco_unitario'] != null
          ? double.parse(row['preco_unitario']!)
          : 0,
      total: row['total'] != null ? double.parse(row['total']!) : 0,
      servicoDescricao: row['servico_descricao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ordem_servico_id': ordemServicoId,
      'servico_id': servicoId,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'total': total,
      'servico_descricao': servicoDescricao,
    };
  }
}

class OsItemProduto {
  final int? id;
  final int ordemServicoId;
  final int produtoId;
  final double quantidade;
  final double precoUnitario;
  final double total;
  final String? produtoDescricao;

  OsItemProduto({
    this.id,
    required this.ordemServicoId,
    required this.produtoId,
    required this.quantidade,
    required this.precoUnitario,
    required this.total,
    this.produtoDescricao,
  });

  factory OsItemProduto.fromRow(Map<String, String?> row) {
    return OsItemProduto(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      ordemServicoId: row['ordem_servico_id'] != null
          ? int.parse(row['ordem_servico_id']!)
          : 0,
      produtoId:
          row['produto_id'] != null ? int.parse(row['produto_id']!) : 0,
      quantidade:
          row['quantidade'] != null ? double.parse(row['quantidade']!) : 0,
      precoUnitario: row['preco_unitario'] != null
          ? double.parse(row['preco_unitario']!)
          : 0,
      total: row['total'] != null ? double.parse(row['total']!) : 0,
      produtoDescricao: row['produto_descricao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ordem_servico_id': ordemServicoId,
      'produto_id': produtoId,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'total': total,
      'produto_descricao': produtoDescricao,
    };
  }
}
