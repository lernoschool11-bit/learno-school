import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/community_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/admin_panel.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'theme/app_theme.dart';
import 'widgets/mac_dock.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learno',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  String _userRole = 'STUDENT';
  bool _isRoleLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserRole();
    try {
      SocketService().connect();
    } catch (e) {
      debugPrint('Socket connection error: $e');
    }
  }

  Future<void> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();

    // اقرأ الـ cached role أولاً عشان الشاشة تفتح بسرعة
    final cachedRole = prefs.getString('userRole') ?? 'STUDENT';
    setState(() {
      _userRole = cachedRole;
      _isRoleLoading = false;
    });

    // ✅ تحقق من السيرفر عشان تلقط أي تغيير في الـ role
    try {
      final apiService = ApiService();
      final profile = await apiService.getUserProfile();
      final freshRole = profile['role'] as String? ?? 'STUDENT';

      if (freshRole != cachedRole) {
        debugPrint('🔄 Role updated: $cachedRole → $freshRole');
        await prefs.setString('userRole', freshRole);
        if (mounted) {
          setState(() => _userRole = freshRole);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Could not sync role from server: $e');
      // استمر بالـ cached role — لا مشكلة
    }
  }

  List<Widget> _getScreens() {
    return [
      const HomeScreen(),
      const SearchScreen(),
      const AIChatScreen(),
      if (_userRole == 'TEACHER' || _userRole == 'STUDENT') CreatePostScreen(userRole: _userRole),
      if (_userRole == 'PRINCIPAL') AdminPanel(),
      if (_userRole != 'PRINCIPAL') const CommunityScreen(),
      const ProfileScreen(),
    ];
  }

  List<MacDockItem> _getDockItems() {
    return [
      const MacDockItem(icon: Icons.home, label: 'الرئيسية'),
      const MacDockItem(icon: Icons.search, label: 'البحث'),
      const MacDockItem(icon: Icons.auto_awesome, label: 'الذكاء'),
      if (_userRole == 'TEACHER' || _userRole == 'STUDENT')
        const MacDockItem(icon: Icons.add_circle_outline, label: 'نشر'),
      if (_userRole == 'PRINCIPAL')
        MacDockItem(icon: Icons.admin_panel_settings, label: 'الإدارة'),
      if (_userRole != 'PRINCIPAL')
        const MacDockItem(icon: Icons.groups, label: 'مجتمعي'),
      const MacDockItem(icon: Icons.person, label: 'حسابي'),
    ];
  }

  // ✅ Force Logout - استخدمه للـ debug أو زر تسجيل الخروج
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('🧹 Cache cleared - logging out');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRoleLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = _getScreens();
    final dockItems = _getDockItems();

    // ✅ تأكد الـ index مش خارج النطاق لما يتغير عدد الشاشات
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: MacDock(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                  items: dockItems,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}