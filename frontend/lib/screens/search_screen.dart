import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import 'user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  late TabController _tabController;

  List<PostModel> _postResults = [];
  List<Map<String, dynamic>> _peopleResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final profile = await _apiService.getUserProfile();
      setState(() => _currentUserId = profile['id'] ?? '');
    } catch (e) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    final results = await Future.wait([
      _apiService.searchPosts(query.trim()),
      _apiService.searchUsers(query.trim()),
    ]);
    setState(() {
      _postResults = results[0] as List<PostModel>;
      _peopleResults = results[1] as List<Map<String, dynamic>>;
      _isLoading = false;
    });
  }

  void _openUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث'),
        bottom: _hasSearched
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(text: 'الكل (${_postResults.length + _peopleResults.length})'),
                  Tab(text: 'أشخاص (${_peopleResults.length})'),
                  Tab(text: 'منشورات (${_postResults.length})'),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'ابحث عن شخص أو محتوى...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _hasSearched = false;
                            _postResults = [];
                            _peopleResults = [];
                          });
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => _search(_searchController.text),
                      ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? _buildEmptyState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAllResults(),
                          _buildPeopleResults(),
                          _buildPostResults(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'ابحث عن أشخاص أو محتوى',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'اكتب اسم المستخدم أو موضوع تعليمي',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildAllResults() {
    if (_postResults.isEmpty && _peopleResults.isEmpty) {
      return const Center(
        child: Text('لا توجد نتائج', style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }
    return ListView(
      children: [
        if (_peopleResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('أشخاص', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ..._peopleResults.take(3).map((user) => _buildPersonCard(user)),
          if (_peopleResults.length > 3)
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: Text('عرض كل الأشخاص (${_peopleResults.length})'),
            ),
        ],
        if (_postResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('منشورات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ..._postResults.take(3).map((post) => PostCard(post: post, currentUserId: _currentUserId)),
          if (_postResults.length > 3)
            TextButton(
              onPressed: () => _tabController.animateTo(2),
              child: Text('عرض كل المنشورات (${_postResults.length})'),
            ),
        ],
      ],
    );
  }

  Widget _buildPeopleResults() {
    if (_peopleResults.isEmpty) {
      return const Center(child: Text('لا يوجد أشخاص', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: _peopleResults.length,
      itemBuilder: (context, index) => _buildPersonCard(_peopleResults[index]),
    );
  }

  Widget _buildPostResults() {
    if (_postResults.isEmpty) {
      return const Center(child: Text('لا توجد منشورات', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: _postResults.length,
      itemBuilder: (context, index) => PostCard(post: _postResults[index], currentUserId: _currentUserId),
    );
  }

  Widget _buildPersonCard(Map<String, dynamic> user) {
    final isTeacher = user['role'] == 'TEACHER';
    final subjects = (user['subjects'] as List<dynamic>?)?.join('، ') ?? '';
    final avatarUrl = user['avatarUrl'] as String?;
    final fullName = user['fullName'] as String? ?? '؟';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () => _openUserProfile(user['id'] ?? ''),
        leading: CircleAvatar(
          backgroundColor: isTeacher ? Colors.teal : const Color(0xFF0A2342),
          radius: 24,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
                  fullName[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user['username'] ?? ''}', style: const TextStyle(color: Colors.grey)),
            if (isTeacher && subjects.isNotEmpty)
              Text('المواد: $subjects', style: const TextStyle(color: Colors.teal, fontSize: 12)),
            if (!isTeacher && user['grade'] != null)
              Text(
                'الصف ${user['grade']} - شعبة ${user['section'] ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isTeacher ? Colors.teal.withAlpha(30) : const Color(0xFF0A2342).withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isTeacher ? 'معلم' : 'طالب',
            style: TextStyle(
              fontSize: 11,
              color: isTeacher ? Colors.teal : const Color(0xFF0A2342),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}