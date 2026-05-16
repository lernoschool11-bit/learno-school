import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sensors_plus/sensors_plus.dart';
import '../theme/app_theme.dart';
import 'premium_visuals.dart';

class DigitalIDCard extends StatefulWidget {
  final Map<String, dynamic> userData;
  const DigitalIDCard({super.key, required this.userData});

  @override
  State<DigitalIDCard> createState() => _DigitalIDCardState();
}

class _DigitalIDCardState extends State<DigitalIDCard> {
  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();
    gyroscopeEvents.listen((GyroscopeEvent event) {
      if (!mounted) return;
      setState(() {
        _tiltY = (_tiltY * 0.9) + (event.y * 0.1);
        _tiltX = (_tiltX * 0.9) + (event.x * 0.1);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.userData['role'] == 'TEACHER';
    final fullName = widget.userData['fullName'] ?? 'مستخدم ليرنو';
    final username = widget.userData['username'] ?? 'user';
    final grade = widget.userData['grade'] ?? 'N/A';
    final section = widget.userData['section'] ?? '';
    final school = widget.userData['school'] ?? 'مدرسة ليرنو الذكية';
    final points = widget.userData['points'] ?? 0;
    final level = (points / 100).floor() + 1;
    final followers = widget.userData['followersCount'] ?? 0;
    final following = widget.userData['followingCount'] ?? 0;
    final subjects = (widget.userData['subjects'] as List<dynamic>?)?.join('، ') ?? 'غير محدد';
    final avatarUrl = widget.userData['avatarUrl'];

    return JellyButton(
      onTap: () {}, // Interactive feel
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX((_tiltX * 0.05).clamp(-0.12, 0.12))
          ..rotateY((_tiltY * 0.05).clamp(-0.12, 0.12)),
        child: Container(
          width: double.infinity,
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.electricPurple.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: -10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Neon Gradient Border (Subtle inner glow)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: CustomPaint(
                          painter: NeonBorderPainter(),
                        ),
                      ),
                    ),

                    // Content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // School Micro-text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              school.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 8,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const Icon(Icons.blur_on, color: Colors.white10, size: 20),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        Row(
                          children: [
                            // Avatar
                            Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.electricPurple.withOpacity(0.3),
                                  width: 1,
                                ),
                                image: avatarUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(avatarUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: Colors.white.withOpacity(0.03),
                              ),
                              child: avatarUrl == null
                                  ? const Icon(Icons.person, color: Colors.white12, size: 35)
                                  : null,
                            ),
                            const SizedBox(width: 20),
                            // Basic Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'ID: @$username',
                                    style: const TextStyle(
                                      color: AppTheme.skyBlue,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildTag('LVL $level', AppTheme.electricPurple),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Extra Data (ID Style)
                        _buildDataRow('المدرسة', school),
                        if (!isTeacher)
                          _buildDataRow('الصف', 'الصف $grade "$section"')
                        else
                          _buildDataRow('المواد', subjects),
                        
                        const SizedBox(height: 15),
                        const Divider(color: Colors.white05, height: 1),
                        const SizedBox(height: 15),

                        // Stats (Followers / Following)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('المتابعون', followers.toString()),
                            _buildStat('يتابع', following.toString()),
                            _buildStat('النقاط', points.toString()),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white24, fontSize: 10)),
          Text(value, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w300)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9)),
      ],
    );
  }
}

class NeonBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = AppTheme.neonGradient.createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(32)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
