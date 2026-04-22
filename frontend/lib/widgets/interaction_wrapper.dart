import 'package:flutter/material.dart';

class InteractiveScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const InteractiveScale({super.key, required this.child, this.onTap});

  @override
  State<InteractiveScale> createState() => _InteractiveScaleState();
}

class _InteractiveScaleState extends State<InteractiveScale> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
      onTapDown: (_) => _controller.forward(),
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

class ScrollGlowPath extends StatefulWidget {
  final Widget child;
  const ScrollGlowPath({super.key, required this.child});

  @override
  State<ScrollGlowPath> createState() => _ScrollGlowPathState();
}

class _ScrollGlowPathState extends State<ScrollGlowPath> {
  double _scrollProgress = 0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          setState(() {
            _scrollProgress = notification.metrics.pixels / notification.metrics.maxScrollExtent;
          });
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          // Glow Path Edge Effect
          Positioned(
            right: 0,
            top: _scrollProgress * MediaQuery.of(context).size.height,
            child: Container(
              width: 4,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.cyan.withAlpha(200),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withAlpha(100),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
