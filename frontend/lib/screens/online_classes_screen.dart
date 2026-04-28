import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'meeting_room_screen.dart';
import '../services/api_service.dart';
import '../models/online_class_model.dart';
import '../theme/app_theme.dart';
import 'dart:ui';

class OnlineClassesScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const OnlineClassesScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  _OnlineClassesScreenState createState() => _OnlineClassesScreenState();
}

class _OnlineClassesScreenState extends State<OnlineClassesScreen> {
  final ApiService _apiService = ApiService();
  List<OnlineClassModel> _activeClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveClasses();
  }

  Future<void> _fetchActiveClasses() async {
    setState(() => _isLoading = true);
    try {
      final classes = await _apiService.getActiveOnlineClasses();
      setState(() {
        _activeClasses = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinClass(OnlineClassModel onlineClass) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeetingRoomScreen(
          title: onlineClass.title,
          meetingUrl: onlineClass.meetingUrl,
          userName: widget.userProfile['fullName'] ?? 'User',
        ),
      ),
    );
  }

  void _showStartClassDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    String? selectedGrade = widget.userProfile['grade'];
    String? selectedSection = widget.userProfile['section'];
    String? selectedSubject;
    
    final List<String> subjects = List<String>.from(widget.userProfile['subjects'] ?? []);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ابدأ حصة اونلاين', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildTextField(titleController, 'عنوان الحصة', Icons.title),
                      const SizedBox(height: 15),
                      _buildTextField(urlController, 'رابط الاجتماع (Zoom/Meet/Jitsi)', Icons.link),
                      const SizedBox(height: 15),
                      if (subjects.isNotEmpty)
                        DropdownButtonFormField<String>(
                          dropdownColor: Colors.grey[850],
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('المادة', Icons.book),
                          items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => selectedSubject = val,
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        onPressed: () async {
                          if (titleController.text.isEmpty) return;
                          
                          String finalUrl = urlController.text;
                          if (finalUrl.isEmpty) {
                            // Generate a unique Jitsi room name
                            final String roomName = "Learno_${widget.userProfile['schoolId'] ?? 'School'}_${DateTime.now().millisecondsSinceEpoch}";
                            finalUrl = "https://meet.jit.si/$roomName";
                          }

                          final success = await _apiService.createOnlineClass(
                            title: titleController.text,
                            meetingUrl: finalUrl,
                            grade: selectedGrade,
                            section: selectedSection,
                            subject: selectedSubject,
                          );

                          if (success) {
                            Navigator.pop(context);
                            _fetchActiveClasses();
                          }
                        },
                        child: const Text('بدأ الحصة الآن', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTeacher = widget.userProfile['role'] == 'TEACHER' || widget.userProfile['role'] == 'PRINCIPAL';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('الحصص الاونلاين', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchActiveClasses),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeClasses.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _activeClasses.length,
                  itemBuilder: (context, index) => _buildClassCard(_activeClasses[index]),
                ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: _showStartClassDialog,
              backgroundColor: Colors.blueAccent,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('بدأ حصة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_camera_front_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 20),
          Text('لا توجد حصص اونلاين حالياً', style: TextStyle(color: Colors.white54, fontSize: 18)),
          if (widget.userProfile['role'] == 'STUDENT')
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('سيظهر هنا أي حصة يبدأها مدرسوك لصفك الدراسي', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)),
            ),
        ],
      ),
    );
  }

  Widget _buildClassCard(OnlineClassModel onlineClass) {
    final bool isMyClass = onlineClass.teacherId == widget.userProfile['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent.withOpacity(0.2), Colors.purpleAccent.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            onlineClass.title,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (onlineClass.subject != null)
                            Text(
                              onlineClass.subject!,
                              style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 14),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(radius: 4, backgroundColor: Colors.green),
                          SizedBox(width: 5),
                          Text('مباشر', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundImage: onlineClass.teacherAvatar != null ? NetworkImage(onlineClass.teacherAvatar!) : null,
                      child: onlineClass.teacherAvatar == null ? const Icon(Icons.person, size: 15) : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'الأستاذ: ${onlineClass.teacherName}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _joinClass(onlineClass),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('انضمام للحصة', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (isMyClass) ...[
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('إنهاء الحصة'),
                              content: const Text('هل أنت متأكد من رغبتك في إنهاء هذه الحصة الاونلاين؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('إنهاء', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _apiService.endOnlineClass(onlineClass.id);
                            _fetchActiveClasses();
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
