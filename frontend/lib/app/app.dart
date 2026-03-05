import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/login/login_screen.dart';
import '../screens/shell/app_shell.dart';

class MenulyApp extends StatelessWidget {
  const MenulyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Menuly PDV',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.theme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (auth.isAuthenticated) {
            return const AppShell();
          }
          return LoginScreen();
        },
      ),
    );
  }
}
