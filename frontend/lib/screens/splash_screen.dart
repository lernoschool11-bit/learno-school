import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'login_screen.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // ── Safety timeout: navigate after 4s even if Lottie fails to load ──
    Future.delayed(const Duration(seconds: 4), () {
      _navigateToNext();
    });
  }

  Future<void> _navigateToNext() async {
    // Guard: only navigate once
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final bool hasToken = token != null && token.isNotEmpty;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              hasToken ? const MainNavigation() : const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: Lottie.network(
          'https://lottie.host/25f804e5-3261-44c7-8708-bfcb6c159480/L7QjCOILSv.json',
          width: 300,
          height: 300,
          fit: BoxFit.contain,
          controller: _controller,
          errorBuilder: (context, error, stackTrace) {
            // If Lottie fails to load, navigate immediately
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToNext();
            });
            return const SizedBox.shrink();
          },
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward().then((_) {
                _navigateToNext();
              });
          },
        ),
      ),
    );
  }
}
