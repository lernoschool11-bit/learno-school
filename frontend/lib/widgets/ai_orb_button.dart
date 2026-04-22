import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/ai_chat_screen.dart';

class AIOrbButton extends StatefulWidget {
  const AIOrbButton({super.key});

  @override
  State<AIOrbButton> createState() => _AIOrbButtonState();
}

class _AIOrbButtonState extends State<AIOrbButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPressed() {
    Navigator.of(context).push(_createRevealRoute());
  }

  Route _createRevealRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const AIChatScreen(),
      transitionDuration: const Duration(milliseconds: 800),
      reverseTransitionDuration: const Duration(milliseconds: 800),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ClipPath(
          clipper: CircularRevealClipper(
            fraction: animation.value,
            center: const Offset(0.85, 0.9), // Approximate location of FAB
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withAlpha(100),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotating Ring
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * pi,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor.withAlpha(150),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Inner Orb
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withAlpha(200),
                    AppTheme.primaryColor.withAlpha(100),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset center;

  CircularRevealClipper({required this.fraction, required this.center});

  @override
  Path getClip(Size size) {
    final path = Path();
    final centerOffset = Offset(size.width * center.dx, size.height * center.dy);
    final maxRadius = sqrt(pow(size.width, 2) + pow(size.height, 2));
    path.addOval(Rect.fromCircle(center: centerOffset, radius: maxRadius * fraction));
    return path;
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) => oldClipper.fraction != fraction;
}
