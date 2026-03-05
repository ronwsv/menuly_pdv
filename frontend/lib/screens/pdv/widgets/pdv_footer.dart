import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';

class PdvFooter extends StatefulWidget {
  PdvFooter({super.key});
  @override
  State<PdvFooter> createState() => _PdvFooterState();
}

class _PdvFooterState extends State<PdvFooter> {
  late Timer _timer;
  String _time = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    setState(() => _time = DateFormat('HH:mm:ss').format(DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        border: Border(top: BorderSide(color: AppTheme.primary, width: 2)),
      ),
      child: Row(
        children: [
          // Operator
          Row(children: [
            Icon(Icons.person, size: 16, color: AppTheme.greenSuccess),
            SizedBox(width: 6),
            Text('Operador: ${auth.nomeUsuario}',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ]),
          Spacer(),
          // Clock
          Text(_time,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Consolas')),
          Spacer(),
          // Logo
          RichText(
              text: TextSpan(children: [
            TextSpan(
                text: 'Menuly',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            TextSpan(
                text: 'PDV',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent)),
          ])),
        ],
      ),
    );
  }
}
