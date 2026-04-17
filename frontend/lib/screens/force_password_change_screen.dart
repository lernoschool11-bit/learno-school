import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/luxury_button.dart';
import '../widgets/glass_card.dart';

class ForcePasswordChangeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ForcePasswordChangeScreen({super.key, required this.userData});

  @override
  State<ForcePasswordChangeScreen> createState() => _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState extends State<ForcePasswordChangeScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _selectedSchool;

  final List<String> _schools = [
    "Marj Al-Hamam",
    "Irbid Secondary",
    "Amman Academy"
  ];

  @override
  void initState() {
    super.initState();
    _selectedSchool = widget.userData['school'];
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمات المرور غير متطابقة')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await _apiService.forcePasswordChange(password);
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/'); // Go to main/home
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تغيير كلمة المرور')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.security, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              const Text(
                'إعداد الحساب لأول مرة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'يجب عليك تأكيد مدرستك وتغيير كلمة المرور الافتراضية للمتابعة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المدرسة الحالية', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedSchool,
                        isExpanded: true,
                        underline: Container(),
                        dropdownColor: AppTheme.surfaceDark,
                        items: _schools.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, style: const TextStyle(color: Colors.white)),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedSchool = val),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور الجديدة',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              LuxuryButton(
                label: 'تفعيل الحساب',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
