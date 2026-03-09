import 'package:xml/xml.dart';
import '../../core/exceptions/api_exception.dart';
import 'compras_repository.dart';

class ComprasService {
  final ComprasRepository _repository;

  ComprasService(this._repository);

  Future<Map<String, dynamic>> listar(Map<String, dynamic> params) async {
    final fornecedorId = params['fornecedor_id'] as int?;
    final dataInicio = params['data_inicio'] as String?;
    final dataFim = params['data_fim'] as String?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final compras = await _repository.findAll(
      fornecedorId: fornecedorId,
      dataInicio: dataInicio,
      dataFim: dataFim,
      limit: limit,
      offset: offset,
    );

    final total = await _repository.count(
      fornecedorId: fornecedorId,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );

    return {
      'items': compras.map((c) => c.toJson()).toList(),
      'total': total,
    };
  }

  Future<Map<String, dynamic>> obterPorId(int id) async {
    final compra = await _repository.findById(id);
    if (compra == null) {
      throw NotFoundException('Compra não encontrada');
    }

    final itens = await _repository.findItensByCompraId(id);
    final compraJson = compra.toJson();
    compraJson['itens'] = itens.map((i) => i.toJson()).toList();
    return compraJson;
  }

  Future<Map<String, dynamic>> criar(
    Map<String, dynamic> data,
    int usuarioId,
  ) async {
    // Validações
    final fornecedorId = _parseInt(data['fornecedor_id']);
    if (fornecedorId == null || fornecedorId == 0) {
      throw ValidationException('Fornecedor é obrigatório');
    }

    final itens = data['itens'] as List<dynamic>?;
    if (itens == null || itens.isEmpty) {
      throw ValidationException('A compra deve ter pelo menos um item');
    }

    final dataCompraRaw = data['data_compra']?.toString() ??
        DateTime.now().toIso8601String();
    // Converter ISO 8601 (com T e Z) para formato MySQL 'YYYY-MM-DD HH:MM:SS'
    final dataCompra = _toMySqlDateTime(dataCompraRaw);

    final formaPagamento = data['forma_pagamento']?.toString();

    // Processar itens
    double valorBruto = 0;
    final itensProcessados = <Map<String, dynamic>>[];

    for (final item in itens) {
      final itemMap = item as Map<String, dynamic>;
      final produtoId = _parseInt(itemMap['produto_id']);

      if (produtoId == null || produtoId == 0) {
        throw ValidationException('produto_id é obrigatório em cada item');
      }

      final produto = await _repository.getProduto(produtoId);
      if (produto == null) {
        throw NotFoundException('Produto $produtoId não encontrado');
      }

      final quantidade = _parseDouble(itemMap['quantidade']) ?? 1;
      if (quantidade <= 0) {
        throw ValidationException('Quantidade deve ser positiva');
      }

      final precoUnitario = _parseDouble(itemMap['preco_unitario']) ?? 0;
      final totalItem = quantidade * precoUnitario;

      itensProcessados.add({
        'produto_id': produtoId,
        'quantidade': quantidade,
        'preco_unitario': precoUnitario,
        'total': totalItem,
      });

      valorBruto += totalItem;
    }

    final valorFinal = _parseDouble(data['valor_final']) ?? valorBruto;

    // Criar a compra
    final compraData = <String, String>{
      'fornecedor_id': fornecedorId.toString(),
      'data_compra': dataCompra,
      'valor_bruto': valorBruto.toStringAsFixed(2),
      'valor_final': valorFinal.toStringAsFixed(2),
    };

    if (formaPagamento != null && formaPagamento.isNotEmpty) {
      compraData['forma_pagamento'] = formaPagamento;
    }
    if (data['chave_nfe'] != null) {
      compraData['chave_nfe'] = data['chave_nfe'].toString();
    }
    if (data['xml_importado'] != null) {
      compraData['xml_importado'] = data['xml_importado'] == true ? '1' : '0';
    }
    if (data['observacoes'] != null) {
      compraData['observacoes'] = data['observacoes'].toString();
    }

    final compraId = await _repository.create(compraData);

    // Criar itens e dar entrada no estoque
    for (final item in itensProcessados) {
      await _repository.createItem({
        'compra_id': compraId.toString(),
        'produto_id': item['produto_id'].toString(),
        'quantidade': (item['quantidade'] as double).toString(),
        'preco_unitario':
            (item['preco_unitario'] as double).toStringAsFixed(2),
        'total': (item['total'] as double).toStringAsFixed(2),
      });

      // Dar entrada no estoque
      final qtd = item['quantidade'] as double;
      await _repository.atualizarEstoque(
        item['produto_id'] as int,
        qtd,
      );

      // Registrar histórico de estoque
      await _repository.registrarHistoricoEstoque({
        'produto_id': item['produto_id'].toString(),
        'tipo': 'entrada',
        'ocorrencia': 'compra',
        'quantidade': qtd.toString(),
        'referencia_id': compraId.toString(),
        'referencia_tipo': 'compra',
        'usuario_id': usuarioId.toString(),
      });
    }

    return await obterPorId(compraId);
  }

