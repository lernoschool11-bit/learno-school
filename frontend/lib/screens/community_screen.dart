import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'user_profile_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  Map<String, dynamic>? _communityData;
  String? _error;
  List<Map<String, dynamic>> _messages = [];
  String? _roomId;
  bool _showMembers = false;
  String? _currentUsername;
  String? _currentUserId;

  final List<String> _quickEmojis = ['😊', '👍', '❤️', '😂', '🎉', '📚', '✅', '❓', '👏', '🔥'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadCommunity();
    await _connectSocket();
    await _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final profile = await _apiService.getUserProfile();
      setState(() {
        _currentUsername = profile['username'];
        _currentUserId = profile['id'];
      });
    } catch (_) {}
  }

  Future<void> _loadCommunity() async {
    try {
      setState(() { _isLoading = true; _error = null; });
      final data = await _apiService.getCommunity();
      setState(() {
        _communityData = data;
        _roomId = '${data['school']}_${data['grade']}_${data['section']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = 'فشل تحميل المجتمع'; _isLoading = false; });
    }
  }

  Future<void> _connectSocket() async {
    await _socketService.connect();
    if (_roomId != null) {
      _socketService.joinRoom(_roomId!);
    }
    _socketService.onRoomHistory((history) {
      setState(() {
        _messages = history.map((m) => Map<String, dynamic>.from(m)).toList();
      });
      _scrollToBottom();
    });
    _socketService.onMessage((message) {
      setState(() => _messages.add(message));
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty || _roomId == null) return;
    _socketService.sendMessage(roomId: _roomId!, content: content.trim());
    _messageController.clear();
  }

  void _openUserProfile(String? userId) {
    if (userId == null || userId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
    );
  }

  Widget _buildAvatar({
    required String name,
    String? avatarUrl,
    required Color backgroundColor,
    double radius = 20,
    double fontSize = 14,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0] : '؟',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!)));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2342),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مجتمعي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_communityData != null)
              Text(
                'الصف ${_communityData!['grade']} - شعبة ${_communityData!['section']}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showMembers ? Icons.chat : Icons.people),
            onPressed: () => setState(() => _showMembers = !_showMembers),
            tooltip: _showMembers ? 'المحادثة' : 'الأعضاء',
          ),
        ],
      ),
      body: _showMembers ? _buildMembersList() : _buildChat(),
    );
  }

  Widget _buildMembersList() {
    final students = _communityData?['students'] as List<dynamic>? ?? [];
    final teachers = _communityData?['teachers'] as List<dynamic>? ?? [];
    final allMembers = [
      ...teachers.map((t) => {...Map<String, dynamic>.from(t), 'isTeacher': true}),
      ...students.map((s) => {...Map<String, dynamic>.from(s), 'isTeacher': false}),
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF0A2342).withAlpha(15),
          child: Row(
            children: [
              const Icon(Icons.people, color: Color(0xFF0A2342), size: 20),
              const SizedBox(width: 8),
              Text(
                '${allMembers.length} عضو',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A2342)),
              ),
              const SizedBox(width: 16),
              Text(
                '${teachers.length} معلم · ${students.length} طالب',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: allMembers.length,
            itemBuilder: (context, index) {
              final member = allMembers[index];
              final isTeacher = member['isTeacher'] == true;
              final avatarUrl = member['avatarUrl'] as String?;
              return ListTile(
                onTap: () => _openUserProfile(member['id']),
                leading: _buildAvatar(
                  name: member['fullName'] ?? '؟',
                  avatarUrl: avatarUrl,
                  backgroundColor: isTeacher ? Colors.teal : const Color(0xFF0A2342),
                ),
                title: Text(
                  member['fullName'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('@${member['username'] ?? ''}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTeacher
                        ? Colors.teal.withAlpha(30)
                        : const Color(0xFF0A2342).withAlpha(20),
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'لا توجد رسائل بعد\nابدأ المحادثة! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                ),
        ),

        // إيموجي سريعة
        Container(
          height: 44,
          color: Colors.grey.shade50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: _quickEmojis.length,
            itemBuilder: (context, index) => InkWell(
              onTap: () => _sendMessage(_quickEmojis[index]),
              child: Container(
                width: 36,
                margin: const EdgeInsets.only(right: 4),
                alignment: Alignment.center,
                child: Text(_quickEmojis[index], style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
        ),

        // حقل الإرسال
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(50),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: _sendMessage,
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF0A2342),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['username'] == _currentUsername;
    final userId = message['userId'] as String?;
    final avatarUrl = message['avatarUrl'] as String?;
    final fullName = message['fullName'] as String? ?? '؟';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () => _openUserProfile(userId),
              child: _buildAvatar(
                name: fullName,
                avatarUrl: avatarUrl,
                backgroundColor: const Color(0xFF0A2342),
                radius: 14,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF0A2342) : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    GestureDetector(
                      onTap: () => _openUserProfile(userId),
                      child: Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  Text(
                    message['content'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message['time'] ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white60 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}