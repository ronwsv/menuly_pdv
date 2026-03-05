import 'package:flutter/material.dart';
import '../app/theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? submessage;

  EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.message,
    this.submessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppTheme.textMuted),
          SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          if (submessage != null) ...[
            SizedBox(height: 8),
            Text(submessage!,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textMuted)),
          ],
        ],
      ),
    );
  }
}