  Future<Map<String, dynamic>> atualizar(
    int id,
    Map<String, dynamic> data,
    int usuarioId,
  ) async {
    final compra = await _repository.findById(id);
    if (compra == null) {
      throw NotFoundException('Compra não encontrada');
    }

    // Reverter estoque dos itens antigos
    final itensAntigos = await _repository.findItensByCompraId(id);
    for (final item in itensAntigos) {
      await _repository.atualizarEstoque(
        item.produtoId,
        -item.quantidade,
      );
      await _repository.registrarHistoricoEstoque({
        'produto_id': item.produtoId.toString(),
        'tipo': 'saida',
        'ocorrencia': 'ajuste_compra',
        'quantidade': item.quantidade.toString(),
        'referencia_id': id.toString(),
        'referencia_tipo': 'ajuste_compra',
        'usuario_id': usuarioId.toString(),
      });
    }

    // Deletar itens antigos
    await _repository.deleteItensByCompraId(id);

    // Processar novos itens
    final itens = data['itens'] as List<dynamic>?;
    if (itens == null || itens.isEmpty) {
      throw ValidationException('A compra deve ter pelo menos um item');
    }

    double valorBruto = 0;
    final itensProcessados = <Map<String, dynamic>>[];

    for (final item in itens) {
      final itemMap = item as Map<String, dynamic>;
      final produtoId = _parseInt(itemMap['produto_id']);

      if (produtoId == null || produtoId == 0) {
        throw ValidationException('produto_id é obrigatório em cada item');
      }

      final produto = await _repository.getProduto(produtoId);
      if (produto == null) {
        throw NotFoundException('Produto $produtoId não encontrado');
      }

      final quantidade = _parseDouble(itemMap['quantidade']) ?? 1;
      if (quantidade <= 0) {
        throw ValidationException('Quantidade deve ser positiva');
      }
      final precoUnitario = _parseDouble(itemMap['preco_unitario']) ?? 0;
      final totalItem = quantidade * precoUnitario;

      itensProcessados.add({
        'produto_id': produtoId,
        'quantidade': quantidade,
        'preco_unitario': precoUnitario,
        'total': totalItem,
      });

      valorBruto += totalItem;
    }

    final valorFinal = _parseDouble(data['valor_final']) ?? valorBruto;

    // Atualizar compra
    final compraUpdate = <String, String>{
      'fornecedor_id': (data['fornecedor_id'] ?? compra.fornecedorId).toString(),
      'data_compra': _toMySqlDateTime(data['data_compra']?.toString() ??
          compra.dataCompra.toIso8601String()),
      'valor_bruto': valorBruto.toStringAsFixed(2),
      'valor_final': valorFinal.toStringAsFixed(2),
    };

    if (data.containsKey('forma_pagamento')) {
      compraUpdate['forma_pagamento'] =
          data['forma_pagamento']?.toString() ?? '';
    }
    if (data.containsKey('chave_nfe')) {
      compraUpdate['chave_nfe'] = data['chave_nfe']?.toString() ?? '';
    }
    if (data.containsKey('observacoes')) {
      compraUpdate['observacoes'] = data['observacoes']?.toString() ?? '';
    }

    await _repository.update(id, compraUpdate);

    // Criar novos itens e dar entrada no estoque
    for (final item in itensProcessados) {
      await _repository.createItem({
        'compra_id': id.toString(),
        'produto_id': item['produto_id'].toString(),
        'quantidade': (item['quantidade'] as double).toString(),
        'preco_unitario':
            (item['preco_unitario'] as double).toStringAsFixed(2),
        'total': (item['total'] as double).toStringAsFixed(2),
      });

      final qtd = item['quantidade'] as double;
      await _repository.atualizarEstoque(item['produto_id'] as int, qtd);

      await _repository.registrarHistoricoEstoque({
        'produto_id': item['produto_id'].toString(),
        'tipo': 'entrada',
        'ocorrencia': 'compra',
        'quantidade': qtd.toString(),
        'referencia_id': id.toString(),
        'referencia_tipo': 'compra',
        'usuario_id': usuarioId.toString(),
      });
    }

    return await obterPorId(id);
  }

