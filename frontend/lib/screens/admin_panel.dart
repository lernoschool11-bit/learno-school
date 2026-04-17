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
  String? _teacherCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>;
          _users = results[1] as List<dynamic>;
          _posts = results[2] as List<dynamic>;
          _teacherCode = results[3] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.oledBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    final schoolName = _profile?['school'] ?? 'المدرسة';

    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      body: Column(
        children: [
          _buildHeader(schoolName),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.vpn_key), text: 'الوصول'),
              Tab(icon: Icon(Icons.article), text: 'المحتوى'),
              Tab(icon: Icon(Icons.people), text: 'الأعضاء'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAccessTab(),
                _buildContentTab(),
                _buildUsersTab(),
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
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryColor.withOpacity(0.2), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryColor,
            child: Text(schoolName[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schoolName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('إدارة النظام - لوحة المدير', style: TextStyle(color: AppTheme.primaryColor, fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildAccessTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إدارة وصول المعلمين', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رمز التسجيل الحالي', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('يستخدمه المعلمون الجدد للانضمام', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  _teacherCode ?? '----',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LuxuryButton(
            label: 'تغيير رمز المعلمين',
            onPressed: _updateTeacherCode,
            icon: Icons.edit,
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    return _posts.isEmpty
        ? const Center(child: Text('لا توجد منشورات حالياً', style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              final post = _posts[index];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(post['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('بواسطة: ${post['author']?['fullName'] ?? 'مجهول'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                    onPressed: () => _deletePost(post['id']),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildUsersTab() {
    return _users.isEmpty
        ? const Center(child: Text('لا يوجد أعضاء', style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              final isPrincipal = user['role'] == 'PRINCIPAL';
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                    child: user['avatarUrl'] == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user['fullName'] ?? '', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(user['role'], style: TextStyle(color: user['role'] == 'TEACHER' ? Colors.blue : Colors.green, fontSize: 11)),
                  trailing: isPrincipal
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.person_remove_outlined, color: AppTheme.errorRed),
                          onPressed: () => _deleteUser(user['id']),
                        ),
                ),
              );
            },
          );
  }
}