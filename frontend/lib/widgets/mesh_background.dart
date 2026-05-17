import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────
/// Upgraded Premium Mesh Background
/// ──────────────────────────────────────────────────────────────
class MeshBackground extends StatefulWidget {
  final Widget child;

  const MeshBackground({super.key, required this.child});

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Slow fluid motion
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // True OLED Black Base
        Container(color: const Color(0xFF000000)),
        
        // Moving Light Nebula
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: PremiumMeshPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
        
        // The Glass Layer (Optional extra blur for content depth)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),
        ),
        
        // Content
        widget.child,
      ],
    );
  }
}

class PremiumMeshPainter extends CustomPainter {
  final double progress;

  PremiumMeshPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    final double phase = progress * 2 * pi;

    // 1. Dark Teal (Deep)
    _drawBlob(
      canvas, size, paint,
      const Color(0xFF0A1F18).withOpacity(0.9), // Very dark teal
      0.2 + 0.1 * sin(phase),
      0.3 + 0.1 * cos(phase),
      0.8,
    );

    // 2. Sovereign Teal (Deep)
    _drawBlob(
      canvas, size, paint,
      const Color(0xFF13362E).withOpacity(0.8), // Darker Sovereign Teal
      0.8 + 0.1 * cos(phase * 0.8),
      0.2 + 0.1 * sin(phase * 1.2),
      0.7,
    );

    // 3. Absolute Black
    _drawBlob(
      canvas, size, paint,
      const Color(0xFF000000).withOpacity(0.9),
      0.5 + 0.2 * cos(phase * 0.5),
      0.8 + 0.2 * sin(phase * 0.5),
      1.0,
    );

    // 4. Subtle Mint Flash
    _drawBlob(
      canvas, size, paint,
      const Color(0xFF2E4C43).withOpacity(0.2), // Light teal flash
      0.1 + 0.3 * cos(phase * 1.5),
      0.9 + 0.1 * sin(phase * 0.7),
      0.5,
    );
  }

  void _drawBlob(Canvas canvas, Size size, Paint paint, Color color, double x, double y, double radiusFactor) {
    paint.color = color;
    canvas.drawCircle(
      Offset(size.width * x, size.height * y),
      size.width * radiusFactor,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant PremiumMeshPainter oldDelegate) => true;
}
