import '../../core/exceptions/api_exception.dart';

import 'estoque_repository.dart';

class EstoqueService {
  final EstoqueRepository _repository;

  EstoqueService(this._repository);

  Future<List<Map<String, dynamic>>> getPosicao() async {
    final results = await _repository.getPosicao();
    return results.map((row) => _parsePosicaoRow(row)).toList();
  }

  Future<List<Map<String, dynamic>>> getAbaixoMinimo() async {
    final results = await _repository.getAbaixoMinimo();
    return results.map((row) => _parsePosicaoRow(row)).toList();
  }

  Future<Map<String, dynamic>> getEstoqueProduto(int produtoId) async {
    final result = await _repository.getEstoqueProduto(produtoId);
    if (result == null) {
      throw NotFoundException('Produto não encontrado');
    }
    return _parsePosicaoRow(result);
  }

  Future<Map<String, dynamic>> getHistorico(
      Map<String, dynamic> params) async {
    final produtoId = params['produto_id'] as int?;
    final tipo = params['tipo'] as String?;
    final ocorrencia = params['ocorrencia'] as String?;
    final dataInicio = params['data_inicio'] as String?;
    final dataFim = params['data_fim'] as String?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final results = await _repository.getHistorico(
      produtoId: produtoId,
      tipo: tipo,
      ocorrencia: ocorrencia,
      dataInicio: dataInicio,
      dataFim: dataFim,
      limit: limit,
      offset: offset,
    );

    final items = results
        .map((row) => {
              'id': row['id'] != null ? int.parse(row['id']!) : null,
              'produto_id': row['produto_id'] != null
                  ? int.parse(row['produto_id']!)
                  : null,
              'produto_descricao': row['produto_descricao'],
              'tipo': row['tipo'],
              'ocorrencia': row['ocorrencia'],
              'quantidade': row['quantidade'] != null
                  ? double.parse(row['quantidade']!)
                  : null,
              'referencia_id': row['referencia_id'] != null
                  ? int.parse(row['referencia_id']!)
                  : null,
              'referencia_tipo': row['referencia_tipo'],
              'observacoes': row['observacoes'],
              'usuario_id': row['usuario_id'] != null
                  ? int.parse(row['usuario_id']!)
                  : null,
              'criado_em': row['criado_em'],
            })
        .toList();

    return {
      'items': items,
    };
  }

  Future<Map<String, dynamic>> registrarMovimento(
    Map<String, dynamic> data,
    int usuarioId,
  ) async {
    // Validacoes
    final produtoId = data['produto_id'];
    if (produtoId == null) {
      throw ValidationException('produto_id é obrigatório');
    }

    final produtoIdInt =
        produtoId is int ? produtoId : int.tryParse(produtoId.toString());
    if (produtoIdInt == null) {
      throw ValidationException('produto_id inválido');
    }

    final tipo = data['tipo'] as String?;
    if (tipo == null || (tipo != 'entrada' && tipo != 'saida')) {
      throw ValidationException(
          'tipo é obrigatório e deve ser "entrada" ou "saida"');
    }

    final quantidade = data['quantidade'];
    if (quantidade == null) {
      throw ValidationException('quantidade é obrigatória');
    }

    final quantidadeNum = quantidade is num
        ? quantidade.toDouble()
        : double.tryParse(quantidade.toString()) ?? 0;

    if (quantidadeNum <= 0) {
      throw ValidationException('quantidade deve ser positiva');
    }

    // Buscar estoque atual
    final produto = await _repository.getEstoqueProduto(produtoIdInt);
    if (produto == null) {
      throw NotFoundException('Produto não encontrado');
    }

    final estoqueAtual = int.parse(produto['estoque_atual'] ?? '0');
    int novaQtd;

    if (tipo == 'entrada') {
      novaQtd = estoqueAtual + quantidadeNum.toInt();
    } else {
      novaQtd = estoqueAtual - quantidadeNum.toInt();
      if (novaQtd < 0) {
        throw ValidationException(
          'Estoque insuficiente. Estoque atual: $estoqueAtual',
        );
      }
    }

    // Atualizar estoque
    await _repository.atualizarEstoque(produtoIdInt, novaQtd);

    // Registrar historico
    final dbData = <String, String>{
      'produto_id': produtoIdInt.toString(),
      'tipo': tipo,
      'ocorrencia': (data['ocorrencia'] ?? 'movimentacao_manual').toString(),
      'quantidade': quantidadeNum.toString(),
      'usuario_id': usuarioId.toString(),
    };

    if (data['referencia_id'] != null) {
      dbData['referencia_id'] = data['referencia_id'].toString();
    }
    if (data['referencia_tipo'] != null) {
      dbData['referencia_tipo'] = data['referencia_tipo'].toString();
    }
    if (data['observacoes'] != null) {
      dbData['observacoes'] = data['observacoes'].toString();
    }

    await _repository.registrarMovimento(dbData);

    return {
      'message': 'Movimento registrado com sucesso',
      'estoque_anterior': estoqueAtual,
      'estoque_atual': novaQtd,
    };
  }

  Map<String, dynamic> _parsePosicaoRow(Map<String, String?> row) {
    return {
      'id': row['id'] != null ? int.parse(row['id']!) : null,
      'descricao': row['descricao'],
      'estoque_atual':
          row['estoque_atual'] != null ? int.parse(row['estoque_atual']!) : 0,
      'estoque_minimo': row['estoque_minimo'] != null
          ? int.parse(row['estoque_minimo']!)
          : 0,
      'ativo': row['ativo'] == '1',
    };
  }
}
