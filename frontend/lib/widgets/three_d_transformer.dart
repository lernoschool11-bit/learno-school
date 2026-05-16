import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// ──────────────────────────────────────────────────────────────
/// PremiumThreeDTransformer – Upgraded with Gyroscope & Specular Highlights
/// ──────────────────────────────────────────────────────────────
class ThreeDTransformer extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final bool useGyro;

  const ThreeDTransformer({
    super.key,
    required this.child,
    this.maxTilt = 0.05,
    this.useGyro = true,
  });

  @override
  State<ThreeDTransformer> createState() => _ThreeDTransformerState();
}

class _ThreeDTransformerState extends State<ThreeDTransformer> {
  double _rotateX = 0;
  double _rotateY = 0;
  double _scrollProgress = 0.5;
  final GlobalKey _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_cardKey.currentContext != null) {
          final RenderBox box = _cardKey.currentContext!.findRenderObject() as RenderBox;
          final position = box.localToGlobal(Offset.zero).dy;
          final screenHeight = MediaQuery.of(context).size.height;
          
          setState(() {
            _scrollProgress = (position / screenHeight).clamp(0.0, 1.0);
          });
        }
        return false;
      },
      child: StreamBuilder<GyroscopeEvent>(
        stream: widget.useGyro ? gyroscopeEvents : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Transform gyroscope data to rotation
            _rotateY = (snapshot.data!.y * 0.05).clamp(-widget.maxTilt, widget.maxTilt);
            _rotateX = (snapshot.data!.x * 0.05).clamp(-widget.maxTilt, widget.maxTilt);
          }

          return Center(
            key: _cardKey,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002) // Perspective Depth
                ..rotateX(_rotateX)
                ..rotateY(_rotateY),
              child: Stack(
                children: [
                  // Shadow (moves in opposite direction for depth)
                  Transform.translate(
                    offset: Offset(-_rotateY * 150, -_rotateX * 150),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // The Main Card (Glassmorphism)
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: widget.child,
                    ),
                  ),

                  // Specular Highlight (Light streak on scroll)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: SpecularHighlightPainter(
                          progress: _scrollProgress,
                          tiltX: _rotateY,
                          tiltY: _rotateX,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SpecularHighlightPainter extends CustomPainter {
  final double progress;
  final double tiltX;
  final double tiltY;

  SpecularHighlightPainter({
    required this.progress,
    required this.tiltX,
    required this.tiltY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Calculate light position based on scroll and tilt
    double lightPos = progress * 2.0 - 0.5;
    lightPos += tiltX * 3.0; // Influence from gyroscope

    paint.shader = LinearGradient(
      begin: Alignment(lightPos - 0.4, lightPos - 0.4),
      end: Alignment(lightPos + 0.4, lightPos + 0.4),
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(0.6), // Specular flash
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      paint,
    );
  }

  @override
  bool shouldRepaint(SpecularHighlightPainter oldDelegate) => true;
}
