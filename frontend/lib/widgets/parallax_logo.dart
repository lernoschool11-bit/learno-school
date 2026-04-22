import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';

class ParallaxLogo extends StatefulWidget {
  const ParallaxLogo({super.key});

  @override
  State<ParallaxLogo> createState() => _ParallaxLogoState();
}

class _ParallaxLogoState extends State<ParallaxLogo> {
  double _rotateX = 0;
  double _rotateY = 0;

  void _handleHover(PointerEvent event) {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    
    // Convert pointer position to -1.0 to 1.0 range
    final normalizedX = (event.position.dx / size.width) - 0.5;
    final normalizedY = (event.position.dy / size.height) - 0.5;

    setState(() {
      // Max tilt ~12 degrees (0.21 radians)
      _rotateX = normalizedY * -0.21;
      _rotateY = normalizedX * 0.21;
    });
  }

  void _handleExit(PointerEvent event) {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _handleHover,
      onExit: _handleExit,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(begin: Offset.zero, end: Offset(_rotateY, _rotateX)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut, // As requested for Infinix GT 20 Pro smoothness
        builder: (context, offset, child) {
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015) // Perspective depth
              ..rotateX(offset.dy)
              ..rotateY(offset.dx),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Neon Glow Background ──
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withAlpha(40),
                        blurRadius: 50,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: AppTheme.neonMagenta.withAlpha(20),
                        blurRadius: 80,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                ),
                // ── Lottie Character ──
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Lottie.asset(
                    'assets/character_logo.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if asset fails to load
                      return Icon(
                        Icons.school_rounded,
                        size: 100,
                        color: AppTheme.primaryColor,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
