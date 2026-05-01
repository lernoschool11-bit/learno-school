import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/luxury_button.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  Map<String, dynamic>? _profile;
  List<dynamic> _users = [];
  List<dynamic> _posts = [];
  List<dynamic> _classes = [];
  String? _teacherCode;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getUserProfile(),
        _apiService.getSchoolUsers(),
        _apiService.getSchoolPosts(),
        _apiService.getTeacherCode(),
        _apiService.getSchoolClasses(),
        _apiService.getSchoolStats(),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>;
          _users = results[1] as List<dynamic>;
          _posts = results[2] as List<dynamic>;
          _teacherCode = results[3] as String?;
          _classes = results[4] as List<dynamic>;
          _stats = results[5] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ... (previous helper methods like _updateTeacherCode, _deletePost, etc. remain the same)
  Future<void> _updateTeacherCode() async {
    final controller = TextEditingController(text: _teacherCode);
    final newCode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('تحديث رمز المعلم', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'الرمز الجديد'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('تحديث')),
        ],
      ),
    );

    if (newCode != null && newCode.isNotEmpty) {
      final success = await _apiService.updateTeacherCode(newCode);
      if (success) {
        setState(() => _teacherCode = newCode);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الرمز')));
      }
    }
  }

  Future<void> _deletePost(String postId) async {
    final success = await _apiService.deletePost(postId);
    if (success) {
      setState(() => _posts.removeWhere((p) => p['id'] == postId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المنشور')));
    }
  }

  Future<void> _deleteUser(String userId) async {
    final success = await _apiService.deleteSchoolUser(userId);
    if (success) {
      setState(() => _users.removeWhere((u) => u['id'] == userId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المستخدم')));
    }
  }

  Future<void> _toggleUserStatus(String userId) async {
    final success = await _apiService.toggleSchoolUserStatus(userId);
    if (success) {
      setState(() {
        final index = _users.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _users[index]['isActive'] = !(_users[index]['isActive'] ?? true);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث حالة الحساب')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.oledBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    final schoolName = _profile?['school'] ?? 'المدرسة';
    final teachers = _users.where((u) => u['role'] == 'TEACHER').toList();
    final students = _users.where((u) => u['role'] == 'STUDENT').toList();

    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      body: Column(
        children: [
          _buildHeader(schoolName),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'الوصول'),
              Tab(text: 'الإحصائيات'),
              Tab(text: 'المنشورات'),
              Tab(text: 'الصفوف'),
              Tab(text: 'المعلمون'),
              Tab(text: 'الطلاب'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAccessTab(),
                _buildStatsTab(),
                _buildContentTab(),
                _buildClassesTab(),
                _buildUserListTab(teachers, 'لا يوجد معلمون حالياً'),
                _buildUserListTab(students, 'لا يوجد طلاب حالياً'),
              ],
            ),
          ),
          const SizedBox(height: 80), // Reserved for Dock
        ],
      ),
    );
  }

  Widget _buildHeader(String schoolName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryColor.withOpacity(0.15), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              schoolName.isNotEmpty ? schoolName[0] : 'S', 
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schoolName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('لوحة تحكم المدير', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildAccessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إدارة رمز المعلمين', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text('رمز التسجيل الحالي:', style: TextStyle(color: Colors.grey)),
                ),
                Text(
                  _teacherCode ?? '----',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LuxuryButton(
            label: 'تغيير الرمز',
            onPressed: _updateTeacherCode,
            icon: Icons.edit,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_stats == null) return const Center(child: Text('لا توجد إحصائيات', style: TextStyle(color: Colors.grey)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('الطلاب', _stats!['students']?.toString() ?? '0', Icons.people, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('المعلمون', _stats!['teachers']?.toString() ?? '0', Icons.person_pin, Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('المنشورات', _stats!['posts']?.toString() ?? '0', Icons.article, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('التفاعل', _stats!['comments']?.toString() ?? '0', Icons.comment, Colors.purple)),
            ],
          ),
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('درجة النشاط العامة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: (_stats!['activityScore'] ?? 0) / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.white10,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text('${_stats!['activityScore'] ?? 0}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 20),
                Text('الحالة: ${_stats!['status'] ?? '---'}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    return _posts.isEmpty
        ? const Center(child: Text('لا توجد منشورات', style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              final post = _posts[index];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(post['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text('بواسطة: ${post['author']?['fullName'] ?? 'مجهول'}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                    onPressed: () => _deletePost(post['id']),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildClassesTab() {
    return _classes.isEmpty
        ? const Center(child: Text('لا توجد صفوف مسجلة', style: TextStyle(color: Colors.grey)))
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _classes.length,
            itemBuilder: (context, index) {
              final c = _classes[index];
              return GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('صف ${c['grade']} - ${c['section']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text('${c['studentCount']} طالب', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildUserListTab(List<dynamic> users, String emptyMsg) {
    return users.isEmpty
        ? Center(child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                    child: user['avatarUrl'] == null ? const Icon(Icons.person, size: 20) : null,
                  ),
                  title: Text(user['fullName'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(user['username'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          (user['isActive'] ?? true) ? Icons.block : Icons.check_circle_outline,
                          color: (user['isActive'] ?? true) ? Colors.orange : Colors.green,
                          size: 20,
                        ),
                        onPressed: () => _toggleUserStatus(user['id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_remove_outlined, color: AppTheme.errorRed, size: 20),
                        onPressed: () => _deleteUser(user['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}