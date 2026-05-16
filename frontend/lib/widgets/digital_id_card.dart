import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';

class DigitalIDCard extends StatefulWidget {
  final Map<String, dynamic> userData;
  const DigitalIDCard({super.key, required this.userData});

  @override
  State<DigitalIDCard> createState() => _DigitalIDCardState();
}

class _DigitalIDCardState extends State<DigitalIDCard> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;

  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );

    // Listen to Gyroscope
    gyroscopeEvents.listen((GyroscopeEvent event) {
      if (!mounted) return;
      setState(() {
        // High-pass filter style smoothing
        _tiltY = (_tiltY * 0.9) + (event.y * 0.1);
        _tiltX = (_tiltX * 0.9) + (event.x * 0.1);
      });
    });
  }

  void _toggleFlip() {
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final angle = _flipAnimation.value;
          final isBack = angle > pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(angle)
              ..rotateX(_isFront ? (_tiltX * 0.05).clamp(-0.2, 0.2) : 0)
              ..rotateY(angle + (_isFront ? (_tiltY * 0.05).clamp(-0.2, 0.2) : 0)),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildBackFace(),
                  )
                : _buildFrontFace(),
          );
        },
      ),
    );
  }

  Widget _buildFrontFace() {
    final fullName = widget.userData['fullName'] ?? 'طالب ليرنو';
    final grade = widget.userData['grade'] ?? 'غير محدد';
    final section = widget.userData['section'] ?? '';
    final studentId = widget.userData['nationalId'] ?? 'ID: 00000000';
    final points = widget.userData['points'] ?? 0;
    final rank = widget.userData['rank'] ?? 'مبتدئ';

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.iceBlue.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.iceBlue.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black.withOpacity(0.7),
            child: Stack(
              children: [
                // Metallic Chip Shimmer
                Positioned(
                  right: 0,
                  top: 40,
                  child: _buildSmartChip(),
                ),

                // Micro Text Labels
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LEARNO DIGITAL ID // v2.0',
                      style: TextStyle(
                        color: AppTheme.iceBlue,
                        fontSize: 8,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ST. SECURE',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 8,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),

                // Main Content
                Padding(
                  padding: const EdgeInsets.only(top: 25),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.iceBlue, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.iceBlue.withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: widget.userData['avatarUrl'] != null
                              ? Image.network(widget.userData['avatarUrl'], fit: BoxFit.cover)
                              : const Icon(Icons.person, color: AppTheme.iceBlue, size: 40),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'الصف $grade "$section"',
                              style: TextStyle(
                                color: AppTheme.iceBlue.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              studentId,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // XP Bar & Rank
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rank,
                            style: const TextStyle(
                              color: AppTheme.iceBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$points XP',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildXPBar(points),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackFace() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.nightPurple.withOpacity(0.3), width: 1.5),
        color: const Color(0xFF0A0A0F),
      ),
      child: Stack(
        children: [
          // Background Tech Grid (Optional/Abstract)
          Opacity(
            opacity: 0.1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 20),
              itemBuilder: (_, __) => Container(decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 0.1))),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'التوثيق الرقمي والجوائز',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.nightPurple.withOpacity(0.5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: widget.userData['id'] ?? 'user_id',
                        version: QrVersions.auto,
                        size: 100.0,
                        gapless: false,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Badges Grid
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الألقاب الرقمية', style: TextStyle(color: Colors.white38, fontSize: 10)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildBadge(Icons.auto_awesome, Colors.amber),
                              _buildBadge(Icons.code, Colors.blue),
                              _buildBadge(Icons.psychology, Colors.purple),
                              _buildBadge(Icons.verified, Colors.green),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'NFC ENABLED // TAP TO SCAN',
                  style: TextStyle(color: AppTheme.nightPurple, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPBar(int points) {
    double progress = (points % 1000) / 1000.0;
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.05, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.xpGradient,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.iceBlue.withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartChip() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 3),
      curve: Curves.linear,
      onEnd: () {}, // Repeat logic could be added
      builder: (context, value, child) {
        return Container(
          width: 45,
          height: 35,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFFFD700), Color(0xFFD4AF37)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 5,
              ),
            ],
          ),
          child: CustomPaint(
            painter: ChipLinesPainter(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-2 + (value * 4), -1),
                  end: Alignment(-1 + (value * 4), 1),
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

class ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 1; i < 4; i++) {
      path.moveTo(0, size.height * i / 4);
      path.lineTo(size.width, size.height * i / 4);
      path.moveTo(size.width * i / 4, 0);
      path.lineTo(size.width * i / 4, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
