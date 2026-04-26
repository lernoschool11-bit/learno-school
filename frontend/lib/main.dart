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
import 'screens/grades_screen.dart';
import 'screens/enter_grades_screen.dart';
import 'screens/class_grades_screen.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'theme/app_theme.dart';
import 'widgets/mac_dock.dart';
import 'widgets/mesh_background.dart';
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
      if (_userRole == 'TEACHER' || _userRole == 'STUDENT') CreatePostScreen(userRole: _userRole),
      if (_userRole == 'PRINCIPAL') AdminPanel(),
      if (_userRole != 'PRINCIPAL') const CommunityScreen(),
      const AIChatScreen(),
      if (_userRole == 'STUDENT') GradesScreen(),
      if (_userRole == 'TEACHER') EnterGradesScreen(),
      if (_userRole == 'PRINCIPAL' || _userRole == 'TEACHER') ClassGradesScreen(),
      const ProfileScreen(),
    ];
  }

  List<MacDockItem> _getDockItems() {
    return [
      const MacDockItem(icon: Icons.home, label: 'الرئيسية'),
      const MacDockItem(icon: Icons.search, label: 'البحث'),
      if (_userRole == 'TEACHER' || _userRole == 'STUDENT')
        const MacDockItem(icon: Icons.add_circle_outline, label: 'نشر'),
      if (_userRole == 'PRINCIPAL')
        MacDockItem(icon: Icons.admin_panel_settings, label: 'الإدارة'),
      if (_userRole != 'PRINCIPAL')
        const MacDockItem(icon: Icons.groups, label: 'مجتمعي'),
      // AI moved to separate FAB
      if (_userRole == 'STUDENT') const MacDockItem(icon: Icons.grade, label: 'علاماتي'),
      if (_userRole == 'TEACHER') const MacDockItem(icon: Icons.edit_note, label: 'رصد'),
      if (_userRole == 'PRINCIPAL' || _userRole == 'TEACHER') const MacDockItem(icon: Icons.assessment, label: 'السجل'),
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

    return MeshBackground(
      child: Scaffold(
        backgroundColor: AppTheme.oledBlack.withAlpha(200),
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 80), // Reserve space for floating Dock
                child: IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
              ),
              // AI Floating Circle (Glassmorphism)
              Positioned(
                right: 20,
                bottom: 110, // Positioned well above the Dock
                child: GestureDetector(
                  onTap: () {
                    final aiIndex = screens.indexWhere((s) => s is AIChatScreen);
                    if (aiIndex != -1) {
                      setState(() => _currentIndex = aiIndex);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surfaceDark.withAlpha(180),
                          border: Border.all(
                            color: AppTheme.primaryColor.withAlpha(100),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withAlpha(40),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_awesome, 
                          color: (_currentIndex == screens.indexWhere((s) => s is AIChatScreen)) 
                              ? AppTheme.primaryColor 
                              : Colors.white70, 
                          size: 30
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: MacDock(
                    currentIndex: dockItems.indexWhere((item) {
                      final currentScreen = screens[_currentIndex];
                      if (currentScreen is HomeScreen && item.label == 'الرئيسية') return true;
                      if (currentScreen is SearchScreen && item.label == 'البحث') return true;
                      if (currentScreen is CreatePostScreen && item.label == 'نشر') return true;
                      if (currentScreen is AdminPanel && item.label == 'الإدارة') return true;
                      if (currentScreen is CommunityScreen && item.label == 'مجتمعي') return true;
                      if (currentScreen is GradesScreen && item.label == 'علاماتي') return true;
                      if (currentScreen is EnterGradesScreen && item.label == 'رصد') return true;
                      if (currentScreen is ClassGradesScreen && item.label == 'السجل') return true;
                      if (currentScreen is ProfileScreen && item.label == 'حسابي') return true;
                      return false;
                    }),
                    onTap: (dockIndex) {
                      final label = dockItems[dockIndex].label;
                      int targetIndex = -1;
                      
                      if (label == 'الرئيسية') targetIndex = screens.indexWhere((s) => s is HomeScreen);
                      else if (label == 'البحث') targetIndex = screens.indexWhere((s) => s is SearchScreen);
                      else if (label == 'نشر') targetIndex = screens.indexWhere((s) => s is CreatePostScreen);
                      else if (label == 'الإدارة') targetIndex = screens.indexWhere((s) => s is AdminPanel);
                      else if (label == 'مجتمعي') targetIndex = screens.indexWhere((s) => s is CommunityScreen);
                      else if (label == 'علاماتي') targetIndex = screens.indexWhere((s) => s is GradesScreen);
                      else if (label == 'رصد') targetIndex = screens.indexWhere((s) => s is EnterGradesScreen);
                      else if (label == 'السجل') targetIndex = screens.indexWhere((s) => s is ClassGradesScreen);
                      else if (label == 'حسابي') targetIndex = screens.indexWhere((s) => s is ProfileScreen);

                      if (targetIndex != -1) {
                        setState(() => _currentIndex = targetIndex);
                      }
                    },
                    items: dockItems,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}