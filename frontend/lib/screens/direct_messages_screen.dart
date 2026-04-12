import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'chat_detail_screen.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _currentUserId = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getConversations(),
        _api.getDmRequests(),
        _api.getUserProfile(),
      ]);
      setState(() {
        _conversations = results[0] as List<Map<String, dynamic>>;
        _requests = results[1] as List<Map<String, dynamic>>;
        _currentUserId =
            ((results[2] as Map<String, dynamic>)['id'] ?? '') as String;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _respondRequest(String conversationId, String action) async {
    final ok = await _api.respondDmRequest(conversationId, action);
    if (ok) _loadData();
  }

  String _otherUserName(Map<String, dynamic> conv) {
    final sender = conv['sender'] as Map<String, dynamic>? ?? {};
    final receiver = conv['receiver'] as Map<String, dynamic>? ?? {};
    if (sender['id'] == _currentUserId) {
      return receiver['fullName'] ?? 'مستخدم';
    }
    return sender['fullName'] ?? 'مستخدم';
  }

  String _otherUserId(Map<String, dynamic> conv) {
    final sender = conv['sender'] as Map<String, dynamic>? ?? {};
    final receiver = conv['receiver'] as Map<String, dynamic>? ?? {};
    if (sender['id'] == _currentUserId) {
      return receiver['id'] ?? '';
    }
    return sender['id'] ?? '';
  }

  String _lastMessage(Map<String, dynamic> conv) {
    final messages = conv['messages'] as List<dynamic>? ?? [];
    if (messages.isEmpty) return 'لا توجد رسائل بعد';
    return messages.first['content'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'الرسائل',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          dividerColor: AppTheme.dividerColor,
          tabs: [
            const Tab(text: 'المحادثات'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('الطلبات'),
                  if (_requests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_requests.length}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 100), // Avoid MacDock overlap
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildConversationsList(),
                  _buildRequestsList(),
                ],
              ),
      ),
    );
  }

  Widget _buildConversationsList() {
    if (_conversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'لا توجد محادثات بعد',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'ابدأ محادثة من بروفايل أي مستخدم',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final conv = _conversations[index];
          final name = _otherUserName(conv);
          final lastMsg = _lastMessage(conv);

          return Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF0A2342).withAlpha(30),
                child: Text(
                  name.isNotEmpty ? name[0] : '؟',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2342),
                    fontSize: 18,
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: Color(0xFF0A2342)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      conversationId: conv['id'],
                      otherUserName: name,
                      currentUserId: _currentUserId,
                    ),
                  ),
                ).then((_) => _loadData());
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_chat_unread_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'لا توجد طلبات محادثة',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final req = _requests[index];
          final sender =
              req['sender'] as Map<String, dynamic>? ?? {};
          final name = sender['fullName'] ?? 'مستخدم';

          return Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF0A2342).withAlpha(30),
                    child: Text(
                      name.isNotEmpty ? name[0] : '؟',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A2342),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        _respondRequest(req['id'], 'REJECTED'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('رفض'),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () =>
                        _respondRequest(req['id'], 'ACCEPTED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2342),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('قبول'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
