import 'dart:convert';
import 'dart:io';

import '../../core/exceptions/api_exception.dart';

import 'produto_model.dart';
import 'produtos_repository.dart';

class ProdutosService {
  final ProdutosRepository _repository;

  ProdutosService(this._repository);

  Future<Map<String, dynamic>> listar(Map<String, dynamic> params) async {
    final busca = params['busca'] as String?;
    final categoriaId = params['categoria_id'] as int?;
    final ativo = params['ativo'] as bool?;
    final tamanho = params['tamanho'] as String?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;

    final items = await _repository.findAll(
      busca: busca,
      categoriaId: categoriaId,
      ativo: ativo,
      tamanho: tamanho,
      limit: limit,
      offset: offset,
    );

    final total = await _repository.count(
      busca: busca,
      categoriaId: categoriaId,
      ativo: ativo,
      tamanho: tamanho,
    );

    // Calculate virtual stock for combos
    final jsonItems = <Map<String, dynamic>>[];
    for (final p in items) {
      final json = p.toJson();
      if (p.isCombo) {
        json['estoque_disponivel'] =
            await _repository.calcularEstoqueCombo(p.id!);
      }
      jsonItems.add(json);
    }

    return {
      'items': jsonItems,
      'total': total,
    };
  }

  Future<Produto> obterPorId(int id) async {
    final produto = await _repository.findById(id);
    if (produto == null) {
      throw NotFoundException('Produto não encontrado');
    }
    return produto;
  }

  /// Returns produto JSON with combo details if applicable.
  Future<Map<String, dynamic>> obterPorIdComDetalhes(int id) async {
    final produto = await obterPorId(id);
    final json = produto.toJson();
    if (produto.isCombo) {
      final comboItens = await _repository.findComboItens(id);
      json['combo_itens'] = comboItens.map((c) => c.toJson()).toList();
      json['estoque_disponivel'] =
          await _repository.calcularEstoqueCombo(id);
    }
    return json;
  }

  Future<Produto> buscarPorCodigoBarras(String codigo) async {
    final produto = await _repository.findByBarcode(codigo);
    if (produto == null) {
      throw NotFoundException('Produto não encontrado com este código de barras');
    }
    return produto;
  }

  Future<Produto> buscarPorCodigoInterno(String codigo) async {
    final produto = await _repository.findByCodigoInterno(codigo);
    if (produto == null) {
      throw NotFoundException(
          'Produto não encontrado com este código interno');
    }
    return produto;
  }