  Future<void> excluir(int id, int usuarioId) async {
    final compra = await _repository.findById(id);
    if (compra == null) {
      throw NotFoundException('Compra não encontrada');
    }

    // Reverter estoque
    final itens = await _repository.findItensByCompraId(id);
    for (final item in itens) {
      await _repository.atualizarEstoque(
        item.produtoId,
        -item.quantidade,
      );
      await _repository.registrarHistoricoEstoque({
        'produto_id': item.produtoId.toString(),
        'tipo': 'saida',
        'ocorrencia': 'exclusao_compra',
        'quantidade': item.quantidade.toString(),
        'referencia_id': id.toString(),
        'referencia_tipo': 'exclusao_compra',
        'usuario_id': usuarioId.toString(),
      });
    }

    await _repository.delete(id);
  }

  /// Parseia XML de NF-e e retorna dados extraídos com match de produtos/fornecedor.
  Future<Map<String, dynamic>> parsearXmlNfe(String xmlContent) async {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(xmlContent);
    } catch (e) {
      throw ValidationException('XML inválido: $e');
    }

    // Localizar o elemento infNFe (pode estar em nfeProc/NFe/infNFe ou NFe/infNFe)
    final infNFe = doc.findAllElements('infNFe').firstOrNull;
    if (infNFe == null) {
      throw ValidationException(
          'XML não contém elemento infNFe. Verifique se é um XML de NF-e válido.');
    }

    // Chave de acesso (atributo Id do infNFe, ex: "NFe35...")
    final idAttr = infNFe.getAttribute('Id') ?? '';
    final chaveNfe = idAttr.startsWith('NFe')
        ? idAttr.substring(3)
        : idAttr;

    // Verificar se já existe compra com esta chave NF-e
    if (chaveNfe.isNotEmpty) {
      final existente = await _repository.buscarCompraPorChaveNfe(chaveNfe);
      if (existente != null) {
        throw ValidationException(
            'Esta NF-e já foi importada anteriormente (Compra #${existente['id']}).');
      }
    }

    // --- Identificação (ide) ---
    final ide = infNFe.findElements('ide').firstOrNull;
    final nNF = _xmlText(ide, 'nNF');
    final serie = _xmlText(ide, 'serie');
    final dhEmi = _xmlText(ide, 'dhEmi');

    // Usar data de emissão da NF-e como data da compra (fallback: agora)
    String dataCompraParaSalvar;
    if (dhEmi.isNotEmpty) {
      dataCompraParaSalvar = _toMySqlDateTime(dhEmi);
    } else {
      dataCompraParaSalvar = _toMySqlDateTime(DateTime.now().toIso8601String());
    }

    // --- Emitente (emit) ---
    final emit = infNFe.findElements('emit').firstOrNull;
    final emitCnpj = _xmlText(emit, 'CNPJ');
    final emitNome = _xmlText(emit, 'xNome');
    final emitFantasia = _xmlText(emit, 'xFant');

