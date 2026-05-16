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
      onTap: () {},
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
            borderRadius: BorderRadius.circular(24),
            // No Border as requested
            boxShadow: [
              // Purple Halo Glow
              BoxShadow(
                color: const Color(0xFF480CA8).withOpacity(0.3),
                blurRadius: 35,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Subtle glass
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: const Color(0xFF121212), // Deep gray as requested
                ),
                child: Stack(
                  children: [
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
                                color: Colors.white12,
                                fontSize: 8,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Icon(Icons.verified_user_outlined, color: Colors.white10, size: 18),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        Row(
                          children: [
                            // Avatar
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: avatarUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(avatarUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: Colors.white.withOpacity(0.03),
                              ),
                              child: avatarUrl == null
                                  ? const Icon(Icons.person_outline, color: Colors.white12, size: 35)
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
                                      color: AppTheme.offWhite,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'ID: @$username',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildTag('LVL $level', const Color(0xFF480CA8)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        _buildDataRow('المدرسة', school),
                        if (!isTeacher)
                          _buildDataRow('الصف', 'الصف $grade "$section"')
                        else
                          _buildDataRow('المواد', subjects),
                        
                        const SizedBox(height: 15),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 15),

                        // Stats
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
          Text('$label: ', style: const TextStyle(color: Colors.white12, fontSize: 10)),
          Text(value, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w300)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.white10, fontSize: 8)),
      ],
    );
  }
}
