import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Internal state ────────────────────────────────────────────────
  static bool _isDark = true;
  static Color _primaryColor = const Color(0xFF1565c0);

  static bool get isDark => _isDark;

  static void setMode(bool isDark) => _isDark = isDark;
  static void setPrimaryColor(Color color) => _primaryColor = color;

  // ── Dynamic colors (depend on theme mode) ─────────────────────────
  static Color get scaffoldBackground =>
      _isDark ? const Color(0xFF0d1117) : const Color(0xFFF5F6FA);
  static Color get cardSurface =>
      _isDark ? const Color(0xFF161b22) : Colors.white;
  static Color get textPrimary =>
      _isDark ? const Color(0xFFe6edf3) : const Color(0xFF1a1a2e);
  static Color get textSecondary =>
      _isDark ? const Color(0xFF8b949e) : const Color(0xFF64748b);
  static Color get textMuted =>
      _isDark ? const Color(0xFF6e7681) : const Color(0xFF94a3b8);
  static Color get border =>
      _isDark ? const Color(0xFF30363d) : const Color(0xFFe2e8f0);
  static Color get inputFill =>
      _isDark ? const Color(0xFF222d3d) : const Color(0xFFF1F5F9);

  static Color get primary => _primaryColor;
  static Color get primaryDark {
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl.withLightness((hsl.lightness * 0.55).clamp(0.0, 1.0)).toColor();
  }

  static Color get accent {
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl
        .withLightness((hsl.lightness * 1.15).clamp(0.0, 0.85))
        .toColor();
  }

  // ── Fixed colors (same in both themes) ────────────────────────────
  static const Color greenSuccess = Color(0xFF22c55e);
  static const Color error = Color(0xFFef4444);
  static const Color yellowWarning = Color(0xFFf59e0b);

  // ── Border‑radius constants ───────────────────────────────────────
  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 10;

  // ── Theme ─────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const fontFamily = 'Segoe UI';

    final colorScheme =
        (_isDark ? const ColorScheme.dark() : const ColorScheme.light())
            .copyWith(
      primary: primary,
      primaryContainer: primaryDark,
      secondary: accent,
      secondaryContainer: primaryDark,
      surface: cardSurface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: _isDark ? Brightness.dark : Brightness.light,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: cardSurface,

      // ── Card ──
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── ElevatedButton ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── OutlinedButton ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TextButton ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── InputDecoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: TextStyle(
          color: textSecondary,
          fontFamily: fontFamily,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: textSecondary,
          fontFamily: fontFamily,
          fontSize: 14,
        ),
        errorStyle: const TextStyle(
          color: error,
          fontFamily: fontFamily,
          fontSize: 12,
        ),
      ),

      // ── Text ──
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          fontFamily: fontFamily,
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamily: fontFamily,
          color: textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: cardSurface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: border),
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: textSecondary,
          fontSize: 14,
        ),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cardSurface,
          borderRadius: BorderRadius.circular(radiusSm),
          border: Border.all(color: border),
        ),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 12,
        ),
      ),

      // ── Snackbar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardSurface,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: border),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── PopupMenu ──
      popupMenuTheme: PopupMenuThemeData(
        color: cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: border),
        ),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 14,
        ),
      ),

      // ── Checkbox ──
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return border;
        }),
      ),

      // ── ProgressIndicator ──
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border,
      ),

      // ── Scrollbar ──
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(border),
        radius: const Radius.circular(radiusSm),
        thickness: WidgetStateProperty.all(6.0),
      ),

      // ── DataTable ──
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(scaffoldBackground),
        dataRowColor: WidgetStateProperty.all(cardSurface),
        dividerThickness: 1,
        headingTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: 14,
        ),
      ),

      // ── IconButton ──
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondary,
        ),
      ),

      // ── FloatingActionButton ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    );
  }
}
