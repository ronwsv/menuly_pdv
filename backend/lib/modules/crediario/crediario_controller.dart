import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'crediario_service.dart';
import '../../core/helpers/json_response.dart';
import '../../core/helpers/query_helpers.dart';

class CrediarioController {
  final CrediarioService _service;

  CrediarioController(this._service);

  Future<Response> listar(Request request) async {
    final queryParams = request.url.queryParameters;

    final page = getPage(queryParams);
    final perPage = getPerPage(queryParams);
    final offset = getOffset(page, perPage);

    final params = <String, dynamic>{
      'busca': queryParams['busca'],
      'status': queryParams['status'],
      'filtro_vencimento': queryParams['filtro_vencimento'],
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
    final parcela = await _service.obterPorId(id);
    return JsonResponse.ok(parcela);
  }

  Future<Response> pagar(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final parcela = await _service.pagar(id, body);
    return JsonResponse.ok(parcela, message: 'Parcela paga com sucesso');
  }

  Future<Response> totais(Request request) async {
    final queryParams = request.url.queryParameters;
    int? clienteId;
    if (queryParams['cliente_id'] != null) {
      clienteId = int.tryParse(queryParams['cliente_id']!);
    }
    final totais = await _service.totais(clienteId: clienteId);
    return JsonResponse.ok(totais);
  }

  Future<Response> verificarLimite(Request request) async {
    final clienteId = int.parse(request.params['clienteId']!);
    final info = await _service.verificarLimiteCliente(clienteId);
    return JsonResponse.ok(info);
  }
}
