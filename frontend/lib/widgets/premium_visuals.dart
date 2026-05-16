import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 4. Animated Mesh Gradient (Liquid Background)
class PremiumMeshBackground extends StatefulWidget {
  final Widget child;
  const PremiumMeshBackground({super.key, required this.child});

  @override
  State<PremiumMeshBackground> createState() => _PremiumMeshBackgroundState();
}

class _PremiumMeshBackgroundState extends State<PremiumMeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
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
        // Dark OLED Base
        Container(color: const Color(0xFF000000)),
        
        // Moving Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                _buildBlob(
                  color: const Color(0xFF1A0B2E).withOpacity(0.6),
                  size: 500,
                  alignment: Alignment(
                    0.8 * cos(_controller.value * 2 * pi),
                    0.8 * sin(_controller.value * 2 * pi),
                  ),
                ),
                _buildBlob(
                  color: const Color(0xFF0A1A2E).withOpacity(0.5),
                  size: 600,
                  alignment: Alignment(
                    -0.8 * sin(_controller.value * 2 * pi),
                    0.8 * cos(_controller.value * 2 * pi),
                  ),
                ),
                _buildBlob(
                  color: const Color(0xFF2E0A1A).withOpacity(0.4),
                  size: 400,
                  alignment: Alignment(
                    0.5 * sin(_controller.value * 4 * pi),
                    -0.5 * cos(_controller.value * 4 * pi),
                  ),
                ),
              ],
            );
          },
        ),
        
        // The Glass Blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ),
        
        // Content
        widget.child,
      ],
    );
  }

  Widget _buildBlob({required Color color, required double size, required Alignment alignment}) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

/// 1 & 2. 3D Parallax Glass Card with Specular Highlight
class PremiumGlassCard extends StatefulWidget {
  final Widget child;
  final double height;
  final double width;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.height = 200,
    this.width = double.infinity,
  });

  @override
  State<PremiumGlassCard> createState() => _PremiumGlassCardState();
}

class _PremiumGlassCardState extends State<PremiumGlassCard> {
  double _scrollPosition = 0.0;
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
            // Normalize scroll position from 0 to 1 based on screen center
            _scrollPosition = (position / screenHeight).clamp(0.0, 1.0);
          });
        }
        return false;
      },
      child: StreamBuilder<GyroscopeEvent>(
        stream: gyroscopeEvents,
        builder: (context, snapshot) {
          double rotationX = 0;
          double rotationY = 0;

          if (snapshot.hasData) {
            // Sensitivity adjustment
            rotationX = (snapshot.data!.y * 0.05).clamp(-0.1, 0.1);
            rotationY = (snapshot.data!.x * 0.05).clamp(-0.1, 0.1);
          }

          return Center(
            key: _cardKey,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002) // Perspective depth
                ..rotateX(rotationY)
                ..rotateY(rotationX),
              child: Stack(
                children: [
                  // Shadow (moves in opposite direction)
                  Transform.translate(
                    offset: Offset(-rotationX * 100, -rotationY * 100),
                    child: Container(
                      height: widget.height,
                      width: widget.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Main Glass Body
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        height: widget.height,
                        width: widget.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1.5,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: widget.child,
                      ),
                    ),
                  ),

                  // Specular Highlight Border
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: CustomPaint(
                            painter: SpecularBorderPainter(
                              progress: _scrollPosition,
                              rotationX: rotationX,
                              rotationY: rotationY,
                            ),
                          ),
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

class SpecularBorderPainter extends CustomPainter {
  final double progress;
  final double rotationX;
  final double rotationY;

  SpecularBorderPainter({
    required this.progress,
    required this.rotationX,
    required this.rotationY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // The light streak position depends on scroll progress and tilt
    double lightPos = progress * 2.0 - 0.5; // range roughly -0.5 to 1.5
    lightPos += rotationX * 2; // Offset by tilt

    paint.shader = LinearGradient(
      begin: Alignment(lightPos - 0.3, lightPos - 0.3),
      end: Alignment(lightPos + 0.3, lightPos + 0.3),
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(0.8), // Icy White flash
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
  bool shouldRepaint(SpecularBorderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.rotationX != rotationX ||
      oldDelegate.rotationY != rotationY;
}

/// 3. Jelly Touch Effect (Elastic Response)
class JellyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const JellyButton({super.key, required this.child, required this.onTap});

  @override
  State<JellyButton> createState() => _JellyButtonState();
}

class _JellyButtonState extends State<JellyButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse().then((_) {
      // Create the bounce back effect
      _controller.animateTo(
        1.05, // Slightly overshoot
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      ).then((_) {
        _controller.animateTo(
          1.0, 
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
        );
      });
    });
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _controller.isAnimating || _controller.value != 0 
                ? (_controller.value > 1.0 ? _controller.value : _scaleAnimation.value)
                : 1.0,
            child: widget.child,
          );
        },
      ),
    );
  }
}