    // Tentar encontrar fornecedor pelo CNPJ, ou criar automaticamente
    int? fornecedorId;
    String? fornecedorNome;
    if (emitCnpj.isNotEmpty) {
      final cnpjLimpo = emitCnpj.replaceAll(RegExp(r'[^\d]'), '');
      final cnpjFormatado = cnpjLimpo.length == 14
          ? '${cnpjLimpo.substring(0, 2)}.${cnpjLimpo.substring(2, 5)}.${cnpjLimpo.substring(5, 8)}/${cnpjLimpo.substring(8, 12)}-${cnpjLimpo.substring(12)}'
          : cnpjLimpo;

      var forn = await _repository.buscarFornecedorPorCnpj(cnpjLimpo);
      forn ??= await _repository.buscarFornecedorPorCnpj(cnpjFormatado);

      if (forn != null) {
        fornecedorId = int.tryParse(forn['id'] ?? '');
        fornecedorNome = forn['razao_social'] ?? forn['nome_fantasia'];
      } else {
        // Auto-criar fornecedor a partir dos dados da NF-e
        final fornData = <String, String>{
          'razao_social': emitNome.isNotEmpty ? emitNome : 'Fornecedor $cnpjFormatado',
          'cnpj': cnpjFormatado,
        };
        if (emitFantasia.isNotEmpty) {
          fornData['nome_fantasia'] = emitFantasia;
        }
        try {
          fornecedorId = await _repository.criarFornecedor(fornData);
          fornecedorNome = emitNome.isNotEmpty ? emitNome : emitFantasia;
        } catch (e) {
          // Se falhou por CNPJ duplicado, tentar buscar novamente
          print('Aviso: falha ao criar fornecedor "$cnpjFormatado": $e');
          var retry = await _repository.buscarFornecedorPorCnpj(cnpjFormatado);
          retry ??= await _repository.buscarFornecedorPorCnpj(cnpjLimpo);
          if (retry != null) {
            fornecedorId = int.tryParse(retry['id'] ?? '');
            fornecedorNome = retry['razao_social'] ?? retry['nome_fantasia'];
          }
        }
      }
    }

    // --- Itens (det/prod) ---
    final detElements = infNFe.findElements('det');
    final itens = <Map<String, dynamic>>[];

    for (final det in detElements) {
      final prod = det.findElements('prod').firstOrNull;
      if (prod == null) continue;

      final cProd = _xmlText(prod, 'cProd');
      final cEAN = _xmlText(prod, 'cEAN');
      final cEANTrib = _xmlText(prod, 'cEANTrib');
      final xProd = _xmlText(prod, 'xProd');
      final qCom = double.tryParse(_xmlText(prod, 'qCom')) ?? 0;
      final vUnCom = double.tryParse(_xmlText(prod, 'vUnCom')) ?? 0;
      final vProd = double.tryParse(_xmlText(prod, 'vProd')) ?? 0;

      // Validar quantidade e preço
      if (qCom <= 0) continue; // Pular itens sem quantidade válida
      final uCom = _xmlText(prod, 'uCom');
      final ncm = _xmlText(prod, 'NCM');

      // Tentar encontrar produto pelo código de barras (EAN), ou criar automaticamente
      int? produtoId;
      String? produtoDescricao;
      bool autoCriado = false;
      final barcode = cEAN.isNotEmpty && cEAN != 'SEM GTIN' ? cEAN : cEANTrib;

      if (barcode.isNotEmpty && barcode != 'SEM GTIN') {
        final produto = await _repository.buscarProdutoPorBarcode(barcode);
        if (produto != null) {
          produtoId = int.tryParse(produto['id'] ?? '');
          produtoDescricao = produto['descricao'];
        } else {
          // Verificar se existe produto inativo com mesmo barcode
          final produtoInativo = await _repository.buscarProdutoPorBarcodeIncluindoInativos(barcode);
          if (produtoInativo != null) {
            produtoId = int.tryParse(produtoInativo['id'] ?? '');
            produtoDescricao = produtoInativo['descricao'];
          }
        }
      }

      // Tentar encontrar por codigo_interno (cProd) como fallback
      if (produtoId == null && cProd.isNotEmpty) {
        final produtoPorCodigo = await _repository.buscarProdutoPorCodigoInterno(cProd);
        if (produtoPorCodigo != null) {
          produtoId = int.tryParse(produtoPorCodigo['id'] ?? '');
          produtoDescricao = produtoPorCodigo['descricao'];
        }
      }

      // Auto-criar produto se não encontrado
      if (produtoId == null && xProd.isNotEmpty) {
        final prodData = <String, String>{
          'descricao': xProd,
          'preco_custo': vUnCom.toStringAsFixed(2),
          'preco_venda': vUnCom.toStringAsFixed(2),
          'unidade': _normalizarUnidade(uCom),
          'estoque_atual': '0',
          'estoque_minimo': '0',
          'margem_lucro': '0.00',
          'ativo': '1',
        };
        if (barcode.isNotEmpty && barcode != 'SEM GTIN') {
          prodData['codigo_barras'] = barcode;
        }
        if (ncm.isNotEmpty) {
          prodData['ncm_code'] = ncm;
        }
        if (cProd.isNotEmpty) {
          // Verificar se já existe outro produto com esse codigo_interno
          final existente = await _repository.buscarProdutoPorCodigoInterno(cProd);
          if (existente == null) {
            prodData['codigo_interno'] = cProd;
          }
        }
        if (fornecedorId != null) {
          prodData['fornecedor_id'] = fornecedorId.toString();
        }
        try {
          produtoId = await _repository.criarProduto(prodData);
          produtoDescricao = xProd;
          autoCriado = true;
        } catch (e) {
          // Se falhou por duplicidade, tentar buscar novamente
          print('Aviso: falha ao criar produto "$xProd": $e');
          if (barcode.isNotEmpty && barcode != 'SEM GTIN') {
            final retry = await _repository.buscarProdutoPorBarcodeIncluindoInativos(barcode);
            if (retry != null) {
              produtoId = int.tryParse(retry['id'] ?? '');
              produtoDescricao = retry['descricao'];
            }
          }
        }
      }

      itens.add({
        'codigo_produto_nfe': cProd,
        'codigo_barras': barcode.isNotEmpty && barcode != 'SEM GTIN' ? barcode : null,
        'descricao_nfe': xProd,
        'quantidade': qCom,
        'preco_unitario': vUnCom,
        'total': vProd,
        'unidade': uCom,
        'ncm': ncm,
        'produto_id': produtoId,
        'produto_descricao': produtoDescricao,
        'auto_criado': autoCriado,
      });
    }