  Future<Produto> criar(Map<String, dynamic> data) async {
    // Validações
    final descricao = data['descricao'];
    if (descricao == null || (descricao is String && descricao.isEmpty)) {
      throw ValidationException('Descrição é obrigatória');
    }

    final precoVenda = data['preco_venda'];
    if (precoVenda == null) {
      throw ValidationException('Preço de venda é obrigatório');
    }

    final precoVendaNum = precoVenda is num
        ? precoVenda.toDouble()
        : double.tryParse(precoVenda.toString()) ?? 0;

    if (precoVendaNum <= 0) {
      throw ValidationException('Preço de venda deve ser positivo');
    }

    final precoCustoNum = data['preco_custo'] != null
        ? (data['preco_custo'] is num
            ? (data['preco_custo'] as num).toDouble()
            : double.tryParse(data['preco_custo'].toString()) ?? 0)
        : 0.0;

    // Calcular margem de lucro
    double? margemLucro;
    if (precoCustoNum > 0) {
      margemLucro = ((precoVendaNum - precoCustoNum) / precoCustoNum) * 100;
    }

    // Preparar dados com defaults
    final dbData = <String, String>{};

    if (data['codigo_barras'] != null) {
      dbData['codigo_barras'] = data['codigo_barras'].toString();
    }
    if (data['codigo_interno'] != null) {
      dbData['codigo_interno'] = data['codigo_interno'].toString();
    }
    dbData['descricao'] = descricao.toString();
    if (data['detalhes'] != null) {
      dbData['detalhes'] = data['detalhes'].toString();
    }
    if (data['categoria_id'] != null) {
      dbData['categoria_id'] = data['categoria_id'].toString();
    }
    if (data['ncm_code'] != null) {
      dbData['ncm_code'] = data['ncm_code'].toString();
    }
    if (data['tributacao'] != null) {
      dbData['tributacao'] = data['tributacao'].toString();
    }
    if (data['fornecedor_id'] != null) {
      dbData['fornecedor_id'] = data['fornecedor_id'].toString();
    }
    dbData['preco_custo'] = precoCustoNum.toString();
    dbData['preco_venda'] = precoVendaNum.toString();
    if (margemLucro != null) {
      dbData['margem_lucro'] = margemLucro.toStringAsFixed(2);
    }
    dbData['unidade'] = (data['unidade'] ?? 'un').toString();
    if (data['tamanho'] != null && data['tamanho'].toString().isNotEmpty) {
      dbData['tamanho'] = data['tamanho'].toString();
    }
    dbData['estoque_atual'] = (data['estoque_atual'] ?? '0').toString();
    dbData['estoque_minimo'] = (data['estoque_minimo'] ?? '0').toString();
    if (data['imagem_path'] != null) {
      dbData['imagem_path'] = data['imagem_path'].toString();
    }
    if (data['thumbnail_path'] != null) {
      dbData['thumbnail_path'] = data['thumbnail_path'].toString();
    }
    dbData['ativo'] = (data['ativo'] ?? '1').toString();
    dbData['bloqueado'] = (data['bloqueado'] ?? '0').toString();

    final isCombo = data['is_combo'] == true || data['is_combo'] == 1;
    if (isCombo) {
      dbData['is_combo'] = '1';
      dbData['estoque_atual'] = '0';
      dbData['estoque_minimo'] = '0';
      dbData['unidade'] = (data['unidade'] ?? 'kit').toString();
    }

    // Validate combo components before creating
    if (isCombo) {
      if (data['combo_itens'] is! List ||
          (data['combo_itens'] as List).isEmpty) {
        throw ValidationException(
            'Um combo deve ter pelo menos um componente');
      }
      final comboItens = (data['combo_itens'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      await _validarComboItens(null, comboItens);
    }

    final id = await _repository.create(dbData);

    // Save combo components
    if (isCombo) {
      final comboItens = (data['combo_itens'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      await _repository.replaceComboItens(id, comboItens);
    }

    return obterPorId(id);
  }

  Future<Produto> atualizar(int id, Map<String, dynamic> data) async {
    // Verificar se existe
    await obterPorId(id);

    final dbData = <String, String>{};

    // Copiar campos fornecidos
    final allowedFields = [
      'codigo_barras',
      'codigo_interno',
      'descricao',
      'detalhes',
      'categoria_id',
      'ncm_code',
      'tributacao',
      'fornecedor_id',
      'preco_custo',
      'preco_venda',
      'unidade',
      'tamanho',
      'estoque_atual',
      'estoque_minimo',
      'imagem_path',
      'thumbnail_path',
      'ativo',
      'bloqueado',
    ];

    for (final field in allowedFields) {
      if (data.containsKey(field) && data[field] != null) {
        dbData[field] = data[field].toString();
      }
    }

    // Recalcular margem se preços mudaram
    final precoVenda = data['preco_venda'] != null
        ? (data['preco_venda'] is num
            ? (data['preco_venda'] as num).toDouble()
            : double.tryParse(data['preco_venda'].toString()))
        : null;

    final precoCusto = data['preco_custo'] != null
        ? (data['preco_custo'] is num
            ? (data['preco_custo'] as num).toDouble()
            : double.tryParse(data['preco_custo'].toString()))
        : null;

    if (precoVenda != null || precoCusto != null) {
      // Se um dos preços mudou, buscar o outro para calcular margem
      final produto = await obterPorId(id);
      final venda = precoVenda ?? produto.precoVenda;
      final custo = precoCusto ?? produto.precoCusto;

      if (custo > 0) {
        final margem = ((venda - custo) / custo) * 100;
        dbData['margem_lucro'] = margem.toStringAsFixed(2);
      }
    }

    // Handle is_combo field
    if (data.containsKey('is_combo')) {
      final isCombo = data['is_combo'] == true || data['is_combo'] == 1;
      dbData['is_combo'] = isCombo ? '1' : '0';
      if (isCombo) {
        dbData['estoque_atual'] = '0';
        dbData['estoque_minimo'] = '0';
      }
    }

    if (dbData.isNotEmpty) {
      await _repository.update(id, dbData);
    }

    // Update combo components if provided (only for combos)
    final isComboNow = data['is_combo'] == true || data['is_combo'] == 1;
    if (data['combo_itens'] is List) {
      if (!isComboNow) {
        throw ValidationException(
            'Não é possível definir componentes em um produto que não é combo');
      }
      final comboItens = (data['combo_itens'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      if (comboItens.isEmpty) {
        throw ValidationException(
            'Um combo deve ter pelo menos um componente');
      }
      await _validarComboItens(id, comboItens);
      await _repository.replaceComboItens(id, comboItens);
    }

    // If turning off combo, clean up orphan combo_itens
    if (data.containsKey('is_combo') && !isComboNow) {
      await _repository.replaceComboItens(id, []);
    }

    return obterPorId(id);
  }

  Future<void> _validarComboItens(
      int? comboId, List<Map<String, dynamic>> itens) async {
    for (final item in itens) {
      final produtoId = item['produto_id'];
      if (produtoId == null) {
        throw ValidationException('produto_id é obrigatório em cada componente');
      }
      final pid = produtoId is int ? produtoId : int.tryParse(produtoId.toString());
      if (pid == null) {
        throw ValidationException('produto_id inválido: $produtoId');
      }

      // Validate quantity
      final quantidade = item['quantidade'];
      final qtd = quantidade is num
          ? quantidade.toDouble()
          : double.tryParse(quantidade?.toString() ?? '') ?? 0;
      if (qtd <= 0) {
        throw ValidationException(
            'Quantidade do componente deve ser maior que zero');
      }

      // No self-reference
      if (comboId != null && pid == comboId) {
        throw ValidationException(
            'Um combo não pode conter a si mesmo como componente');
      }

      // Check product exists and is not a combo (no nesting)
      final produto = await _repository.findById(pid);
      if (produto == null) {
        throw NotFoundException('Produto componente $pid não encontrado');
      }
      if (produto.isCombo) {
        throw ValidationException(
            'O produto "${produto.descricao}" é um combo e não pode ser componente de outro combo');
      }
    }
  }

  Future<void> inativar(int id) async {
    await obterPorId(id);
    await _repository.update(id, {'ativo': '0'});
  }

  Future<void> bloquear(int id) async {
    final produto = await obterPorId(id);
    final novoBloqueado = produto.bloqueado ? '0' : '1';
    await _repository.update(id, {'bloqueado': novoBloqueado});
  }

  Future<Map<String, dynamic>> definirEstoqueMinimoEmLote(int valor) async {
    if (valor < 0) {
      throw ValidationException('O valor de estoque mínimo não pode ser negativo');
    }
    final affected = await _repository.updateEstoqueMinimoAll(valor);
    return {'affected': affected, 'estoque_minimo': valor};
  }

  Future<Map<String, dynamic>> alterarMargemBruta(double novaMargem) async {
    if (novaMargem < 0) {
      throw ValidationException('A margem não pode ser negativa');
    }

    final produtos = await _repository.findAllAtivos();
    int updated = 0;

    for (final produto in produtos) {
      if (produto.precoCusto > 0) {
        final novoPrecoVenda =
            produto.precoCusto * (1 + novaMargem / 100);
        await _repository.update(produto.id!, {
          'preco_venda': novoPrecoVenda.toStringAsFixed(2),
          'margem_lucro': novaMargem.toStringAsFixed(2),
        });
        updated++;
      }
    }

    return {'affected': updated, 'margem': novaMargem};
  }

  Future<Produto> uploadImagem(int id, String base64Image) async {
    // Verificar se produto existe
    final produto = await obterPorId(id);

    // Criar diretorio de uploads
    final dir = Directory('uploads/produtos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Remover imagem anterior se existir
    if (produto.imagemPath != null && produto.imagemPath!.isNotEmpty) {
      final oldFile = File(produto.imagemPath!);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }

    // Decodificar base64 e salvar
    final bytes = base64Decode(base64Image);
    final filename = '${id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = 'uploads/produtos/$filename';
    await File(filePath).writeAsBytes(bytes);

    // Atualizar produto no banco
    await _repository.update(id, {
      'imagem_path': filePath,
      'thumbnail_path': filePath,
    });

    return obterPorId(id);
  }

  Future<Map<String, dynamic>> importarLote(
      List<Map<String, dynamic>> produtos) async {
    int importados = 0;
    final erros = <Map<String, dynamic>>[];

    for (int i = 0; i < produtos.length; i++) {
      final linha = i + 2; // +2 porque linha 1 é cabeçalho e i começa em 0
      final data = produtos[i];

      try {
        // Pular linhas totalmente vazias
        final descricao = data['descricao']?.toString().trim() ?? '';
        if (descricao.isEmpty) {
          erros.add({'linha': linha, 'erro': 'Descrição vazia, linha ignorada'});
          continue;
        }

        // Limpar códigos vazios para evitar conflitos de unique
        if (data['codigo_barras'] != null &&
            data['codigo_barras'].toString().trim().isEmpty) {
          data.remove('codigo_barras');
        }
        if (data['codigo_interno'] != null &&
            data['codigo_interno'].toString().trim().isEmpty) {
          data.remove('codigo_interno');
        }

        await criar(data);
        importados++;
      } catch (e) {
        erros.add({'linha': linha, 'erro': e.toString()});
      }
    }

    return {'importados': importados, 'erros': erros};
  }

  Future<List<Map<String, dynamic>>> rankingGeral({int limit = 20}) async {
    final results = await _repository.rankingGeral(limit: limit);
    return results.map((row) => {
      'produto_id': int.tryParse(row['id'] ?? '0') ?? 0,
      'descricao': row['descricao'] ?? '',
      'preco_venda': double.tryParse(row['preco_venda'] ?? '0') ?? 0,
      'total_quantidade': int.tryParse(row['total_quantidade'] ?? '0') ?? 0,
      'total_faturamento': double.tryParse(row['total_faturamento'] ?? '0') ?? 0,
    }).toList();
  }

  Future<List<Map<String, dynamic>>> rankingPorData({
    required String dataInicio,
    required String dataFim,
    int limit = 20,
  }) async {
    final results = await _repository.rankingPorData(
      dataInicio: dataInicio,
      dataFim: dataFim,
      limit: limit,
    );
    return results.map((row) => {
      'produto_id': int.tryParse(row['id'] ?? '0') ?? 0,
      'descricao': row['descricao'] ?? '',
      'preco_venda': double.tryParse(row['preco_venda'] ?? '0') ?? 0,
      'total_quantidade': int.tryParse(row['total_quantidade'] ?? '0') ?? 0,
      'total_faturamento': double.tryParse(row['total_faturamento'] ?? '0') ?? 0,
    }).toList();
  }
}
