import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/luxury_button.dart';
import '../widgets/post_card.dart';
import '../models/post_model.dart';
import 'login_screen.dart';
import 'user_profile_screen.dart';
import 'edit_profile_screen.dart';
import 'admin_panel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _error;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final me = await _apiService.getUserProfile();
      _currentUserId = me['id'] ?? '';
      final profile = await _apiService.getUserById(_currentUserId);
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذر تحميل الملف الشخصي';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _apiService.clearToken();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _openEditProfile() async {
    final me = await _apiService.getUserProfile();
    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(currentProfile: me),
      ),
    );
    if (result == true) {
      _fetchProfile();
    }
  }

  void _openFollowersList() => _openUsersList('المتابعون', 'followers');
  void _openFollowingList() => _openUsersList('يتابع', 'following');

  void _openUsersList(String title, String type) {
    final list = type == 'followers'
        ? (_userProfile!['followers'] as List<dynamic>? ?? [])
        : (_userProfile!['following'] as List<dynamic>? ?? []);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text('لا يوجد بعد', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final user = list[index] as Map<String, dynamic>;
                      final isTeacher = user['role'] == 'TEACHER';
                      return ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(userId: user['id'] ?? ''),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: isTeacher ? Colors.teal : AppTheme.primaryColor,
                          backgroundImage: user['avatarUrl'] != null
                              ? NetworkImage(user['avatarUrl'])
                              : null,
                          child: user['avatarUrl'] == null
                              ? Text(
                                  (user['fullName'] as String? ?? '؟')[0],
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(user['fullName'] ?? ''),
                        subtitle: Text('@${user['username'] ?? ''}'),
                        trailing: Text(
                          isTeacher ? 'معلم' : 'طالب',
                          style: TextStyle(
                            color: isTeacher ? Colors.teal : AppTheme.primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_userProfile != null && _userProfile!['role'] == 'ADMIN')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanel())),
            ),
          IconButton(icon: const Icon(Icons.edit), onPressed: _openEditProfile),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchProfile, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    if (_userProfile == null) return const Center(child: Text('لا توجد بيانات'));

    final isTeacher = _userProfile!['role'] == 'TEACHER';
    final subjects = (_userProfile!['subjects'] as List<dynamic>?)?.join('، ') ?? '';
    final grade = _userProfile!['grade'];
    final section = _userProfile!['section'];
    final avatarUrl = _userProfile!['avatarUrl'];
    final posts = (_userProfile!['posts'] as List<dynamic>? ?? [])
        .map((p) => PostModel.fromJson(p))
        .toList();

    return RefreshIndicator(
      onRefresh: _fetchProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // الهيدر
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 32, top: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF0A2342),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // صورة البروفايل - Centered and Fixed Distortion
                  GestureDetector(
                    onTap: _openEditProfile,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                        image: avatarUrl != null 
                          ? DecorationImage(
                              image: NetworkImage(avatarUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                        color: Colors.white.withAlpha(50),
                      ),
                      child: avatarUrl == null
                          ? Center(
                              child: Text(
                                (_userProfile!['fullName'] as String? ?? '؟')[0],
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userProfile!['fullName'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${_userProfile!['username'] ?? ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isTeacher ? Colors.teal : Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isTeacher ? 'معلم' : 'طالب',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // الإحصائيات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatCard('المنشورات', '${_userProfile!['postsCount'] ?? 0}', Icons.article, null),
                  const SizedBox(width: 12),
                  _buildStatCard('المتابعون', '${_userProfile!['followersCount'] ?? 0}', Icons.people, _openFollowersList),
                  const SizedBox(width: 12),
                  _buildStatCard('يتابع', '${_userProfile!['followingCount'] ?? 0}', Icons.person_add, _openFollowingList),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // المعلومات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _buildInfoTile(Icons.school, 'المدرسة', _userProfile!['school'] ?? 'غير محدد'),
                    if (!isTeacher && grade != null) ...[
                      const Divider(height: 1),
                      _buildInfoTile(Icons.class_, 'الصف والشعبة', 'الصف $grade - شعبة ${section ?? ''}'),
                    ],
                    if (isTeacher && subjects.isNotEmpty) ...[
                      const Divider(height: 1),
                      _buildInfoTile(Icons.book, 'المواد', subjects),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // المنشورات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('منشوراتي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${posts.length} منشور', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            if (posts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('لا يوجد منشورات بعد', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) => PostCard(
                  post: posts[index],
                  currentUserId: _currentUserId,
                  onDeleted: _fetchProfile,
                ),
              ),

            const SizedBox(height: 16),

            // زر تسجيل الخروج
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LuxuryButton(
                label: 'تسجيل الخروج',
                onPressed: _logout,
                icon: Icons.logout,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 22),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0A2342)),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    );
  }
}