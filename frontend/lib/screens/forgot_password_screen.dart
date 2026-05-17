import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/mesh_background.dart';
import '../widgets/luxury_button.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('نسيت كلمة المرور', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                const Text(
                  'إعادة تعيين كلمة المرور',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.iceBlue),
                ),
                const SizedBox(height: 32),

                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  margin: EdgeInsets.zero,
                  opacity: 0.08,
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_codeSent,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.email, color: AppTheme.primaryColor),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (!_codeSent)
                  LuxuryButton(
                    label: 'إرسال رمز التحقق',
                    isLoading: _isLoading,
                    onPressed: _sendCode,
                  ),

                if (_codeSent) ...[
                  const Text(
                    '✅ تم إرسال الرمز على بريدك، تحقق من inbox أو spam',
                    style: TextStyle(color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    margin: EdgeInsets.zero,
                    opacity: 0.08,
                    child: TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold, color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'رمز التحقق',
                        labelStyle: TextStyle(color: Colors.grey),
                        hintText: '000000',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    margin: EdgeInsets.zero,
                    opacity: 0.08,
                    child: TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور الجديدة',
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.lock, color: AppTheme.primaryColor),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    margin: EdgeInsets.zero,
                    opacity: 0.08,
                    child: TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  LuxuryButton(
                    label: 'تغيير كلمة المرور',
                    isLoading: _isLoading,
                    onPressed: _resetPassword,
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : _sendCode,
                    child: const Text('إعادة إرسال الرمز', style: TextStyle(color: AppTheme.iceBlue)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
