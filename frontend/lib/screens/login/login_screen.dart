import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();
  final _loginFocus = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loginFocus.requestFocus();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    _loginFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final login = _loginController.text.trim();
    final senha = _senhaController.text.trim();
    if (login.isEmpty || senha.isEmpty) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.login(login, senha);
    if (mounted) setState(() => _isLoading = false);
    if (!success && mounted) {
      // error is displayed via Consumer
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.point_of_sale, color: Colors.white, size: 28),
                    ),
                    SizedBox(width: 12),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: 'MENULY ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                          TextSpan(text: 'PDV', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.accent)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('Sistema de Ponto de Venda', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                SizedBox(height: 48),

                // Login Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      SizedBox(height: 24),

                      // Login field
                      TextField(
                        controller: _loginController,
                        focusNode: _loginFocus,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Usuário',
                          prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.primary, width: 2)),
                        ),
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      SizedBox(height: 16),

                      // Senha field
                      TextField(
                        controller: _senhaController,
                        obscureText: true,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.primary, width: 2)),
                        ),
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      SizedBox(height: 8),

                      // Error message
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          if (auth.error == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(auth.error!, style: TextStyle(color: AppTheme.error, fontSize: 13)),
                          );
                        },
                      ),
                      SizedBox(height: 24),

                      // Login button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                          ),
                          child: _isLoading
                              ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),
                Text('v1.0.0', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
