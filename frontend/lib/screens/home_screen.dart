import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import 'notifications_screen.dart';
import 'direct_messages_screen.dart';
import '../widgets/glass_card.dart';
import '../widgets/tilt_card.dart';
import '../widgets/staggered_slide_animation.dart';
import '../widgets/dynamic_effects.dart';
import '../widgets/ai_orb_button.dart';
import 'online_classes_screen.dart';

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
  int _activityScore = 0;
  int _activeClassesCount = 0;
  Map<String, dynamic> _userProfile = {};

  List<PostModel> get _topPosts {
    final sorted = List<PostModel>.from(_posts);
    sorted.sort((a, b) => (b.likes + b.comments).compareTo(a.likes + a.comments));
    return sorted.take(5).toList();
  }

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
        _apiService.getSchoolStats(),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final posts = results[1] as List<PostModel>;
      final unreadCount = results[2] as int;
      final stats = results[3] as Map<String, dynamic>;
      
      final activeClasses = await _apiService.getActiveOnlineClasses();

      setState(() {
        _userProfile = profile;
        _currentUserId = profile['id'] ?? '';
        _posts = posts;
        _unreadCount = unreadCount;
        _activityScore = stats['activityScore'] ?? 0;
        _activeClassesCount = activeClasses.length;
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
          // Online Classes Button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.video_camera_front_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OnlineClassesScreen(userProfile: _userProfile)),
                  ).then((_) => _loadData());
                },
              ),
              if (_activeClassesCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                  ),
                ),
            ],
          ),
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
          ).wrapWithBounce(),
        ],
      ),
      body: GlowScrollFollower(child: _buildBody()),
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
        itemCount: _posts.length + 2, // +1 for activity bar, +1 for horizontal list
        itemBuilder: (context, index) {
          if (index == 0) {
            // Task 2: Interactive Analytics Bar
            return SchoolActivityBar(activityScore: _activityScore);
          }

          if (index == 1) {
            // Task 2: Horizontal ListView for "Featured Content"
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'أبرز الأنشطة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_topPosts.isNotEmpty)
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _topPosts.length,
                      itemBuilder: (context, i) {
                        final post = _topPosts[i];
                        return StaggeredSlideAnimation(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: TiltCard(
                              child: AnimatedBounce(
                                onTap: () {},
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        post.type == 'IMAGE' ? Icons.image : 
                                        post.type == 'VIDEO' ? Icons.play_circle :
                                        post.type == 'DOCUMENT' ? Icons.description :
                                        Icons.text_snippet,
                                        color: AppTheme.primaryColor,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        post.authorName,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${post.likes} إعجاب',
                                        style: TextStyle(fontSize: 10, color: AppTheme.primaryColor.withAlpha(200)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            );
          }

          final postIndex = index - 2;
          // Task 4: Staggered Entry Animations
          return StaggeredSlideAnimation(
            index: index,
            child: PostCard(
              post: _posts[postIndex],
              currentUserId: _currentUserId,
              onDeleted: () => _removePost(_posts[postIndex].id),
            ),
          );
        },
      ),
    );
  }
}

class SchoolActivityBar extends StatefulWidget {
  final int activityScore;
  const SchoolActivityBar({super.key, required this.activityScore});

  @override
  State<SchoolActivityBar> createState() => _SchoolActivityBarState();
}

class _SchoolActivityBarState extends State<SchoolActivityBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    final double endValue = widget.activityScore / 100.0;
    _progressAnimation = Tween<double>(begin: 0, end: endValue).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const SpringCurve(),
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(SchoolActivityBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activityScore != widget.activityScore) {
      final double endValue = widget.activityScore / 100.0;
      _progressAnimation = Tween<double>(begin: _progressAnimation.value, end: endValue).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const SpringCurve(),
        ),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 8), // Padding for transparent app bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نشاط المدرسة المتوقع',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor.withAlpha(200),
                  fontWeight: FontWeight.bold,
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Text(
                    '${(_progressAnimation.value * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,
                      color: Colors.white.withAlpha(20),
                    ),
                    Container(
                      height: 4,
                      width: MediaQuery.of(context).size.width * _progressAnimation.value,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withAlpha(150),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SpringCurve extends Curve {
  const SpringCurve();

  @override
  double transformInternal(double t) {
    const double s = 0.15;
    return pow(2, -10 * t) * sin((t - s / 4) * (2 * pi) / s) + 1;
  }
}