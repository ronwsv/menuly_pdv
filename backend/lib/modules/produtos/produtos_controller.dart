import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/exceptions/api_exception.dart';
import 'produtos_service.dart';

class ProdutosController {
  final ProdutosService _service;

  ProdutosController(this._service);

  Future<Response> listar(Request request) async {
    try {
      final queryParams = request.url.queryParameters;

      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final perPage = int.tryParse(queryParams['per_page'] ?? '50') ?? 50;
      final offset = (page - 1) * perPage;

      final params = <String, dynamic>{
        'busca': queryParams['busca'],
        'limit': perPage,
        'offset': offset,
      };

      if (queryParams['categoria_id'] != null) {
        params['categoria_id'] = int.tryParse(queryParams['categoria_id']!);
      }

      if (queryParams['ativo'] != null) {
        params['ativo'] = queryParams['ativo'] == '1' ||
            queryParams['ativo'] == 'true';
      }

      if (queryParams['tamanho'] != null) {
        params['tamanho'] = queryParams['tamanho'];
      }

      final result = await _service.listar(params);

      return Response.ok(
        jsonEncode({
          'data': result['items'],
          'total': result['total'],
          'page': page,
          'per_page': perPage,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('[PRODUTOS] Erro ao listar: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> obterPorId(Request request, String id) async {
    try {
      final produtoId = int.tryParse(id);
      if (produtoId == null) {
        return Response(
          400,
          body: jsonEncode({'error': 'ID inválido'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final data = await _service.obterPorIdComDetalhes(produtoId);

      return Response.ok(
        jsonEncode({'data': data}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> buscarPorCodigoBarras(
      Request request, String codigo) async {
    try {
      final produto = await _service.buscarPorCodigoBarras(codigo);

      return Response.ok(
        jsonEncode({'data': produto.toJson()}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> buscarPorCodigoInterno(
      Request request, String codigo) async {
    try {
      final produto = await _service.buscarPorCodigoInterno(codigo);

      return Response.ok(
        jsonEncode({'data': produto.toJson()}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> criar(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final produto = await _service.criar(data);

      return Response(
        201,
        body: jsonEncode({'data': produto.toJson()}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> atualizar(Request request, String id) async {
    try {
      final produtoId = int.tryParse(id);
      if (produtoId == null) {
        return Response(
          400,
          body: jsonEncode({'error': 'ID inválido'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final produto = await _service.atualizar(produtoId, data);

      return Response.ok(
        jsonEncode({'data': produto.toJson()}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> inativar(Request request, String id) async {
    try {
      final produtoId = int.tryParse(id);
      if (produtoId == null) {
        return Response(
          400,
          body: jsonEncode({'error': 'ID inválido'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _service.inativar(produtoId);

      return Response.ok(
        jsonEncode({'message': 'Produto inativado com sucesso'}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> bloquear(Request request, String id) async {
    try {
      final produtoId = int.tryParse(id);
      if (produtoId == null) {
        return Response(
          400,
          body: jsonEncode({'error': 'ID inválido'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _service.bloquear(produtoId);

      return Response.ok(
        jsonEncode({'message': 'Status de bloqueio atualizado com sucesso'}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> batchEstoqueMinimo(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final valor = data['estoque_minimo'];
      if (valor == null) {
        return Response(
          400,
          body: jsonEncode({'error': 'estoque_minimo é obrigatório'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final valorInt = valor is int ? valor : int.tryParse(valor.toString()) ?? 0;
      final result = await _service.definirEstoqueMinimoEmLote(valorInt);

      return Response.ok(
        jsonEncode({'message': 'Estoque mínimo atualizado', ...result}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> batchMargem(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final margem = data['margem'];
      if (margem == null) {
        return Response(
          400,
          body: jsonEncode({'error': 'margem é obrigatório'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final margemDouble = margem is num
          ? margem.toDouble()
          : double.tryParse(margem.toString()) ?? 0;
      final result = await _service.alterarMargemBruta(margemDouble);

      return Response.ok(
        jsonEncode({'message': 'Margem atualizada', ...result}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> uploadImagem(Request request) async {
    try {
      final id = request.params['id'];
      final produtoId = int.tryParse(id ?? '');
      if (produtoId == null) {
        return Response(
          400,
          body: jsonEncode({'error': 'ID inválido'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final base64Image = data['imagem_base64'] as String?;
      if (base64Image == null || base64Image.isEmpty) {
        return Response(
          400,
          body: jsonEncode({'error': 'imagem_base64 é obrigatório'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final produto = await _service.uploadImagem(produtoId, base64Image);

      return Response.ok(
        jsonEncode({'data': produto.toJson()}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> importarCSV(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      if (data is! List) {
        return Response(
          400,
          body: jsonEncode({'error': 'Esperado um array de produtos'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final produtos =
          data.map((e) => e as Map<String, dynamic>).toList();

      if (produtos.isEmpty) {
        return Response(
          400,
          body: jsonEncode({'error': 'Nenhum produto para importar'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final result = await _service.importarLote(produtos);

      return Response.ok(
        jsonEncode({'data': result}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> comboItens(Request request, String id) async {
    try {
      final produtoId = int.tryParse(id);
      if (produtoId == null) {
        return Response(
          400,
          body: jsonEncode({'error': 'ID inválido'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final data = await _service.obterPorIdComDetalhes(produtoId);
      final comboItens = data['combo_itens'] ?? [];

      return Response.ok(
        jsonEncode({'data': comboItens}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ApiException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> rankingGeral(Request request) async {
    try {
      final limit = int.tryParse(
              request.url.queryParameters['limit'] ?? '20') ??
          20;
      final data = await _service.rankingGeral(limit: limit);

      return Response.ok(
        jsonEncode({'data': data}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> rankingPorData(Request request) async {
    try {
      final queryParams = request.url.queryParameters;
      final dataInicio = queryParams['data_inicio'];
      final dataFim = queryParams['data_fim'];

      if (dataInicio == null || dataFim == null) {
        return Response(
          400,
          body: jsonEncode(
              {'error': 'data_inicio e data_fim são obrigatórios'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      final data = await _service.rankingPorData(
        dataInicio: dataInicio,
        dataFim: dataFim,
        limit: limit,
      );

      return Response.ok(
        jsonEncode({'data': data}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
