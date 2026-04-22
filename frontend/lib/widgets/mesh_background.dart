import 'dart:math';
import 'package:flutter/material.dart';

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
      duration: const Duration(seconds: 20), // Slower for "life"
    )..repeat();
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
        // OLED Black base
        Container(color: Colors.black),
        
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: MeshPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
        
        // Content
        widget.child,
      ],
    );
  }
}

class MeshPainter extends CustomPainter {
  final double animationValue;

  MeshPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120); // Blurry Gradient

    final double phase = animationValue * 2 * pi;

    // Deep Purple Blobs
    _drawBlob(
      canvas, 
      size, 
      paint, 
      const Color(0xFF6200EA).withAlpha(35), 
      0.3 + 0.15 * sin(phase), 
      0.2 + 0.15 * cos(phase), 
      0.7,
    );

    _drawBlob(
      canvas, 
      size, 
      paint, 
      const Color(0xFF7C4DFF).withAlpha(25), 
      0.8 + 0.1 * cos(phase * 0.8), 
      0.4 + 0.1 * sin(phase * 1.2), 
      0.5,
    );

    // Teal Blobs
    _drawBlob(
      canvas, 
      size, 
      paint, 
      const Color(0xFF00BFA5).withAlpha(30), 
      0.7 + 0.2 * cos(phase), 
      0.8 + 0.15 * sin(phase), 
      0.6,
    );

    _drawBlob(
      canvas, 
      size, 
      paint, 
      const Color(0xFF1DE9B6).withAlpha(20), 
      0.2 + 0.1 * sin(phase * 0.7), 
      0.7 + 0.1 * cos(phase * 1.3), 
      0.4,
    );
  }

  void _drawBlob(Canvas canvas, Size size, Paint paint, Color color, double xFactor, double yFactor, double sizeFactor) {
    paint.color = color;
    final center = Offset(size.width * xFactor, size.height * yFactor);
    canvas.drawCircle(center, size.width * sizeFactor, paint);
  }

  @override
  bool shouldRepaint(covariant MeshPainter oldDelegate) => true;
}
