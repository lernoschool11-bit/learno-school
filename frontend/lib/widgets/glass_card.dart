import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ──────────────────────────────────────────────────────────────
/// GlassCard – Frosted-glass wrapper widget
/// ──────────────────────────────────────────────────────────────
/// Wrap any child with `GlassCard(child: ...)` to get the
/// signature glassmorphism look:
///   • BackdropFilter blur
///   • Semi-transparent fill
///   • Subtle white border
///   • Optional neon glow
///
/// IMPORTANT: This widget does NOT contain any business logic.
/// ──────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurStrength;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? glowColor;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blurStrength = 12,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.glowColor,
    this.opacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    final glow = glowColor;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurStrength,
            sigmaY: blurStrength,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: padding,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withAlpha((opacity * 255).round()),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withAlpha(30),
                width: 1,
              ),
              boxShadow: glow != null
                  ? [
                      BoxShadow(
                        color: glow.withAlpha(40),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
