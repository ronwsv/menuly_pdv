import 'dart:io';

import '../../config/database.dart';
import '../../config/server_config.dart';

class BackupService {
  /// Gera um dump SQL completo do banco de dados.
  /// Tenta usar mysqldump primeiro; se não disponível, faz dump puro via SQL.
  Future<String> gerarBackup() async {
    try {
      return await _gerarViaMysqldump();
    } catch (_) {
      return await _gerarViaSql();
    }
  }

  /// Restaura o banco a partir de um dump SQL.
  Future<void> restaurarBackup(String sql) async {
    if (sql.trim().isEmpty) {
      throw Exception('Arquivo de backup vazio');
    }

    final db = Database.instance;

    await db.execute('SET FOREIGN_KEY_CHECKS = 0', {});

    // Separar statements por ';' respeitando delimitadores
    final statements = _splitStatements(sql);
    var executados = 0;

    try {
      for (final stmt in statements) {
        final trimmed = stmt.trim();
        if (trimmed.isEmpty) continue;
        // Ignorar comentários e comandos de configuração do mysqldump
        if (trimmed.startsWith('--')) continue;
        if (trimmed.startsWith('/*')) continue;

        try {
          await db.execute(trimmed, {});
          executados++;
        } catch (e) {
          // Ignorar erros de DROP/CREATE em tabelas que não existem
          // mas logar para debug
          print('Aviso ao restaurar (statement $executados): $e');
        }
      }
    } finally {
      await db.execute('SET FOREIGN_KEY_CHECKS = 1', {});
    }
  }

  Future<String> _gerarViaMysqldump() async {
    final result = await Process.run('mysqldump', [
      '-h', ServerConfig.dbHost,
      '-P', ServerConfig.dbPort.toString(),
      '-u', ServerConfig.dbUser,
      '--password=${ServerConfig.dbPassword}',
      '--routines',
      '--triggers',
      '--single-transaction',
      '--set-charset',
      ServerConfig.dbName,
    ]);

    if (result.exitCode != 0) {
      final err = result.stderr.toString();
      // mysqldump prints a warning about password on CLI — that's OK
      if (!err.contains('Using a password on the command line')) {
        throw Exception('mysqldump falhou: $err');
      }
      // If the only message is the password warning, check if stdout has content
      if ((result.stdout as String).trim().isEmpty) {
        throw Exception('mysqldump retornou vazio');
      }
    }

    final timestamp = DateTime.now().toIso8601String();
    return '-- Menuly PDV Backup - $timestamp\n'
        '-- Gerado via mysqldump\n\n'
        '${result.stdout}';
  }

  Future<String> _gerarViaSql() async {
    final db = Database.instance;
    final buffer = StringBuffer();
    final timestamp = DateTime.now().toIso8601String();

    buffer.writeln('-- Menuly PDV Backup - $timestamp');
    buffer.writeln('-- Gerado via dump SQL puro');
    buffer.writeln();
    buffer.writeln('SET FOREIGN_KEY_CHECKS = 0;');
    buffer.writeln('SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";');
    buffer.writeln('SET NAMES utf8mb4;');
    buffer.writeln();

    // Listar todas as tabelas
    final tables = await db.query('SHOW TABLES', {});
    final tableKey = 'Tables_in_${ServerConfig.dbName}';

    for (final row in tables) {
      final tableName = row[tableKey] ?? row.values.first;
      if (tableName == null) continue;

      // DROP + CREATE TABLE
      buffer.writeln('-- Tabela: $tableName');
      buffer.writeln('DROP TABLE IF EXISTS `$tableName`;');

      final createResult = await db.query(
        'SHOW CREATE TABLE `$tableName`',
        {},
      );
      if (createResult.isNotEmpty) {
        final createSql = createResult.first['Create Table'] ??
            createResult.first.values.last;
        if (createSql != null) {
          buffer.writeln('$createSql;');
        }
      }
      buffer.writeln();

      // INSERT dos dados
      final rows = await db.query('SELECT * FROM `$tableName`', {});
      if (rows.isNotEmpty) {
        final columns = rows.first.keys.toList();
        final colNames = columns.map((c) => '`$c`').join(', ');

        for (final dataRow in rows) {
          final values = columns.map((col) {
            final val = dataRow[col];
            if (val == null) return 'NULL';
            // Escapar aspas simples
            final escaped = val.replaceAll("'", "\\'").replaceAll('\n', '\\n');
            return "'$escaped'";
          }).join(', ');

          buffer.writeln('INSERT INTO `$tableName` ($colNames) VALUES ($values);');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('SET FOREIGN_KEY_CHECKS = 1;');
    return buffer.toString();
  }

  List<String> _splitStatements(String sql) {
    final statements = <String>[];
    final lines = sql.split('\n');
    final current = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('--') || trimmed.startsWith('/*') || trimmed.isEmpty) {
        continue;
      }
      current.write('$line\n');
      if (trimmed.endsWith(';')) {
        statements.add(current.toString());
        current.clear();
      }
    }
    // Restante sem ;
    if (current.isNotEmpty) {
      statements.add(current.toString());
    }
    return statements;
  }
}
