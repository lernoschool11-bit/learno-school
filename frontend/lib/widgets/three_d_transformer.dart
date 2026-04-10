import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────
/// ThreeDTransformer – Adds a subtle 3D tilt to any child
/// ──────────────────────────────────────────────────────────────
/// Modes:
///   1. **Touch / pointer** – tilts toward the user's finger.
///   2. **Scroll-aware**    – set [scrollFraction] (0→1) for
///      a parallax tilt as the card enters/exits the viewport.
///
/// Usage:
///   ThreeDTransformer(child: MyCard())  // touch mode (default)
///
///   ThreeDTransformer(                  // scroll mode
///     scrollFraction: fraction,
///     child: MyCard(),
///   )
///
/// IMPORTANT: This widget does NOT contain any business logic.
/// ──────────────────────────────────────────────────────────────

class ThreeDTransformer extends StatefulWidget {
  final Widget child;

  /// Max tilt angle in radians (default ≈ 4°).
  final double maxTilt;

  /// If non-null, drives the tilt from scroll position instead of pointer.
  /// Should be a value from 0.0 (top) to 1.0 (bottom).
  final double? scrollFraction;

  /// Duration for the spring-back animation.
  final Duration resetDuration;

  const ThreeDTransformer({
    super.key,
    required this.child,
    this.maxTilt = 0.07,
    this.scrollFraction,
    this.resetDuration = const Duration(milliseconds: 400),
  });

  @override
  State<ThreeDTransformer> createState() => _ThreeDTransformerState();
}

class _ThreeDTransformerState extends State<ThreeDTransformer> {
  double _rotateX = 0;
  double _rotateY = 0;

  @override
  Widget build(BuildContext context) {
    // ── Scroll-driven mode ─────────────────────────────
    if (widget.scrollFraction != null) {
      final f = (widget.scrollFraction! - 0.5) * 2; // –1 → +1
      return Transform(
        alignment: FractionalOffset.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(f * widget.maxTilt),
        child: widget.child,
      );
    }

    // ── Pointer-driven mode ────────────────────────────
    return MouseRegion(
      onHover: (e) => _onPointer(e.localPosition, e),
      onExit: (_) => _reset(),
      child: GestureDetector(
        onPanUpdate: (d) => _onPointerRaw(d.localPosition),
        onPanEnd: (_) => _reset(),
        child: AnimatedContainer(
          duration: widget.resetDuration,
          curve: Curves.easeOutBack,
          child: Transform(
            alignment: FractionalOffset.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_rotateX)
              ..rotateY(_rotateY),
            child: widget.child,
          ),
        ),
      ),
    );
  }

  void _onPointer(Offset local, PointerEvent e) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    _onPointerRaw(local);
  }

  void _onPointerRaw(Offset local) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    // Normalise –1 → +1
    final nx = (local.dx / size.width  - 0.5) * 2;
    final ny = (local.dy / size.height - 0.5) * 2;

    setState(() {
      _rotateY =  nx * widget.maxTilt;
      _rotateX = -ny * widget.maxTilt;
    });
  }

  void _reset() {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
    });
  }
}
