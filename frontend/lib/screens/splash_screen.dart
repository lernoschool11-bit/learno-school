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

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // مؤقت زمني ذكي: ينتقل تلقائياً بعد ثانيتين ونصف (2500 مللي ثانية)
    Future.delayed(const Duration(milliseconds: 2500), () {
      _navigateToNext();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack, // خلفية سوداء فاخرة متوافقة مع شاشات OLED
      body: Center(
        child: Lottie.asset(
          'assets/Hello (apple).json', // Local apple welcome asset
          width: 300,
          height: 300,
          fit: BoxFit.contain,
          animate: true, // تشغيل فوري وتلقائي
          repeat: false, // يعمل لمرة واحدة فقط دون تكرار
          errorBuilder: (context, error, stackTrace) {
            // واجهة الطوارئ البديلة في حال حدوث أي خطأ في الملف
            debugPrint('⚠️ Lottie asset error: $error');
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
        ),
      ),
    );
  }
}