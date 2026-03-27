import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/school_picker_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _fullNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'STUDENT';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedSchool = '';
  String _selectedGrade = '4';
  String _selectedSection = 'أ';
  List<String> _selectedSubjects = [];
  List<Map<String, String>> _selectedClasses = [];

  final List<String> _grades = ['4', '5', '6', '7', '8', '9', '10'];
  final List<String> _sections = ['أ', 'ب', 'ج', 'د'];
  final List<String> _subjects = [
    'رياضيات', 'علوم', 'لغة عربية', 'لغة إنجليزية',
    'فيزياء', 'كيمياء', 'أحياء', 'تاريخ', 'جغرافيا',
    'تربية إسلامية', 'تربية وطنية', 'حاسوب', 'تربية رياضية'
  ];

  final _apiService = ApiService();
  bool _isLoading = false;
  String _tempGrade = '4';
  String _tempSection = 'أ';

  String? _validatePage1() {
    if (_fullNameController.text.trim().isEmpty) return 'الرجاء إدخال الاسم الكامل';
    final nationalId = _nationalIdController.text.trim();
    if (nationalId.isNotEmpty && (nationalId.length != 10 || int.tryParse(nationalId) == null)) {
      return 'الرقم الوطني يجب أن يتكون من 10 أرقام';
    }
    if (_usernameController.text.trim().isEmpty) return 'الرجاء إدخال اسم المستخدم';
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      return 'الرجاء إدخال بريد إلكتروني صالح';
    }
    if (_dobController.text.trim().isEmpty) return 'الرجاء إدخال تاريخ الميلاد';
    if (_passwordController.text.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    if (_passwordController.text != _confirmPasswordController.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  String? _validatePage2() {
    if (_selectedSchool.isEmpty) return 'الرجاء اختيار المدرسة';
    if (_selectedRole == 'TEACHER') {
      if (_selectedSubjects.isEmpty) return 'الرجاء اختيار مادة واحدة على الأقل';
      if (_selectedClasses.isEmpty) return 'الرجاء اختيار صف وشعبة واحدة على الأقل';
    }
    return null;
  }

  void _nextPage() {
    final error = _validatePage1();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentPage = 1);
  }

  void _prevPage() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentPage = 0);
  }

  Future<void> _register() async {
    final error = _validatePage2();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    final success = await _apiService.register(
      fullName: _fullNameController.text.trim(),
      nationalId: _nationalIdController.text.trim().isNotEmpty ? _nationalIdController.text.trim() : null,
      dob: _dobController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      school: _selectedSchool,
      grade: _selectedRole == 'STUDENT' ? _selectedGrade : null,
      section: _selectedRole == 'STUDENT' ? _selectedSection : null,
      subjects: _selectedRole == 'TEACHER' ? _selectedSubjects : null,
      classes: _selectedRole == 'TEACHER' ? _selectedClasses : null,
    );
    setState(() => _isLoading = false);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الحساب بنجاح!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل التسجيل. قد تكون المعلومات مستخدمة مسبقاً.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPage == 0 ? 'تسجيل حساب جديد' : 'معلومات إضافية'),
        leading: _currentPage == 1 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage) : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF0A2342), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _currentPage == 1 ? const Color(0xFF0A2342) : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              ],
            ),
          ),
          Text('الخطوة ${_currentPage + 1} من 2', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildPage1(), _buildPage2()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('نوع الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _buildRoleButton('STUDENT', 'طالب', Icons.school)),
            const SizedBox(width: 12),
            Expanded(child: _buildRoleButton('TEACHER', 'معلم', Icons.person_pin)),
          ]),
          const SizedBox(height: 20),
          _buildField(_fullNameController, 'الاسم الكامل *', Icons.person),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nationalIdController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'الرقم الوطني (اختياري)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge), hintText: '10 أرقام'),
          ),
          const SizedBox(height: 16),
          _buildField(_usernameController, 'اسم المستخدم *', Icons.alternate_email),
          const SizedBox(height: 16),
          _buildField(_emailController, 'البريد الإلكتروني *', Icons.email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildField(_dobController, 'تاريخ الميلاد *', Icons.calendar_today, hint: '2000-01-01'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'كلمة المرور *', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'تأكيد كلمة المرور *', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A2342), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('التالي', style: TextStyle(fontSize: 18, color: Colors.white)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: Colors.white),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // School Picker
          SchoolPickerWidget(
            onSelected: (school) => setState(() => _selectedSchool = school),
          ),
          const SizedBox(height: 20),

          if (_selectedRole == 'STUDENT') ...[
            const Text('الصف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _grades.map((grade) => ChoiceChip(
                label: Text('الصف $grade'),
                selected: _selectedGrade == grade,
                selectedColor: const Color(0xFF0A2342),
                labelStyle: TextStyle(color: _selectedGrade == grade ? Colors.white : Colors.black),
                onSelected: (_) => setState(() => _selectedGrade = grade),
              )).toList(),
            ),
            const SizedBox(height: 20),
            const Text('الشعبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: _sections.map((section) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(section),
                  selected: _selectedSection == section,
                  selectedColor: const Color(0xFF0A2342),
                  labelStyle: TextStyle(color: _selectedSection == section ? Colors.white : Colors.black),
                  onSelected: (_) => setState(() => _selectedSection = section),
                ),
              )).toList(),
            ),
          ],

          if (_selectedRole == 'TEACHER') ...[
            const Text('المواد التي تدرّسها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _subjects.map((subject) => FilterChip(
                label: Text(subject),
                selected: _selectedSubjects.contains(subject),
                selectedColor: const Color(0xFF0A2342),
                labelStyle: TextStyle(color: _selectedSubjects.contains(subject) ? Colors.white : Colors.black),
                onSelected: (selected) {
                  setState(() { if (selected) _selectedSubjects.add(subject); else _selectedSubjects.remove(subject); });
                },
              )).toList(),
            ),
            const SizedBox(height: 20),
            const Text('الصفوف والشعب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildClassSelector(),
            if (_selectedClasses.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _selectedClasses.map((cls) => Chip(
                  label: Text('صف ${cls['grade']} - ${cls['section']}'),
                  backgroundColor: const Color(0xFF0A2342).withAlpha(25),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _selectedClasses.remove(cls)),
                )).toList(),
              ),
            ],
          ],

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A2342),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('إنشاء الحساب', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelector() {
    return Row(
      children: [
        Expanded(child: DropdownButtonFormField<String>(
          value: _tempGrade,
          decoration: const InputDecoration(labelText: 'الصف', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          items: _grades.map((g) => DropdownMenuItem(value: g, child: Text('صف $g'))).toList(),
          onChanged: (val) => setState(() => _tempGrade = val!),
        )),
        const SizedBox(width: 8),
        Expanded(child: DropdownButtonFormField<String>(
          value: _tempSection,
          decoration: const InputDecoration(labelText: 'الشعبة', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          items: _sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) => setState(() => _tempSection = val!),
        )),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            final cls = {'grade': _tempGrade, 'section': _tempSection};
            if (!_selectedClasses.any((c) => c['grade'] == _tempGrade && c['section'] == _tempSection)) {
              setState(() => _selectedClasses.add(cls));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A2342), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildRoleButton(String role, String label, IconData icon) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: selected ? const Color(0xFF0A2342) : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Icon(icon, color: selected ? Colors.white : Colors.grey),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, String? hint}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder(), prefixIcon: Icon(icon)),
    );
  }
}
