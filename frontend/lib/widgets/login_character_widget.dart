import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ──────────────────────────────────────────────────────────────
// LoginCharacterWidget
// ──────────────────────────────────────────────────────────────
// If you have the Rive package installed and assets/character.riv
// in your project, uncomment the Rive section below and comment
// out the fallback.
//
// For now this provides a beautiful animated fallback character
// that still tracks the pointer and reacts to password visibility
// WITHOUT requiring the `rive` package – so it won't break your build.
//
// IMPORTANT: This widget does NOT contain any business logic.
// ──────────────────────────────────────────────────────────────

/* ─── UNCOMMENT THIS WHEN YOU ADD THE RIVE PACKAGE ───────────
import 'package:rive/rive.dart';

class LoginCharacterWidget extends StatefulWidget {
  final bool isPasswordVisible;

  const LoginCharacterWidget({
    super.key,
    this.isPasswordVisible = false,
  });

  @override
  State<LoginCharacterWidget> createState() => _LoginCharacterWidgetState();
}

class _LoginCharacterWidgetState extends State<LoginCharacterWidget> {
  StateMachineController? _controller;
  SMIBool? _coverEyes;
  SMINumber? _lookX;
  SMINumber? _lookY;

  void _onRiveInit(Artboard artboard) {
    final ctrl = StateMachineController.fromArtboard(artboard, 'State Machine 1');
    if (ctrl != null) {
      artboard.addController(ctrl);
      _controller = ctrl;
      _coverEyes = ctrl.findInput<bool>('cover_eyes') as SMIBool?;
      _lookX = ctrl.findInput<double>('look_x') as SMINumber?;
      _lookY = ctrl.findInput<double>('look_y') as SMINumber?;
    }
  }

  @override
  void didUpdateWidget(covariant LoginCharacterWidget old) {
    super.didUpdateWidget(old);
    _coverEyes?.value = widget.isPasswordVisible;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) {
        final screenW = MediaQuery.of(context).size.width;
        final screenH = MediaQuery.of(context).size.height;
        _lookX?.value = (e.position.dx / screenW - 0.5) * 100;
        _lookY?.value = (e.position.dy / screenH - 0.5) * 100;
      },
      child: SizedBox(
        height: 180,
        width: 180,
        child: RiveAnimation.asset(
          'assets/character.riv',
          fit: BoxFit.contain,
          onInit: _onRiveInit,
        ),
      ),
    );
  }
}
─── END RIVE SECTION ──────────────────────────────────────── */

// ═══════════════════════════════════════════════════════════════
// FALLBACK – Animated character without Rive dependency
// ═══════════════════════════════════════════════════════════════

class LoginCharacterWidget extends StatefulWidget {
  /// Set to `true` when the password field is in "show" mode.
  final bool isPasswordVisible;

  const LoginCharacterWidget({
    super.key,
    this.isPasswordVisible = false,
  });

  @override
  State<LoginCharacterWidget> createState() => _LoginCharacterWidgetState();
}

class _LoginCharacterWidgetState extends State<LoginCharacterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;
  Offset _pointerOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) {
        final screenW = MediaQuery.of(context).size.width;
        final screenH = MediaQuery.of(context).size.height;
        setState(() {
          _pointerOffset = Offset(
            (e.position.dx / screenW - 0.5) * 2,  // –1 → +1
            (e.position.dy / screenH - 0.5) * 2,
          );
        });
      },
      child: AnimatedBuilder(
        animation: _breathe,
        builder: (_, __) => _buildAvatar(),
      ),
    );
  }

  Widget _buildAvatar() {
    final breatheScale = 1.0 + _breathe.value * 0.04;
    final eyeOffsetX = _pointerOffset.dx * 6;
    final eyeOffsetY = _pointerOffset.dy * 4;
    final coverEyes = widget.isPasswordVisible;

    return Transform.scale(
      scale: breatheScale,
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Outer glow ring ──
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.neonCyan.withAlpha(50),
                    AppTheme.neonMagenta.withAlpha(20),
                    Colors.transparent,
                  ],
                  stops: const [0.5, 0.8, 1.0],
                ),
              ),
            ),
            // ── Face circle ──
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  width: 2,
                  color: AppTheme.neonCyan.withAlpha(100),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonCyan.withAlpha(40),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            // ── Eyes ──
            if (!coverEyes)
              Positioned(
                top: 50 + eyeOffsetY,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Eye(offsetX: eyeOffsetX, offsetY: eyeOffsetY),
                    const SizedBox(width: 24),
                    _Eye(offsetX: eyeOffsetX, offsetY: eyeOffsetY),
                  ],
                ),
              ),
            // ── Covering hands (when password visible) ──
            if (coverEyes)
              Positioned(
                top: 44,
                child: AnimatedOpacity(
                  opacity: coverEyes ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A4A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.neonMagenta.withAlpha(100),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 30,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A4A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.neonMagenta.withAlpha(100),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // ── Mouth ──
            Positioned(
              top: 82 + eyeOffsetY * 0.3,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: coverEyes ? 12 : 20,
                height: coverEyes ? 12 : 8,
                decoration: BoxDecoration(
                  color: coverEyes
                      ? AppTheme.neonMagenta.withAlpha(150)
                      : AppTheme.neonCyan.withAlpha(150),
                  borderRadius: BorderRadius.circular(coverEyes ? 6 : 4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single animated eye
class _Eye extends StatelessWidget {
  final double offsetX;
  final double offsetY;

  const _Eye({required this.offsetX, required this.offsetY});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(230),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withAlpha(60),
            blurRadius: 8,
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 120),
            left: 5 + offsetX * 0.5,
            top: 5 + offsetY * 0.5,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0A0A2E),
              ),
              child: Center(
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.neonCyan,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonCyan.withAlpha(180),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AnimatedBuilder is just a convenience alias for AnimatedWidget
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }

  // Override listenable getter for convenience
  Animation<double> get animation => listenable as Animation<double>;
}
