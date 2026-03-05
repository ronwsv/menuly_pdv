class Devolucao {
  final int? id;
  final int vendaId;
  final int? clienteId;
  final int usuarioId;
  final DateTime dataDevolucao;
  final String motivo;
  final String tipo; // devolucao, troca
  final String status; // pendente, aprovada, recusada, finalizada
  final double valorTotal;
  final String formaRestituicao; // dinheiro, credito, troca
  final double creditoGerado;
  final String? observacoes;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  // Joins
  final String? clienteNome;
  final String? usuarioNome;
  final String? vendaNumero;

  // Itens (carregados separadamente)
  final List<DevolucaoItem>? itens;

  Devolucao({
    this.id,
    required this.vendaId,
    this.clienteId,
    required this.usuarioId,
    required this.dataDevolucao,
    required this.motivo,
    this.tipo = 'devolucao',
    this.status = 'pendente',
    this.valorTotal = 0,
    this.formaRestituicao = 'credito',
    this.creditoGerado = 0,
    this.observacoes,
    this.criadoEm,
    this.atualizadoEm,
    this.clienteNome,
    this.usuarioNome,
    this.vendaNumero,
    this.itens,
  });

  factory Devolucao.fromRow(Map<String, String?> row) {
    return Devolucao(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      vendaId: int.parse(row['venda_id'] ?? '0'),
      clienteId:
          row['cliente_id'] != null ? int.parse(row['cliente_id']!) : null,
      usuarioId: int.parse(row['usuario_id'] ?? '0'),
      dataDevolucao: DateTime.parse(row['data_devolucao']!),
      motivo: row['motivo'] ?? '',
      tipo: row['tipo'] ?? 'devolucao',
      status: row['status'] ?? 'pendente',
      valorTotal: double.parse(row['valor_total'] ?? '0'),
      formaRestituicao: row['forma_restituicao'] ?? 'credito',
      creditoGerado: double.parse(row['credito_gerado'] ?? '0'),
      observacoes: row['observacoes'],
      criadoEm:
          row['criado_em'] != null ? DateTime.parse(row['criado_em']!) : null,
      atualizadoEm: row['atualizado_em'] != null
          ? DateTime.parse(row['atualizado_em']!)
          : null,
      clienteNome: row['cliente_nome'],
      usuarioNome: row['usuario_nome'],
      vendaNumero: row['venda_numero'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venda_id': vendaId,
      'cliente_id': clienteId,
      'usuario_id': usuarioId,
      'data_devolucao': dataDevolucao.toIso8601String(),
      'motivo': motivo,
      'tipo': tipo,
      'status': status,
      'valor_total': valorTotal,
      'forma_restituicao': formaRestituicao,
      'credito_gerado': creditoGerado,
      'observacoes': observacoes,
      'cliente_nome': clienteNome,
      'usuario_nome': usuarioNome,
      'venda_numero': vendaNumero,
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
      'itens': itens?.map((i) => i.toJson()).toList(),
    };
  }
}

class DevolucaoItem {
  final int? id;
  final int devolucaoId;
  final int produtoId;
  final double quantidade;
  final double precoUnitario;
  final double subtotal;
  final String? motivoItem;
  final String estadoProduto; // novo, usado, defeito
  final bool retornaEstoque;

  // Joins
  final String? produtoDescricao;

  DevolucaoItem({
    this.id,
    required this.devolucaoId,
    required this.produtoId,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
    this.motivoItem,
    this.estadoProduto = 'novo',
    this.retornaEstoque = true,
    this.produtoDescricao,
  });

  factory DevolucaoItem.fromRow(Map<String, String?> row) {
    return DevolucaoItem(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      devolucaoId: int.parse(row['devolucao_id'] ?? '0'),
      produtoId: int.parse(row['produto_id'] ?? '0'),
      quantidade: double.parse(row['quantidade'] ?? '0'),
      precoUnitario: double.parse(row['preco_unitario'] ?? '0'),
      subtotal: double.parse(row['subtotal'] ?? '0'),
      motivoItem: row['motivo_item'],
      estadoProduto: row['estado_produto'] ?? 'novo',
      retornaEstoque: (row['retorna_estoque'] ?? '1') == '1',
      produtoDescricao: row['produto_descricao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'devolucao_id': devolucaoId,
      'produto_id': produtoId,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'subtotal': subtotal,
      'motivo_item': motivoItem,
      'estado_produto': estadoProduto,
      'retorna_estoque': retornaEstoque,
      'produto_descricao': produtoDescricao,
    };
  }
}

class CustomerCredit {
  final int? id;
  final int clienteId;
  final int? devolucaoId;
  final double valor;
  final double valorUtilizado;
  final double saldo;
  final String status; // ativo, utilizado, expirado, cancelado
  final DateTime? dataExpiracao;
  final String? observacoes;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  // Joins
  final String? clienteNome;

  CustomerCredit({
    this.id,
    required this.clienteId,
    this.devolucaoId,
    required this.valor,
    this.valorUtilizado = 0,
    required this.saldo,
    this.status = 'ativo',
    this.dataExpiracao,
    this.observacoes,
    this.criadoEm,
    this.atualizadoEm,
    this.clienteNome,
  });

  factory CustomerCredit.fromRow(Map<String, String?> row) {
    return CustomerCredit(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      clienteId: int.parse(row['cliente_id'] ?? '0'),
      devolucaoId:
          row['devolucao_id'] != null ? int.parse(row['devolucao_id']!) : null,
      valor: double.parse(row['valor'] ?? '0'),
      valorUtilizado: double.parse(row['valor_utilizado'] ?? '0'),
      saldo: double.parse(row['saldo'] ?? '0'),
      status: row['status'] ?? 'ativo',
      dataExpiracao: row['data_expiracao'] != null
          ? DateTime.parse(row['data_expiracao']!)
          : null,
      observacoes: row['observacoes'],
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
      'cliente_id': clienteId,
      'devolucao_id': devolucaoId,
      'valor': valor,
      'valor_utilizado': valorUtilizado,
      'saldo': saldo,
      'status': status,
      'data_expiracao':
          dataExpiracao?.toIso8601String().substring(0, 10),
      'observacoes': observacoes,
      'cliente_nome': clienteNome,
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }
}
