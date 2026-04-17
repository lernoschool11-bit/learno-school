import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'admin_panel.dart';
import '../main.dart';
import '../widgets/login_character_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/luxury_button.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'force_password_change_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال بريد إلكتروني صحيح')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال كلمة المرور')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // DEMO BYPASS: Admin hardcoded
    if (email == 'admin@learno.com' && password == 'admin123') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userRole', 'ADMIN');
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminPanel()),
        );
      }
      return;
    }

    final data = await _apiService.login(email, password);
    setState(() => _isLoading = false);

    if (data.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      final user = data['user'];
      final role = user['role'] as String? ?? 'STUDENT';
      final bool needsPasswordChange = user['needsPasswordChange'] ?? false;

      await prefs.setString('userRole', role);
      await prefs.setString('userSchool', user['school'] ?? '');

      if (mounted) {
        if (needsPasswordChange) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ForcePasswordChangeScreen(userData: user),
            ),
          );
        } else if (role == 'PRINCIPAL' || role == 'ADMIN') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
      }
    } else {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('البريد الإلكتروني أو كلمة المرور غير صحيحة'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: LoginCharacterWidget(
                  isPasswordVisible: !_obscurePassword,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Learno',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'المنصة التعليمية',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              GlassCard(
                padding: const EdgeInsets.all(16),
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ),
              const SizedBox(height: 16),

              LuxuryButton(
                label: 'تسجيل الدخول',
                isLoading: _isLoading,
                onPressed: _login,
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text('ليس لديك حساب؟ سجل الآن'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}