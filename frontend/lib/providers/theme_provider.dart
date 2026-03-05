import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'configuracoes_provider.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  Color _primaryColor = const Color(0xFF1565c0);
  String? _logoPath;
  bool _showWatermark = true;
  double _watermarkOpacity = 0.05;

  bool get isDark => _isDark;
  Color get primaryColor => _primaryColor;
  String? get logoPath => _logoPath;
  bool get showWatermark => _showWatermark;
  double get watermarkOpacity => _watermarkOpacity;

  ThemeData get theme {
    AppTheme.setMode(_isDark);
    AppTheme.setPrimaryColor(_primaryColor);
    return AppTheme.darkTheme;
  }

  /// Loads visual settings from ConfiguracoesProvider.
  void carregarConfigs(ConfiguracoesProvider configProvider) {
    final modo = configProvider.getConfig('tema_modo', 'dark');
    final corHex = configProvider.getConfig('tema_cor_primaria', '#1565c0');
    final logo = configProvider.getConfig('logo_path', '');
    final watermark = configProvider.getConfig('pdv_mostrar_watermark', '1');
    final opacidade =
        configProvider.getConfig('pdv_watermark_opacidade', '0.05');

    _isDark = modo != 'light';
    _primaryColor = _hexToColor(corHex);
    _logoPath = logo.isNotEmpty ? logo : null;
    _showWatermark = watermark == '1';
    _watermarkOpacity =
        double.tryParse(opacidade)?.clamp(0.01, 0.15) ?? 0.05;

    AppTheme.setMode(_isDark);
    AppTheme.setPrimaryColor(_primaryColor);
    notifyListeners();
  }

  Future<void> toggleTheme(ConfiguracoesProvider cp) async {
    _isDark = !_isDark;
    AppTheme.setMode(_isDark);
    notifyListeners();
    await cp.salvarConfig('tema_modo', _isDark ? 'dark' : 'light');
  }

  Future<void> setPrimaryColor(Color color, ConfiguracoesProvider cp) async {
    _primaryColor = color;
    AppTheme.setPrimaryColor(color);
    notifyListeners();
    await cp.salvarConfig(
      'tema_cor_primaria',
      '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    );
  }

  Future<void> setLogoPath(String? path, ConfiguracoesProvider cp) async {
    _logoPath = path;
    notifyListeners();
    await cp.salvarConfig('logo_path', path ?? '');
  }

  Future<void> setShowWatermark(bool show, ConfiguracoesProvider cp) async {
    _showWatermark = show;
    notifyListeners();
    await cp.salvarConfig('pdv_mostrar_watermark', show ? '1' : '0');
  }

  Future<void> setWatermarkOpacity(
      double opacity, ConfiguracoesProvider cp) async {
    _watermarkOpacity = opacity.clamp(0.01, 0.15);
    notifyListeners();
    await cp.salvarConfig(
        'pdv_watermark_opacidade', _watermarkOpacity.toStringAsFixed(2));
  }

  static Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
