import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../main.dart';

class TeacherAnalyticsScreen extends StatelessWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أهلاً، الأستاذ علي',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'لوحة تحكم المعلم - إحصائيات مباشرة',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  _buildGlassProfileIcon(context),
                ],
              ),
              const SizedBox(height: 32),

              // Main Stats Carousel-like logic
              _buildMainStatCard(
                'معدل الصف العام',
                '3.8',
                Icons.trending_up,
                AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                   Expanded(
                     child: _buildSmallStatCard(
                       'الواجبات النشطة',
                       '12',
                       Icons.assignment_outlined,
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: _buildSmallStatCard(
                       'تفاعل الطلاب',
                       '94%',
                       Icons.favorite_border,
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 32),

              // Mock Chart Area
              Text(
                'أداء الطلاب الأسبوعي',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildMockChartContainer(),

              const SizedBox(height: 48),

              // Logout Button
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    'تسجيل الخروج من نظام المعلم',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassProfileIcon(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: AppTheme.glassDecoration(opacity: 0.1),
          child: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildMainStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(50), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Icon(icon, color: color, size: 48),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockChartContainer() {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildChartBar(0.4, 'Sun'),
          _buildChartBar(0.6, 'Mon'),
          _buildChartBar(0.9, 'Tue'),
          _buildChartBar(0.7, 'Wed'),
          _buildChartBar(0.85, 'Thu'),
        ],
      ),
    );
  }

  Widget _buildChartBar(double heightFactor, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(seconds: 1),
          width: 30,
          height: 140 * heightFactor,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppTheme.primaryColor.withAlpha(100),
                AppTheme.primaryColor,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withAlpha(50),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
