import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/interaction_wrapper.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class GradesScreen extends StatefulWidget {
  @override
  _GradesScreenState createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _grades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      final grades = await _apiService.getMyGrades();
      setState(() {
        _grades = grades;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل العلامات')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('علاماتي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : RefreshIndicator(
                onRefresh: _loadGrades,
                child: _grades.isEmpty
                    ? _buildEmptyState()
                    : _buildGradesList(),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.white24),
          SizedBox(height: 16),
          Text('لا يوجد علامات بعد', style: TextStyle(color: Colors.white70, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildGradesList() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 100, 16, 16),
      itemCount: _grades.length,
      itemBuilder: (context, index) {
        final grade = _grades[index];
        final double percentage = grade['percentage']?.toDouble() ?? 0.0;
        
        Color statusColor = Colors.greenAccent;
        if (percentage < 50) statusColor = Colors.redAccent;
        else if (percentage < 80) statusColor = Colors.orangeAccent;

        return InteractiveScale(
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${percentage.toInt()}%',
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grade['title'],
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'المادة: ${grade['subject']}',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        'بواسطة: ${grade['teacherName']}',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${grade['score']} / ${grade['maxScore']}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy-MM-dd').format(DateTime.parse(grade['createdAt'])),
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
