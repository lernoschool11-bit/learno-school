import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Task 3: Animated Bounce Effect for Buttons with Haptic Feedback
class AnimatedBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const AnimatedBounce({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
  });

  @override
  State<AnimatedBounce> createState() => _AnimatedBounceState();
}

class _AnimatedBounceState extends State<AnimatedBounce> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact(); // Task 3
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Task 4: Optimized Glow Path Follow Effect
/// Uses ValueNotifier to avoid full-widget rebuilds on scroll.
class GlowScrollFollower extends StatefulWidget {
  final Widget child;

  const GlowScrollFollower({super.key, required this.child});

  @override
  State<GlowScrollFollower> createState() => _GlowScrollFollowerState();
}

class _GlowScrollFollowerState extends State<GlowScrollFollower> {
  final ValueNotifier<double> _scrollNotifier = ValueNotifier(0.0);

  @override
  void dispose() {
    _scrollNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _scrollNotifier.value = notification.metrics.pixels;
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          ValueListenableBuilder<double>(
            valueListenable: _scrollNotifier,
            builder: (context, offset, child) {
              final screenHeight = MediaQuery.of(context).size.height + 200;
              return Stack(
                children: [
                  // Left side glow
                  Positioned(
                    left: 0,
                    top: (offset % screenHeight) - 100,
                    child: RepaintBoundary(
                      child: _NeonGlow(color: AppTheme.primaryColor),
                    ),
                  ),
                  // Right side glow
                  Positioned(
                    right: 0,
                    top: ((offset * 1.2) % screenHeight) - 100,
                    child: RepaintBoundary(
                      child: _NeonGlow(color: AppTheme.neonMagenta),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NeonGlow extends StatelessWidget {
  final Color color;
  const _NeonGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(150),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

extension WidgetBounceExtension on Widget {
  Widget wrapWithBounce({VoidCallback? onTap, double scaleDown = 0.95}) {
    return AnimatedBounce(onTap: onTap, scaleDown: scaleDown, child: this);
  }
}
