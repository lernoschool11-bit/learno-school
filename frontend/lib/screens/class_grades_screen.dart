import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import '../widgets/interaction_wrapper.dart';

class ClassGradesScreen extends StatefulWidget {
  @override
  _ClassGradesScreenState createState() => _ClassGradesScreenState();
}

class _ClassGradesScreenState extends State<ClassGradesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _allGrades = [];
  bool _isLoading = true;
  String _subjectFilter = '';

  @override
  void initState() {
    super.initState();
    _loadAllGrades();
  }

  Future<void> _loadAllGrades() async {
    setState(() => _isLoading = true);
    try {
      final grades = await _apiService.getClassGrades();
      setState(() {
        _allGrades = grades;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredGrades = _subjectFilter.isEmpty
        ? _allGrades
        : _allGrades.where((g) => g['subject'].contains(_subjectFilter)).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('سجل العلامات', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadAllGrades,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 110, 20, 10),
              child: _buildFilterBar(),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : filteredGrades.isEmpty
                      ? _buildEmptyState()
                      : _buildGradesTable(filteredGrades),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return TextField(
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'البحث حسب المادة...',
        hintStyle: TextStyle(color: Colors.white38),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      onChanged: (val) => setState(() => _subjectFilter = val),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_outlined, size: 80, color: Colors.white24),
          SizedBox(height: 16),
          Text('لا توجد سجلات مطابقة', style: TextStyle(color: Colors.white70, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildGradesTable(List<dynamic> grades) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: grades.length,
      itemBuilder: (context, index) {
        final g = grades[index];
        final student = g['student'];
        final double percentage = (g['score'] / g['maxScore']) * 100;

        return InteractiveScale(
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['fullName'],
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${student['grade']} - ${student['section']}',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(color: Colors.white10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g['subject'],
                        style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        g['title'],
                        style: TextStyle(color: Colors.white70, fontSize: 12, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPercentageColor(percentage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${g['score']}/${g['maxScore']}',
                    style: TextStyle(
                      color: _getPercentageColor(percentage),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getPercentageColor(double p) {
    if (p < 50) return Colors.redAccent;
    if (p < 80) return Colors.orangeAccent;
    return Colors.greenAccent;
  }
}
