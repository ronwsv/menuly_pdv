import 'package:flutter/material.dart';
import '../app/theme.dart';

enum AppButtonVariant { primary, success, danger, outline }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double? height;
  final String? shortcutLabel; // e.g. "F1"

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.height,
    this.shortcutLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    Widget child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (shortcutLabel != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.$1.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colors.$1.withOpacity(0.4)),
            ),
            child: Text(
              shortcutLabel!,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.$1),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        if (isLoading)
          const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
        else
          Text(label),
      ],
    );

    final style = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        variant == AppButtonVariant.outline ? Colors.transparent : colors.$1,
      ),
      foregroundColor: WidgetStatePropertyAll(colors.$2),
      side: variant == AppButtonVariant.outline
          ? WidgetStatePropertyAll(BorderSide(color: colors.$1))
          : null,
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
      minimumSize: WidgetStatePropertyAll(
          Size(fullWidth ? double.infinity : 0, height ?? 42)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      ),
    );

    if (variant == AppButtonVariant.outline) {
      return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child);
    }
    return ElevatedButton(
        onPressed: isLoading ? null : onPressed, style: style, child: child);
  }

  (Color, Color) _getColors() => switch (variant) {
        AppButtonVariant.primary => (AppTheme.primary, Colors.white),
        AppButtonVariant.success => (AppTheme.greenSuccess, Colors.white),
        AppButtonVariant.danger => (AppTheme.error, Colors.white),
        AppButtonVariant.outline => (AppTheme.border, AppTheme.textPrimary),
      };
}