    // --- Totais ---
    final total = infNFe.findElements('total').firstOrNull;
    final icmsTot = total?.findElements('ICMSTot').firstOrNull;
    final vProdTotal = double.tryParse(_xmlText(icmsTot, 'vProd')) ?? 0;
    final vDesc = double.tryParse(_xmlText(icmsTot, 'vDesc')) ?? 0;
    final vNF = double.tryParse(_xmlText(icmsTot, 'vNF')) ?? 0;
    final vFrete = double.tryParse(_xmlText(icmsTot, 'vFrete')) ?? 0;
    final vOutro = double.tryParse(_xmlText(icmsTot, 'vOutro')) ?? 0;

    return {
      'fornecedor': {
        'cnpj': emitCnpj,
        'nome': emitNome,
        'fantasia': emitFantasia,
        'fornecedor_id': fornecedorId,
        'fornecedor_nome': fornecedorNome,
      },
      'nfe': {
        'numero': nNF,
        'serie': serie,
        'data_emissao': dhEmi,
        'data_compra': dataCompraParaSalvar,
        'chave_nfe': chaveNfe,
      },
      'itens': itens,
      'totais': {
        'valor_produtos': vProdTotal,
        'desconto': vDesc,
        'frete': vFrete,
        'outras_despesas': vOutro,
        'valor_nota': vNF,
      },
    };
  }

  /// Extrai texto de um elemento filho XML.
  String _xmlText(XmlElement? parent, String tagName) {
    if (parent == null) return '';
    final el = parent.findElements(tagName).firstOrNull;
    return el?.innerText.trim() ?? '';
  }

  String _toMySqlDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.year.toString().padLeft(4, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString.replaceAll('T', ' ').replaceAll('Z', '').split('.').first;
    }
  }

  String _normalizarUnidade(String uCom) {
    if (uCom.isEmpty) return 'un';
    final u = uCom.trim().toLowerCase();
    const mapa = {
      'pca': 'pc', 'pç': 'pc', 'peca': 'pc', 'peça': 'pc',
      'und': 'un', 'unid': 'un', 'unidade': 'un',
      'kilo': 'kg', 'quilo': 'kg',
      'litro': 'l', 'lt': 'l',
      'metro': 'm', 'mt': 'm',
      'caixa': 'cx', 'pacote': 'pct', 'duzia': 'dz',
      'par': 'par', 'rolo': 'rl', 'galao': 'gl',
      'grama': 'g', 'gr': 'g',
    };
    return mapa[u] ?? u;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
