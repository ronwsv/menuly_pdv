import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'devolucoes_service.dart';
import '../../core/helpers/json_response.dart';
import '../../core/helpers/query_helpers.dart';

class DevolucoesController {
  final DevolucoesService _service;

  DevolucoesController(this._service);

  // ── Devoluções ──

  Future<Response> listar(Request request) async {
    final queryParams = request.url.queryParameters;

    final page = getPage(queryParams);
    final perPage = getPerPage(queryParams);
    final offset = getOffset(page, perPage);

    final params = <String, dynamic>{
      'tipo': queryParams['tipo'],
      'status': queryParams['status'],
      'data_inicio': queryParams['data_inicio'],
      'data_fim': queryParams['data_fim'],
      'limit': perPage,
      'offset': offset,
    };

    if (queryParams['cliente_id'] != null) {
      params['cliente_id'] = int.tryParse(queryParams['cliente_id']!);
    }
    if (queryParams['venda_id'] != null) {
      params['venda_id'] = int.tryParse(queryParams['venda_id']!);
    }

    final result = await _service.listar(params);

    return JsonResponse.paginated(
      result['items'] as List,
      result['total'] as int,
      page,
      perPage,
    );
  }

  Future<Response> obterPorId(Request request) async {
    final id = int.parse(request.params['id']!);
    final devolucao = await _service.obterPorId(id);
    return JsonResponse.ok(devolucao);
  }

  Future<Response> buscarVenda(Request request) async {
    final numero = request.params['numero']!;
    final venda = await _service.buscarVenda(numero);
    return JsonResponse.ok(venda);
  }

  Future<Response> buscarVendasPorValor(Request request) async {
    final valorStr = request.url.queryParameters['valor'];
    if (valorStr == null || valorStr.isEmpty) {
      return JsonResponse.error(400, 'Parametro valor e obrigatorio');
    }
    final valor = double.tryParse(valorStr);
    if (valor == null) {
      return JsonResponse.error(400, 'Valor invalido');
    }
    final vendas = await _service.buscarVendasPorValor(valor);
    return JsonResponse.ok(vendas);
  }

  Future<Response> criar(Request request) async {
    final body = await parseBody(request);
    final usuarioId = request.context['userId'] as int;
    final devolucao = await _service.criar(body, usuarioId);
    return JsonResponse.created(devolucao,
        message: 'Devolucao registrada com sucesso');
  }

  // ── Customer Credits ──

  Future<Response> listarCreditos(Request request) async {
    final queryParams = request.url.queryParameters;

    final page = getPage(queryParams);
    final perPage = getPerPage(queryParams);
    final offset = getOffset(page, perPage);

    final params = <String, dynamic>{
      'status': queryParams['status'],
      'limit': perPage,
      'offset': offset,
    };

    if (queryParams['cliente_id'] != null) {
      params['cliente_id'] = int.tryParse(queryParams['cliente_id']!);
    }

    final result = await _service.listarCreditos(params);

    return JsonResponse.paginated(
      result['items'] as List,
      result['total'] as int,
      page,
      perPage,
    );
  }

  Future<Response> saldoCliente(Request request) async {
    final clienteId = int.parse(request.params['clienteId']!);
    final saldo = await _service.obterSaldoCliente(clienteId);
    return JsonResponse.ok(saldo);
  }

  Future<Response> utilizarCredito(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final result = await _service.utilizarCredito(id, body);
    return JsonResponse.ok(result, message: 'Credito utilizado com sucesso');
  }

  Future<Response> totaisCreditos(Request request) async {
    final queryParams = request.url.queryParameters;
    int? clienteId;
    if (queryParams['cliente_id'] != null) {
      clienteId = int.tryParse(queryParams['cliente_id']!);
    }
    final totais = await _service.totaisCreditos(clienteId: clienteId);
    return JsonResponse.ok(totais);
  }
}
