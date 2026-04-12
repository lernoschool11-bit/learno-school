import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import 'chat_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _followLoading = false;
  bool _msgLoading = false;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getUserById(widget.userId),
        _api.getUserProfile(),
      ]);
      setState(() {
        _profile = results[0] as Map<String, dynamic>;
        _currentUserId = (results[1] as Map<String, dynamic>)['id'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);
    try {
      final result = await _api.toggleFollow(widget.userId);
      if (result.containsKey('isFollowing')) {
        setState(() {
          _profile!['isFollowing'] = result['isFollowing'];
          _profile!['followersCount'] = result['followersCount'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تنفيذ العملية، حاول مرة أخرى')),
        );
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  Future<void> _openDm() async {
    if (_msgLoading) return;
    setState(() => _msgLoading = true);
    try {
      final conv = await _api.sendDmRequest(widget.userId);
      if (!mounted) return;
      if (conv.isNotEmpty && conv['id'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversationId: conv['id'],
              otherUserName: _profile!['fullName'] ?? 'مستخدم',
              currentUserId: _currentUserId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح المحادثة، حاول مرة أخرى')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ، تحقق من الاتصال')),
        );
      }
    } finally {
      if (mounted) setState(() => _msgLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('تعذر تحميل البروفايل')),
      );
    }

    final isTeacher = _profile!['role'] == 'TEACHER';
    final isMe = _currentUserId == widget.userId;
    final isFollowing = _profile!['isFollowing'] ?? false;
    final posts = (_profile!['posts'] as List<dynamic>? ?? [])
        .map((p) => PostModel.fromJson(p))
        .toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // الهيدر
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A2342),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white.withAlpha(50),
                      backgroundImage: (_profile!['avatarUrl'] != null &&
                              (_profile!['avatarUrl'] as String).isNotEmpty)
                          ? NetworkImage(_profile!['avatarUrl'])
                          : null,
                      child: (_profile!['avatarUrl'] == null ||
                              (_profile!['avatarUrl'] as String).isEmpty)
                          ? Text(
                              (_profile!['fullName'] as String? ?? '؟')[0],
                              style: const TextStyle(
                                fontSize: 36,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _profile!['fullName'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${_profile!['username'] ?? ''}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTeacher
                            ? Colors.teal
                            : Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isTeacher ? 'معلم' : 'طالب',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // أزرار المتابعة والمراسلة
                    if (!isMe)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _followLoading ? null : _toggleFollow,
                            icon: _followLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    isFollowing
                                        ? Icons.person_remove
                                        : Icons.person_add,
                                    size: 18,
                                  ),
                            label:
                                Text(isFollowing ? 'إلغاء المتابعة' : 'متابعة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isFollowing ? Colors.red : Colors.white,
                              foregroundColor: isFollowing
                                  ? Colors.white
                                  : const Color(0xFF0A2342),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          /* const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _msgLoading ? null : _openDm,
                            icon: _msgLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0A2342),
                                    ),
                                  )
                                : const Icon(Icons.message, size: 18),
                            label: const Text('مراسلة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0A2342),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ), */
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // الإحصائيات
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _statCard('المنشورات',
                        '${_profile!['postsCount'] ?? 0}', Icons.article),
                    const SizedBox(width: 12),
                    _statCard('المتابعون',
                        '${_profile!['followersCount'] ?? 0}', Icons.people),
                    const SizedBox(width: 12),
                    _statCard('يتابع',
                        '${_profile!['followingCount'] ?? 0}', Icons.person_add),
                  ],
                ),
              ),
            ),

            // المعلومات
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _infoTile(Icons.school, 'المدرسة',
                          _profile!['school'] ?? 'غير محدد'),
                      if (!isTeacher && _profile!['grade'] != null) ...[
                        const Divider(height: 1),
                        _infoTile(
                          Icons.class_,
                          'الصف والشعبة',
                          'الصف ${_profile!['grade']} - شعبة ${_profile!['section'] ?? ''}',
                        ),
                      ],
                      if (isTeacher &&
                          (_profile!['subjects'] as List?)?.isNotEmpty ==
                              true) ...[
                        const Divider(height: 1),
                        _infoTile(
                          Icons.book,
                          'المواد',
                          (_profile!['subjects'] as List).join('، '),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // عنوان المنشورات
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'المنشورات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),

            // المنشورات
            if (posts.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'لا يوجد منشورات بعد',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PostCard(
                    post: posts[index],
                    currentUserId: _currentUserId,
                    onDeleted: _loadData,
                  ),
                  childCount: posts.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2342).withAlpha(15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0A2342), size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2342),
              ),
            ),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0A2342)),
      title:
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(
        value,
        style:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }
}
