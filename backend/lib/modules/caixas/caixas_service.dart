import '../../core/exceptions/api_exception.dart';
import 'caixas_repository.dart';

class CaixasService {
  final CaixasRepository _repository;

  CaixasService(this._repository);

  Future<List<Map<String, dynamic>>> listarCaixas() async {
    final caixas = await _repository.findAll();
    return caixas.map((c) => c.toJson()).toList();
  }

  Future<Map<String, dynamic>> obterCaixa(int id) async {
    final caixa = await _repository.findById(id);
    if (caixa == null) {
      throw NotFoundException('Caixa não encontrado');
    }
    return caixa.toJson();
  }

  Future<Map<String, dynamic>> listarMovimentos(
    Map<String, dynamic> params,
  ) async {
    final caixaId = params['caixa_id'] as int?;
    final tipo = params['tipo'] as String?;
    final dataInicio = params['data_inicio'] as String?;
    final dataFim = params['data_fim'] as String?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final movimentos = await _repository.findMovimentos(
      caixaId: caixaId,
      tipo: tipo,
      dataInicio: dataInicio,
      dataFim: dataFim,
      limit: limit,
      offset: offset,
    );

    final total = await _repository.countMovimentos(
      caixaId: caixaId,
      tipo: tipo,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );

    return {
      'items': movimentos.map((m) => m.toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> lancamento(
    Map<String, dynamic> data,
    int usuarioId,
  ) async {
    final caixaId = data['caixa_id'];
    if (caixaId == null) {
      throw ValidationException('caixa_id é obrigatório');
    }
    final caixaIdInt =
        caixaId is int ? caixaId : int.tryParse(caixaId.toString());
    if (caixaIdInt == null) {
      throw ValidationException('caixa_id inválido');
    }

    final caixa = await _repository.findById(caixaIdInt);
    if (caixa == null) {
      throw NotFoundException('Caixa não encontrado');
    }

    final descricao = data['descricao'] as String?;
    if (descricao == null || descricao.isEmpty) {
      throw ValidationException('Descrição é obrigatória');
    }

    final tipo = data['tipo'] as String?;
    if (tipo == null || (tipo != 'entrada' && tipo != 'saida')) {
      throw ValidationException('Tipo deve ser "entrada" ou "saida"');
    }

    final valor = data['valor'];
    if (valor == null) {
      throw ValidationException('Valor é obrigatório');
    }
    final valorNum = valor is num
        ? valor.toDouble()
        : double.tryParse(valor.toString()) ?? 0;
    if (valorNum <= 0) {
      throw ValidationException('Valor deve ser positivo');
    }

    // Verificar saldo para saídas
    if (tipo == 'saida' && caixa.saldoAtual < valorNum) {
      throw ValidationException(
        'Saldo insuficiente. Saldo atual: R\$ ${caixa.saldoAtual.toStringAsFixed(2)}',
      );
    }

    final movData = <String, String>{
      'caixa_id': caixaIdInt.toString(),
      'descricao': descricao,
      'valor': valorNum.toStringAsFixed(2),
      'tipo': tipo,
      'usuario_id': usuarioId.toString(),
    };

    if (data['categoria'] != null) {
      movData['categoria'] = data['categoria'].toString();
    }
    if (data['observacoes'] != null) {
      movData['observacoes'] = data['observacoes'].toString();
    }

    final movId = await _repository.criarMovimento(movData);

    // Atualizar saldo
    final delta = tipo == 'entrada' ? valorNum : -valorNum;
    await _repository.atualizarSaldo(caixaIdInt, delta);

    return {
      'id': movId,
      'message': 'Lançamento registrado com sucesso',
      'saldo_anterior': caixa.saldoAtual,
      'saldo_atual': caixa.saldoAtual + delta,
    };
  }

  Future<Map<String, dynamic>> lancamentoBatch(
    Map<String, dynamic> data,
    int usuarioId,
  ) async {
    final caixaId = data['caixa_id'];
    if (caixaId == null) {
      throw ValidationException('caixa_id é obrigatório');
    }
    final caixaIdInt =
        caixaId is int ? caixaId : int.tryParse(caixaId.toString());
    if (caixaIdInt == null) {
      throw ValidationException('caixa_id inválido');
    }

    final caixa = await _repository.findById(caixaIdInt);
    if (caixa == null) {
      throw NotFoundException('Caixa não encontrado');
    }

    final itens = data['itens'] as List?;
    if (itens == null || itens.isEmpty) {
      throw ValidationException('itens é obrigatório');
    }

    int importados = 0;
    double saldoDelta = 0;

    for (final item in itens) {
      final m = item as Map<String, dynamic>;
      final tipo = m['tipo'] as String?;
      if (tipo != 'entrada' && tipo != 'saida') continue;

      final valor = m['valor'];
      final valorNum = valor is num
          ? valor.toDouble()
          : double.tryParse(valor?.toString() ?? '') ?? 0;
      if (valorNum <= 0) continue;

      final descricao =
          (m['descricao'] as String?)?.isNotEmpty == true
              ? m['descricao'] as String
              : 'Importação CSV';

      final movData = <String, String>{
        'caixa_id': caixaIdInt.toString(),
        'descricao': descricao,
        'valor': valorNum.toStringAsFixed(2),
        'tipo': tipo!,
        'categoria': 'importacao_csv',
        'usuario_id': usuarioId.toString(),
      };

      if (m['observacoes'] != null) {
        movData['observacoes'] = m['observacoes'].toString();
      }

      await _repository.criarMovimento(movData);

      final delta = tipo == 'entrada' ? valorNum : -valorNum;
      saldoDelta += delta;
      importados++;
    }

    // Atualizar saldo de uma vez
    if (saldoDelta != 0) {
      await _repository.atualizarSaldo(caixaIdInt, saldoDelta);
    }

    return {
      'message': 'Importação realizada com sucesso',
      'importados': importados,
      'total_itens': itens.length,
      'saldo_anterior': caixa.saldoAtual,
      'saldo_atual': caixa.saldoAtual + saldoDelta,
    };
  }

  Future<Map<String, dynamic>> transferencia(
    Map<String, dynamic> data,
    int usuarioId,
  ) async {
    final origemId = data['caixa_origem_id'];
    final destinoId = data['caixa_destino_id'];

    if (origemId == null || destinoId == null) {
      throw ValidationException(
          'caixa_origem_id e caixa_destino_id são obrigatórios');
    }

    final origemIdInt =
        origemId is int ? origemId : int.tryParse(origemId.toString());
    final destinoIdInt =
        destinoId is int ? destinoId : int.tryParse(destinoId.toString());

    if (origemIdInt == null || destinoIdInt == null) {
      throw ValidationException('IDs de caixa inválidos');
    }

    if (origemIdInt == destinoIdInt) {
      throw ValidationException('Caixa de origem e destino devem ser diferentes');
    }

    final origem = await _repository.findById(origemIdInt);
    if (origem == null) {
      throw NotFoundException('Caixa de origem não encontrado');
    }

    final destino = await _repository.findById(destinoIdInt);
    if (destino == null) {
      throw NotFoundException('Caixa de destino não encontrado');
    }

    final valor = data['valor'];
    if (valor == null) {
      throw ValidationException('Valor é obrigatório');
    }
    final valorNum = valor is num
        ? valor.toDouble()
        : double.tryParse(valor.toString()) ?? 0;
    if (valorNum <= 0) {
      throw ValidationException('Valor deve ser positivo');
    }

    if (origem.saldoAtual < valorNum) {
      throw ValidationException(
        'Saldo insuficiente no caixa de origem. '
        'Saldo: R\$ ${origem.saldoAtual.toStringAsFixed(2)}',
      );
    }

    final descricao = data['descricao'] as String? ??
        'Transferência de ${origem.nome} para ${destino.nome}';

    // Saída da origem
    await _repository.criarMovimento({
      'caixa_id': origemIdInt.toString(),
      'descricao': descricao,
      'valor': valorNum.toStringAsFixed(2),
      'tipo': 'saida',
      'categoria': 'transferencia',
      'referencia_id': destinoIdInt.toString(),
      'referencia_tipo': 'transferencia',
      'usuario_id': usuarioId.toString(),
    });
    await _repository.atualizarSaldo(origemIdInt, -valorNum);

    // Entrada no destino
    await _repository.criarMovimento({
      'caixa_id': destinoIdInt.toString(),
      'descricao': descricao,
      'valor': valorNum.toStringAsFixed(2),
      'tipo': 'entrada',
      'categoria': 'transferencia',
      'referencia_id': origemIdInt.toString(),
      'referencia_tipo': 'transferencia',
      'usuario_id': usuarioId.toString(),
    });
    await _repository.atualizarSaldo(destinoIdInt, valorNum);

    return {
      'message': 'Transferência realizada com sucesso',
      'valor': valorNum,
      'origem': {
        'id': origemIdInt,
        'nome': origem.nome,
        'saldo_anterior': origem.saldoAtual,
        'saldo_atual': origem.saldoAtual - valorNum,
      },
      'destino': {
        'id': destinoIdInt,
        'nome': destino.nome,
        'saldo_anterior': destino.saldoAtual,
        'saldo_atual': destino.saldoAtual + valorNum,
      },
    };
  }

  Future<Map<String, dynamic>> resumo(
    int caixaId,
    Map<String, dynamic> params,
  ) async {
    final caixa = await _repository.findById(caixaId);
    if (caixa == null) {
      throw NotFoundException('Caixa não encontrado');
    }

    final resumo = await _repository.getResumo(
      caixaId,
      dataInicio: params['data_inicio'] as String?,
      dataFim: params['data_fim'] as String?,
    );

    return {
      'caixa': caixa.toJson(),
      'total_entradas': resumo['total_entradas'],
      'total_saidas': resumo['total_saidas'],
      'saldo': (resumo['total_entradas'] as double) -
          (resumo['total_saidas'] as double),
    };
  }

  Future<Map<String, dynamic>> fechamento(
    int caixaId,
    Map<String, dynamic> params,
  ) async {
    final caixa = await _repository.findById(caixaId);
    if (caixa == null) {
      throw NotFoundException('Caixa não encontrado');
    }

    final dataInicio = params['data_inicio'] as String?;
    final dataFim = params['data_fim'] as String?;

    // Vendas por forma de pagamento
    final vendasPorForma = await _repository.getVendasPorFormaPagamento(
      caixaId,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );

    // Movimentos por categoria
    final movsPorCategoria = await _repository.getMovimentosPorCategoria(
      caixaId,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );

    // Parse vendas
    final vendasForma = vendasPorForma
        .map((r) => {
              'forma_pagamento': r['forma_pagamento'] ?? 'outros',
              'quantidade': int.parse(r['qtd'] ?? '0'),
              'total': double.parse(r['total'] ?? '0'),
            })
        .toList();

    // Parse movimentos
    final movsCat = movsPorCategoria
        .map((r) => {
              'tipo': r['tipo'],
              'categoria': r['categoria'] ?? 'manual',
              'quantidade': int.parse(r['qtd'] ?? '0'),
              'total': double.parse(r['total'] ?? '0'),
            })
        .toList();

    // Calculate totals
    double totalEntradas = 0;
    double totalSaidas = 0;
    for (final m in movsCat) {
      if (m['tipo'] == 'entrada') totalEntradas += m['total'] as double;
      if (m['tipo'] == 'saida') totalSaidas += m['total'] as double;
    }

    return {
      'caixa': caixa.toJson(),
      'vendas_por_forma_pagamento': vendasForma,
      'movimentos_por_categoria': movsCat,
      'total_entradas': totalEntradas,
      'total_saidas': totalSaidas,
      'saldo_esperado': totalEntradas - totalSaidas,
    };
  }

  // ── Abrir Caixa ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> abrirCaixa(
    int caixaId,
    Map<String, dynamic> data,
    int usuarioId,
  ) async {
    final caixa = await _repository.findById(caixaId);
    if (caixa == null) {
      throw NotFoundException('Caixa não encontrado');
    }

    if (caixa.status == 'aberto') {
      throw ValidationException('Caixa já está aberto');
    }

    // Valor inicial (fundo de troco)
    final valor = data['valor_inicial'];
    final valorNum = valor is num
        ? valor.toDouble()
        : double.tryParse(valor?.toString() ?? '') ?? 0;

    if (valorNum < 0) {
      throw ValidationException('Valor inicial não pode ser negativo');
    }

    // Zerar saldo e definir o fundo de troco
    await _repository.definirSaldo(caixaId, valorNum);

    // Registrar movimento de abertura se houver valor
    if (valorNum > 0) {
      await _repository.criarMovimento({
        'caixa_id': caixaId.toString(),
        'descricao': 'Abertura de caixa - Fundo de troco',
        'valor': valorNum.toStringAsFixed(2),
        'tipo': 'entrada',
        'categoria': 'abertura',
        'usuario_id': usuarioId.toString(),
      });
    }

    // Marcar como aberto
    await _repository.atualizarStatus(caixaId, 'aberto');

    return {
      'message': 'Caixa aberto com sucesso',
      'caixa_id': caixaId,
      'valor_inicial': valorNum,
      'status': 'aberto',
    };
  }

  // ── Fechar Caixa (persistir fechamento) ─────────────────────────────

  Future<Map<String, dynamic>> fecharCaixa(
    int caixaId,
    Map<String, dynamic> data,
    int usuarioId,
  ) async {
    final caixa = await _repository.findById(caixaId);
    if (caixa == null) {
      throw NotFoundException('Caixa não encontrado');
    }

    if (caixa.status == 'fechado') {
      throw ValidationException('Caixa já está fechado');
    }

    final dataInicio = data['data_inicio'] as String?;
    final dataFim = data['data_fim'] as String?;
    if (dataInicio == null || dataFim == null) {
      throw ValidationException('data_inicio e data_fim são obrigatórios');
    }

    // Buscar saldo inicial (do movimento de abertura)
    final saldoInicial = data['saldo_inicial'] is num
        ? (data['saldo_inicial'] as num).toDouble()
        : double.tryParse(data['saldo_inicial']?.toString() ?? '0') ?? 0;

    // Calcular totais do período
    final movsPorCategoria = await _repository.getMovimentosPorCategoria(
      caixaId,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );

    double totalEntradas = 0;
    double totalSaidas = 0;
    for (final m in movsPorCategoria) {
      final tipo = m['tipo'];
      final total = double.parse(m['total'] ?? '0');
      if (tipo == 'entrada') totalEntradas += total;
      if (tipo == 'saida') totalSaidas += total;
    }
    final saldoEsperado = totalEntradas - totalSaidas;

    // Saldo informado (opcional)
    double? saldoInformado;
    double? diferenca;
    if (data['saldo_informado'] != null) {
      final v = data['saldo_informado'];
      saldoInformado =
          v is num ? v.toDouble() : double.tryParse(v.toString());
      if (saldoInformado != null) {
        diferenca = saldoInformado - saldoEsperado;
      }
    }

    final fechData = <String, String>{
      'caixa_id': caixaId.toString(),
      'saldo_inicial': saldoInicial.toStringAsFixed(2),
      'usuario_id': usuarioId.toString(),
      'data_inicio': dataInicio,
      'data_fim': dataFim,
      'total_entradas': totalEntradas.toStringAsFixed(2),
      'total_saidas': totalSaidas.toStringAsFixed(2),
      'saldo_esperado': saldoEsperado.toStringAsFixed(2),
    };

    if (saldoInformado != null) {
      fechData['saldo_informado'] = saldoInformado.toStringAsFixed(2);
    }
    if (diferenca != null) {
      fechData['diferenca'] = diferenca.toStringAsFixed(2);
    }
    if (data['observacoes'] != null &&
        (data['observacoes'] as String).isNotEmpty) {
      fechData['observacoes'] = data['observacoes'] as String;
    }

    final id = await _repository.criarFechamento(fechData);

    // Marcar como fechado
    await _repository.atualizarStatus(caixaId, 'fechado');

    return {
      'id': id,
      'message': 'Fechamento registrado com sucesso',
      'caixa': caixa.toJson(),
      'saldo_inicial': saldoInicial,
      'total_entradas': totalEntradas,
      'total_saidas': totalSaidas,
      'saldo_esperado': saldoEsperado,
      'saldo_informado': saldoInformado,
      'diferenca': diferenca,
    };
  }

  Future<List<Map<String, dynamic>>> listarFechamentos(int caixaId) async {
    final caixa = await _repository.findById(caixaId);
    if (caixa == null) {
      throw NotFoundException('Caixa não encontrado');
    }

    final fechamentos = await _repository.findFechamentos(caixaId);
    return fechamentos.map((f) => f.toJson()).toList();
  }
}
