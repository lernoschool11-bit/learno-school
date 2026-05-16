import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import 'premium_visuals.dart';

class LuxuryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const LuxuryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return JellyButton(
      onTap: onPressed ?? () {},
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: onPressed == null ? null : AppTheme.sovereignGradient,
              color: onPressed == null 
                  ? Colors.white.withOpacity(0.05) 
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (onPressed != null)
                  BoxShadow(
                    color: AppTheme.sovereignTeal.withOpacity(0.15),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: AppTheme.offWhite, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppTheme.offWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w300, // Light typography
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
