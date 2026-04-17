import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import 'notifications_screen.dart';
import 'direct_messages_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<PostModel> _posts = [];
  bool _isLoading = true;
  String? _error;
  String _currentUserId = '';
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _apiService.getUserProfile(),
        _apiService.getPosts(),
        _apiService.getUnreadCount(),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final posts = results[1] as List<PostModel>;
      final unreadCount = results[2] as int;

      setState(() {
        _currentUserId = profile['id'] ?? '';
        _posts = posts;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذر تحميل المنشورات';
        _isLoading = false;
      });
    }
  }

  void _removePost(String postId) {
    setState(() {
      _posts.removeWhere((p) => p.id == postId);
    });
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    final count = await _apiService.getUnreadCount();
    setState(() => _unreadCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final String? schoolName = _posts.isNotEmpty ? _posts.first.school : null;

    return Scaffold(
      backgroundColor: Colors.transparent, // Let MainNavigation handle the background
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.black.withAlpha(120),
        elevation: 0,
        centerTitle: false,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Learno',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 24,
                letterSpacing: -0.5,
                color: AppTheme.primaryColor,
              ),
            ),
            if (schoolName != null)
              Text(
                schoolName,
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.normal),
              ),
          ],
        ),

        actions: [
          // زر الإشعارات مع العداد
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: _openNotifications,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          /* IconButton(
            icon: const Icon(Icons.mail_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DirectMessagesScreen()),
              );
            },
          ), */
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Text(
          'لا يوجد منشورات بعد',
          style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return PostCard(
            post: _posts[index],
            currentUserId: _currentUserId,
            onDeleted: () => _removePost(_posts[index].id),
          );
        },
      ),
    );
  }
}