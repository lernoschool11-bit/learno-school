import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/community_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'theme/app_theme.dart';
import 'widgets/mac_dock.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase initialization removed for emergency build bypass
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learno',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Enabled for demo: Start at LoginScreen to show dual-view login
  bool _isLoading = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.oledBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }
    return _isLoggedIn ? const MainNavigation() : const LoginScreen();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    SocketService().connect();
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const AIChatScreen(),
    const CreatePostScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 100), // Reserve space for MacDock
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: MacDock(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                items: const [
                  MacDockItem(icon: Icons.home, label: 'الرئيسية'),
                  MacDockItem(icon: Icons.search, label: 'البحث'),
                  MacDockItem(icon: Icons.auto_awesome, label: 'الذكاء الصناعي'),
                  MacDockItem(icon: Icons.add_circle_outline, label: 'نشر'),
                  MacDockItem(icon: Icons.groups, label: 'مجتمعي'),
                  MacDockItem(icon: Icons.person, label: 'حسابي'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}