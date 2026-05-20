import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../main.dart';
import '../theme/app_theme.dart';

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

    // Safety Fallback Timeout: If Lottie fails to load or takes > 4 seconds,
    // transition to the next screen anyway to avoid a stuck/white screen.
    Future.delayed(const Duration(seconds: 4), () {
      if (!_hasNavigated) {
        debugPrint('⚠️ Lottie load timeout. Fallback navigation triggered.');
        _navigateToNext();
      }
    });
  }

  Future<void> _navigateToNext() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    try {
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
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error during splash navigation: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
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
      backgroundColor: AppTheme.oledBlack,
      body: Center(
        child: Lottie.network(
          'https://lottie.host/25f804e5-3261-44c7-8708-bfcb6c159480/L7QjCOILSv.json',
          width: 300,
          height: 300,
          fit: BoxFit.contain,
          controller: _controller,
          errorBuilder: (context, error, stackTrace) {
            // If network fails to fetch, show a nice fallback logo and navigate immediately
            debugPrint('⚠️ Lottie network error: $error');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToNext();
            });
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.sovereignTeal, Color(0xFF0A1F18)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.sovereignTeal.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Learno',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ],
            );
          },
          onLoaded: (composition) {
            // Configure the controller duration to match the Lottie file exactly
            _controller
              ..duration = composition.duration
              ..forward().then((_) {
                // Rule: No Loop. Navigate to Next Screen immediately after animation ends
                _navigateToNext();
              });
          },
        ),
      ),
    );
  }
}
