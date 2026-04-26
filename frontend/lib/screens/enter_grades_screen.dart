import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/luxury_button.dart';
import '../widgets/interaction_wrapper.dart';

class EnterGradesScreen extends StatefulWidget {
  @override
  _EnterGradesScreenState createState() => _EnterGradesScreenState();
}

class _EnterGradesScreenState extends State<EnterGradesScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _students = [];
  String? _selectedStudentId;
  String _selectedGrade = '4';
  String _selectedSection = 'أ';
  final List<String> _grades = ['4', '5', '6', '7', '8', '9', '10'];
  final List<String> _sections = ['أ', 'ب', 'ج', 'د'];

  String _subject = '';
  String _title = '';
  double _score = 0;
  double _maxScore = 100;
  bool _isLoading = false;
  bool _isFetchingStudents = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isFetchingStudents = true);
    try {
      final students = await _apiService.getSchoolUsers();
      debugPrint('Loaded ${students.length} school users');
      setState(() {
        _students = students.where((u) => u['role'] == 'STUDENT').toList();
        debugPrint('Found ${_students.length} students');
        _isFetchingStudents = false;
      });
    } catch (e) {
      debugPrint('Error loading students: $e');
      setState(() => _isFetchingStudents = false);
    }
  }

  List<dynamic> _getFilteredStudents() {
    return _students.where((s) {
      final sGrade = s['grade']?.toString().trim();
      final sSection = s['section']?.toString().trim();
      final selectedGrade = _selectedGrade.trim();
      final selectedSection = _selectedSection.trim();
      
      return sGrade == selectedGrade && sSection == selectedSection;
    }).toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى ملء جميع الحقول واختيار طالب')));
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.addGrade(
        studentId: _selectedStudentId!,
        subject: _subject,
        title: _title,
        score: _score,
        maxScore: _maxScore,
      );

      setState(() => _isLoading = false);
      if (result.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ العلامة بنجاح')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل في حفظ العلامة')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الاتصال بالخادم')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('إدخال العلامات', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: _isFetchingStudents 
          ? Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 120, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildFilters(),
                    SizedBox(height: 20),
                    _buildDropdown(),
                    SizedBox(height: 20),
                    _buildTextField('المادة (مثلاً: رياضيات)', (val) => _subject = val),
                    SizedBox(height: 20),
                    _buildTextField('عنوان الاختبار (مثلاً: الشهر الأول)', (val) => _title = val),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildNumberField('العلامة', (val) => _score = double.tryParse(val) ?? 0)),
                        SizedBox(width: 20),
                        Expanded(child: _buildNumberField('العلامة الكاملة', (val) => _maxScore = double.tryParse(val) ?? 100)),
                      ],
                    ),
                    SizedBox(height: 40),
                    _isLoading
                      ? CircularProgressIndicator(color: Colors.blueAccent)
                      : LuxuryButton(
                          label: 'حفظ العلامة',
                          onPressed: _submit,
                          icon: Icons.save_rounded,
                        ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('تصفية الطلاب:', style: TextStyle(color: Colors.white70, fontSize: 14)),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGrade,
                dropdownColor: Color(0xFF1E293B),
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'الصف',
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _grades.map((g) => DropdownMenuItem(value: g, child: Text('صف $g'))).toList(),
                onChanged: (val) => setState(() { _selectedGrade = val!; _selectedStudentId = null; }),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedSection,
                dropdownColor: Color(0xFF1E293B),
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'الشعبة',
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() { _selectedSection = val!; _selectedStudentId = null; }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    final filtered = _getFilteredStudents();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStudentId,
          hint: Text(filtered.isEmpty ? 'لا يوجد طلاب في هذا الصف' : 'اختر الطالب', style: TextStyle(color: Colors.white54)),
          dropdownColor: Color(0xFF1E293B),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent),
          items: filtered.map((s) {
            return DropdownMenuItem<String>(
              value: s['id'],
              child: Text(s['fullName'], style: TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedStudentId = val),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, Function(String) onSave) {
    return TextFormField(
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      validator: (val) => val == null || val.isEmpty ? 'هذا الحقل مطلوب' : null,
      onSaved: (val) => onSave(val!),
    );
  }

  Widget _buildNumberField(String label, Function(String) onSave) {
    return TextFormField(
      keyboardType: TextInputType.number,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      onSaved: (val) => onSave(val!),
    );
  }
}
