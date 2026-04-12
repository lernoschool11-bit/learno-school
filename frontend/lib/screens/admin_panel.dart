import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _principalProfile;
  late TabController _tabController;
  
  // Default filtering for Wadi Al-Seer district
  final String _targetDistrict = 'مديرية التربية والتعليم للواء وادي السير';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPrincipalData();
    _fetchCurrentCode();
  }

  Future<void> _loadPrincipalData() async {
    try {
      final profile = await _apiService.getUserProfile();
      setState(() {
        _principalProfile = profile;
      });
    } catch (e) {
      debugPrint('Error loading principal profile: $e');
    }
  }

  Future<void> _fetchCurrentCode() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot doc = await _firestore
          .collection('system_control')
          .doc('security_config')
          .get();
      
      if (doc.exists) {
        setState(() {
          _codeController.text = doc.get('teacher_access_code') ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error fetching code: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCode() async {
    if (_codeController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _firestore
          .collection('system_control')
          .doc('security_config')
          .set({
        'teacher_access_code': _codeController.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher Access Code Updated Successfully!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Confirm Deletion', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to remove this user?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('users').doc(userId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the principal's school
    final principalSchool = _principalProfile?['school'] ?? 'Loading...';

    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      appBar: AppBar(
        title: const Text('PRINCIPAL DASHBOARD'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: () => _loadPrincipalData(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Stack(
        children: [
          _buildBackgroundGlow(),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildWelcomeHeader(principalSchool),
                const SizedBox(height: 32),
                _buildSummaryCards(principalSchool),
                const SizedBox(height: 48),
                _buildAccessCodeSection(),
                const SizedBox(height: 48),
                _buildUserManagementSection(principalSchool),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryColor.withOpacity(0.05),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String school) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, Principal',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          school,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
        Text(
          _targetDistrict,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(String school) {
    return Row(
      children: [
        Expanded(child: _buildCountCard('Teachers', 'TEACHER', school, Icons.person_pin)),
        const SizedBox(width: 16),
        Expanded(child: _buildCountCard('Students', 'STUDENT', school, Icons.school)),
      ],
    );
  }

  Widget _buildCountCard(String title, String role, String school, IconData icon) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users')
          .where('role', '==', role)
          .where('school_name', '==', school)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccessCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manage Teacher Access Code',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: AppTheme.glassDecoration(opacity: 0.1),
              child: TextField(
                controller: _codeController,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Dynamic Teacher Verification Code',
                  labelStyle: TextStyle(color: AppTheme.primaryColor),
                  prefixIcon: Icon(Icons.vpn_key_outlined, color: AppTheme.primaryColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateCode,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('UPDATE ACCESS CODE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildUserManagementSection(String school) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Management',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                tabs: const [Tab(text: 'Teachers'), Tab(text: 'Students')],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserList('TEACHER', school),
                    _buildUserList('STUDENT', school),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserList(String role, String school) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users')
          .where('role', '==', role)
          .where('school_name', '==', school)
          .where('district', '==', _targetDistrict)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No users found', style: TextStyle(color: Colors.grey)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05)),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(data['fullName'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(data['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                onPressed: () => _deleteUser(id),
              ),
            );
          },
        );
      },
    );
  }
}
