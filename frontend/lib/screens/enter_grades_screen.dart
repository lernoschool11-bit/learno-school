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
    try {
      final students = await _apiService.getSchoolUsers();
      setState(() {
        _students = students.where((u) => u['role'] == 'STUDENT').toList();
        _isFetchingStudents = false;
      });
    } catch (e) {
      setState(() => _isFetchingStudents = false);
    }
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
                          text: 'حفظ العلامة',
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

  Widget _buildDropdown() {
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
          hint: Text('اختر الطالب', style: TextStyle(color: Colors.white54)),
          dropdownColor: Color(0xFF1E293B),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent),
          items: _students.map((s) {
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
