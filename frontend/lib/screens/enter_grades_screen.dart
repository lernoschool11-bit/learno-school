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

  List<String> _teacherSubjects = [];
  String? _selectedSubject;
  String _subject = '';
  String _title = '';
  double _score = 0;
  double _maxScore = 100;
  bool _isLoading = false;
  bool _isFetchingData = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isFetchingData = true);
    try {
      final results = await Future.wait([
        _apiService.getSchoolUsers(),
        _apiService.getUserProfile(),
      ]);

      final students = results[0] as List<dynamic>;
      final profile = results[1] as Map<String, dynamic>;

      setState(() {
        _students = students.where((u) => u['role'] == 'STUDENT').toList();
        debugPrint('Found ${_students.length} students');

        if (profile['subjects'] != null) {
          _teacherSubjects = List<String>.from(profile['subjects']);
          if (_teacherSubjects.isNotEmpty) {
            _selectedSubject = _teacherSubjects[0];
            _subject = _selectedSubject!;
          }
        }
        _isFetchingData = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isFetchingData = false);
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

    final finalSubject = _teacherSubjects.isNotEmpty ? _selectedSubject : _subject;
    if (finalSubject == null || finalSubject.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى اختيار أو كتابة المادة')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.addGrade(
        studentId: _selectedStudentId!,
        subject: finalSubject,
        title: _title,
        score: _score,
        maxScore: _maxScore,
      );

      setState(() => _isLoading = false);
      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'].toString()),
          backgroundColor: Colors.redAccent,
        ));
      } else if (result.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم حفظ العلامة بنجاح'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل في حفظ العلامة'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('خطأ في الاتصال بالخادم'),
        backgroundColor: Colors.redAccent,
      ));
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
        child: _isFetchingData 
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
                    _teacherSubjects.isNotEmpty
                      ? _buildSubjectDropdown()
                      : _buildTextField('المادة (مثلاً: رياضيات)', (val) => _subject = val),
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

  Widget _buildSubjectDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedSubject,
          dropdownColor: Color(0xFF1E293B),
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'المادة الدراسية',
            labelStyle: TextStyle(color: Colors.blueAccent),
            border: InputBorder.none,
          ),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent),
          items: _teacherSubjects.map((subject) {
            return DropdownMenuItem<String>(
              value: subject,
              child: Text(subject, style: TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (val) => setState(() {
            _selectedSubject = val;
            _subject = val ?? '';
          }),
        ),
      ),
    );
  }
}
