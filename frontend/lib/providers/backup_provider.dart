import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';

class BackupProvider extends ChangeNotifier {
  final ApiClient _api;

  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  BackupProvider(this._api);

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  /// Gera backup e abre dialog para o usuário escolher onde salvar.
  Future<void> fazerBackup() async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      // 1. Gerar backup no backend
      final bytes = await _api.getBytes(ApiConfig.backupGerar);

      // 2. Abrir dialog para escolher onde salvar
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'menuly_pdv_backup_$timestamp.sql';

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar Backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['sql'],
      );

      if (path == null) {
        // Usuário cancelou
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 3. Salvar arquivo
      final filePath = path.endsWith('.sql') ? path : '$path.sql';
      await File(filePath).writeAsBytes(bytes);

      _successMessage = 'Backup salvo em: $filePath';
    } catch (e) {
      _error = 'Erro ao gerar backup: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Abre dialog para selecionar arquivo .sql e restaura no banco.
  Future<void> restaurarBackup() async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      // 1. Abrir dialog para selecionar arquivo
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Selecionar Backup',
        type: FileType.custom,
        allowedExtensions: ['sql'],
      );

      if (result == null || result.files.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        _error = 'Caminho do arquivo invalido';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. Ler conteúdo do arquivo
      final sql = await File(filePath).readAsString();

      if (sql.trim().isEmpty) {
        _error = 'Arquivo de backup vazio';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 3. Enviar ao backend para restaurar
      await _api.postRaw(ApiConfig.backupRestaurar, sql);

      _successMessage = 'Backup restaurado com sucesso!';
    } catch (e) {
      _error = 'Erro ao restaurar backup: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void limparMensagens() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
