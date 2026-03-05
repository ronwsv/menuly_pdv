import 'package:flutter/material.dart';
import '../app/theme.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;

  LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: AppTheme.primary),
          ),
          if (message != null) ...[
            SizedBox(height: 16),
            Text(message!,
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }
}
