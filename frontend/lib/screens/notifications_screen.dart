import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final notifications = await _api.getNotifications();
    await _api.markAllAsRead();
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'LIKE': return Icons.favorite;
      case 'COMMENT': return Icons.comment;
      case 'FOLLOW': return Icons.person_add;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'LIKE': return Colors.red;
      case 'COMMENT': return Colors.blue;
      case 'FOLLOW': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} أيام';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعات';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقائق';
    return 'الآن';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا يوجد إشعارات بعد',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isUnread = !(n['isRead'] ?? false);
                      final type = n['type'] ?? '';
                      final actor = n['actor'] as Map<String, dynamic>?;

                      return Container(
                        color: isUnread
                            ? const Color(0xFF0A2342).withAlpha(13)
                            : null,
                        child: ListTile(
                          onTap: () {
                            if (actor != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(
                                    userId: actor['id'] ?? '',
                                  ),
                                ),
                              );
                            }
                          },
                          leading: CircleAvatar(
                            backgroundColor: _getColor(type).withAlpha(30),
                            child: Icon(
                              _getIcon(type),
                              color: _getColor(type),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            n['message'] ?? '',
                            style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            _getTimeAgo(n['createdAt']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: isUnread
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0A2342),
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}