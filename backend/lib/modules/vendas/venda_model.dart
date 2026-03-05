class Venda {
  final int? id;
  final String numero;
  final String tipo;
  final int? clienteId;
  final int usuarioId;
  final int? vendedorId;
  final int totalItens;
  final double subtotal;
  final double descontoPercentual;
  final double descontoValor;
  final double total;
  final String? formaPagamento;
  final double? valorRecebido;
  final double troco;
  final String status;
  final bool sincronizadoNfce;
  final String? observacoes;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  Venda({
    this.id,
    required this.numero,
    required this.tipo,
    this.clienteId,
    required this.usuarioId,
    this.vendedorId,
    required this.totalItens,
    required this.subtotal,
    this.descontoPercentual = 0,
    this.descontoValor = 0,
    required this.total,
    this.formaPagamento,
    this.valorRecebido,
    this.troco = 0,
    this.status = 'finalizada',
    this.sincronizadoNfce = false,
    this.observacoes,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory Venda.fromRow(Map<String, String?> row) {
    return Venda(
      id: row['id'] != null ? int.parse(row['id']!) : null,
      numero: row['numero'] ?? '',
      tipo: row['tipo'] ?? 'Venda',
      clienteId:
          row['cliente_id'] != null ? int.parse(row['cliente_id']!) : null,
      usuarioId: int.parse(row['usuario_id'] ?? '0'),
      vendedorId:
          row['vendedor_id'] != null ? int.parse(row['vendedor_id']!) : null,
      totalItens: int.parse(row['total_itens'] ?? '0'),
      subtotal: double.parse(row['subtotal'] ?? '0'),
      descontoPercentual: double.parse(row['desconto_percentual'] ?? '0'),
      descontoValor: double.parse(row['desconto_valor'] ?? '0'),
      total: double.parse(row['total'] ?? '0'),
      formaPagamento: row['forma_pagamento'],
      valorRecebido: row['valor_recebido'] != null
          ? double.parse(row['valor_recebido']!)
          : null,
      troco: double.parse(row['troco'] ?? '0'),
      status: row['status'] ?? 'finalizada',
      sincronizadoNfce: row['sincronizado_nfce'] == '1',
      observacoes: row['observacoes'],
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
      'numero': numero,
      'tipo': tipo,
      'cliente_id': clienteId,
      'usuario_id': usuarioId,
      'vendedor_id': vendedorId,
      'total_itens': totalItens,
      'subtotal': subtotal,
      'desconto_percentual': descontoPercentual,
      'desconto_valor': descontoValor,
      'total': total,
      'forma_pagamento': formaPagamento,
      'valor_recebido': valorRecebido,
      'troco': troco,
      'status': status,
      'sincronizado_nfce': sincronizadoNfce,
      'observacoes': observacoes,
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }
}
