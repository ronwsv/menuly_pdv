import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../core/helpers/query_helpers.dart';
import 'emitente_repository.dart';

class EmitenteController {
  final EmitenteRepository _repository;

  EmitenteController(this._repository);

  Future<Response> obter(Request request) async {
    try {
      final emitente = await _repository.findFirst();

      if (emitente == null) {
        return Response.ok(
          jsonEncode({'data': null}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'data': emitente}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno do servidor'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> atualizar(Request request) async {
    try {
      final body = await parseBody(request);

      final allowed = <String>{
        'razao_social', 'nome_fantasia', 'cnpj',
        'inscricao_estadual', 'inscricao_municipal',
        'endereco', 'numero', 'complemento', 'bairro',
        'cidade', 'estado', 'cep', 'telefone', 'email',
        'logo_path', 'regime_tributario',
      };

      final data = <String, String>{};
      for (final key in allowed) {
        if (body.containsKey(key)) {
          data[key] = body[key]?.toString() ?? '';
        }
      }

      if (data.isEmpty) {
        return Response(400,
          body: jsonEncode({'error': 'Nenhum campo para atualizar'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _repository.upsert(data);
      final updated = await _repository.findFirst();

      return Response.ok(
        jsonEncode({'data': updated}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro ao atualizar emitente'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
