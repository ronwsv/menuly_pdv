import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'backup_service.dart';

class BackupController {
  final BackupService _service;

  BackupController(this._service);

  Future<Response> gerar(Request request) async {
    try {
      final sql = await _service.gerarBackup();
      final bytes = utf8.encode(sql);
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'menuly_pdv_backup_$timestamp.sql';

      return Response.ok(
        bytes,
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Disposition': 'attachment; filename="$fileName"',
          'Content-Length': bytes.length.toString(),
        },
      );
    } catch (e) {
      return Response(500,
          body: jsonEncode({
            'success': false,
            'error': 'Erro ao gerar backup: $e',
          }),
          headers: {'Content-Type': 'application/json; charset=utf-8'});
    }
  }

  Future<Response> restaurar(Request request) async {
    try {
      final sql = await request.readAsString();
      if (sql.trim().isEmpty) {
        return Response(400,
            body: jsonEncode({
              'success': false,
              'error': 'Conteudo do backup vazio',
            }),
            headers: {'Content-Type': 'application/json; charset=utf-8'});
      }

      await _service.restaurarBackup(sql);

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Backup restaurado com sucesso',
        }),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );
    } catch (e) {
      return Response(500,
          body: jsonEncode({
            'success': false,
            'error': 'Erro ao restaurar backup: $e',
          }),
          headers: {'Content-Type': 'application/json; charset=utf-8'});
    }
  }
}
