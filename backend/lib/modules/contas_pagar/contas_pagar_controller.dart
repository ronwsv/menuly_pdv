import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'contas_pagar_service.dart';
import '../../core/helpers/json_response.dart';
import '../../core/helpers/query_helpers.dart';

class ContasPagarController {
  final ContasPagarService _service;

  ContasPagarController(this._service);

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

    if (queryParams['fornecedor_id'] != null) {
      params['fornecedor_id'] = int.tryParse(queryParams['fornecedor_id']!);
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
    final conta = await _service.obterPorId(id);
    return JsonResponse.ok(conta);
  }

  Future<Response> criar(Request request) async {
    final body = await parseBody(request);
    final conta = await _service.criar(body);
    return JsonResponse.created(conta);
  }

  Future<Response> atualizar(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final conta = await _service.atualizar(id, body);
    return JsonResponse.ok(conta);
  }

  Future<Response> darBaixa(Request request) async {
    final id = int.parse(request.params['id']!);
    final body = await parseBody(request);
    final conta = await _service.darBaixa(id, body);
    return JsonResponse.ok(conta, message: 'Pagamento realizado com sucesso');
  }

  Future<Response> cancelar(Request request) async {
    final id = int.parse(request.params['id']!);
    await _service.cancelar(id);
    return JsonResponse.ok({'message': 'Conta cancelada com sucesso'});
  }

  Future<Response> excluir(Request request) async {
    final id = int.parse(request.params['id']!);
    await _service.excluir(id);
    return JsonResponse.ok({'message': 'Conta excluida com sucesso'});
  }

  Future<Response> totais(Request request) async {
    final queryParams = request.url.queryParameters;
    int? fornecedorId;
    if (queryParams['fornecedor_id'] != null) {
      fornecedorId = int.tryParse(queryParams['fornecedor_id']!);
    }
    final totais = await _service.totais(fornecedorId: fornecedorId);
    return JsonResponse.ok(totais);
  }
}
