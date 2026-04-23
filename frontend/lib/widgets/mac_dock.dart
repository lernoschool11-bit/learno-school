import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ──────────────────────────────────────────────────────────────
/// MacDock – macOS-style floating bottom navigation bar
/// ──────────────────────────────────────────────────────────────
/// Features:
///   • Fisheye magnification on hover / drag
///   • Glassmorphism backdrop blur
///   • Neon glow on the active icon
///
/// Usage:
///   MacDock(
///     currentIndex: _currentIndex,
///     onTap: (i) => setState(() => _currentIndex = i),
///     items: [ MacDockItem(icon: Icons.home, label: 'Home'), ... ],
///   )
///
/// IMPORTANT: This widget does NOT contain any business logic.
/// ──────────────────────────────────────────────────────────────

class MacDockItem {
  final IconData icon;
  final String label;

  const MacDockItem({required this.icon, required this.label});
}

class MacDock extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MacDockItem> items;

  const MacDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<MacDock> createState() => _MacDockState();
}

class _MacDockState extends State<MacDock> with SingleTickerProviderStateMixin {
  /// Normalized pointer position along the dock (0.0 → 1.0).
  /// `null` means the pointer is outside the dock.
  double? _pointerX;

  // ── Layout constants ────────────────────────────────
  static const double _baseIconSize = 28;
  static const double _maxIconSize  = 44;
  static const double _dockHeight   = 68;
  static const double _iconSpacing  = 8;

  /// How many neighbouring icons are influenced by the pointer.
  static const double _influenceRadius = 2.5;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final count = items.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onExit: (_) => setState(() => _pointerX = null),
        onHover: (e) => _updatePointer(e.localPosition.dx, count),
        child: GestureDetector(
          onPanUpdate: (d) => _updatePointer(d.localPosition.dx, count),
          onPanEnd: (_) => setState(() => _pointerX = null),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: _dockHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark.withAlpha(200),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: AppTheme.primaryColor.withAlpha(80),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withAlpha(40),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: AppTheme.neonMagenta.withAlpha(20),
                      blurRadius: 60,
                      spreadRadius: -10,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(count, (i) {
                      final scale = _scaleFor(i, count);
                      final isActive = widget.currentIndex == i;
                      return _DockIcon(
                        item: items[i],
                        scale: scale,
                        isActive: isActive,
                        spacing: _iconSpacing,
                        onTap: () => widget.onTap(i),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updatePointer(double localX, int count) {
    // Total dock width (approx)
    final totalWidth = count * (_baseIconSize + _iconSpacing * 2) + 32;
    setState(() => _pointerX = (localX / totalWidth).clamp(0.0, 1.0));
  }

  double _scaleFor(int index, int count) {
    if (_pointerX == null) return 1.0;

    // Normalised icon centre position
    final centre = (index + 0.5) / count;
    final dist = (_pointerX! - centre).abs() * count;

    if (dist > _influenceRadius) return 1.0;

    // Cosine falloff
    final t = 1.0 - (dist / _influenceRadius);
    final ease = (math.cos((1 - t) * math.pi) + 1) / 2;
    return 1.0 + ease * ((_maxIconSize / _baseIconSize) - 1.0);
  }
}

/// Individual dock icon with animated scale
class _DockIcon extends StatefulWidget {
  final MacDockItem item;
  final double scale;
  final bool isActive;
  final double spacing;
  final VoidCallback onTap;

  const _DockIcon({
    required this.item,
    required this.scale,
    required this.isActive,
    required this.spacing,
    required this.onTap,
  });

  @override
  State<_DockIcon> createState() => _DockIconState();
}

class _DockIconState extends State<_DockIcon> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final size = _MacDockState._baseIconSize * widget.scale;
    // Spring effect scale
    final effectiveScale = _isPressed ? 0.85 : (widget.isActive ? 1.15 : 1.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: effectiveScale,
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.spacing),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: size + 12,
              height: size + 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isActive
                    ? AppTheme.primaryColor.withAlpha(30)
                    : Colors.transparent,
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withAlpha(60),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                widget.item.icon,
                size: size,
                color: widget.isActive
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            // Active dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: widget.isActive ? 5 : 0,
              height: widget.isActive ? 5 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withAlpha(120),
                          blurRadius: 6,
                        ),
                      ]
                    : [],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    ),
  );
}
}
