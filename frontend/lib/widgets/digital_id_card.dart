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
            // Border removed as requested
            boxShadow: [
              // Sovereign Halo Glow (Low opacity)
              BoxShadow(
                color: AppTheme.sovereignTeal.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: const Color(0xFF0A0A0A), // Deep Surface color
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // School Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          school.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white12,
                            fontSize: 8,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const Icon(Icons.shield_outlined, color: Colors.white10, size: 18),
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
                            color: Colors.white.withOpacity(0.02),
                          ),
                          child: avatarUrl == null
                              ? const Icon(Icons.person_outline, color: Colors.white10, size: 35)
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
                                  fontWeight: FontWeight.bold, // Large titles Bold White
                                ),
                              ),
                              Text(
                                'ID: @$username',
                                style: const TextStyle(
                                  color: AppTheme.sovereignTeal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w300, // Sub-info w300
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildTag('LVL $level', AppTheme.sovereignTeal),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    _buildDataRow('المدرسة', school),
                    if (!isTeacher)
                      _buildDataRow('الصف الدراسي', 'الصف $grade "$section"')
                    else
                      _buildDataRow('المواد الدراسية', subjects),
                    
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
          Text(
            value, 
            style: const TextStyle(
              color: AppTheme.sovereignTeal, 
              fontSize: 10, 
              fontWeight: FontWeight.w300 // Sub-info w300
            )
          ),
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
        Text(
          label, 
          style: const TextStyle(
            color: AppTheme.sovereignTeal, 
            fontSize: 8,
            fontWeight: FontWeight.w300
          )
        ),
      ],
    );
  }
}
