import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../theme/app_theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String currentUserId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.currentUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ApiService _api = ApiService();
  final SocketService _socket = SocketService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenSocket();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs = await _api.getDirectMessages(widget.conversationId);
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _listenSocket() {
    _socket.onDirectMessage((data) {
      if (!mounted) return;
      if (data['conversationId'] == widget.conversationId) {
        setState(() => _messages.add(data));
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _msgController.clear();

    // إرسال عبر Socket
    _socket.sendDirectMessage(
      conversationId: widget.conversationId,
      content: text,
    );

    // أضف الرسالة محلياً فوراً
    setState(() {
      _messages.add({
        'id': DateTime.now().toIso8601String(),
        'content': text,
        'senderId': widget.currentUserId,
        'sender': {'id': widget.currentUserId},
        'createdAt': DateTime.now().toIso8601String(),
      });
      _isSending = false;
    });
    _scrollToBottom();
  }

  bool _isMe(Map<String, dynamic> msg) {
    final sender = msg['sender'] as Map<String, dynamic>? ?? {};
    final senderId = sender['id'] ?? msg['senderId'] ?? '';
    return senderId == widget.currentUserId;
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.surfaceDark,
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0]
                    : '؟',
                style: const TextStyle(
                    color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.otherUserName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // الرسائل
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan))
                  : _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'ابدأ المحادثة الآن! 👋',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = _isMe(msg);
                            return _buildMessage(msg, isMe);
                          },
                        ),
            ),
          ),

          // حقل الكتابة
          Container(
            color: AppTheme.surfaceDark,
            padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 108), // Avoid MacDock overlap
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      textDirection: TextDirection.rtl,
                      maxLines: null,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        hintTextDirection: TextDirection.rtl,
                        filled: true,
                        fillColor: AppTheme.oledBlack,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppTheme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppTheme.dividerColor),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppTheme.neonCyan,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppTheme.oledBlack),
                            )
                          : const Icon(Icons.send, color: AppTheme.oledBlack, size: 20),
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

  Widget _buildMessage(Map<String, dynamic> msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe 
                    ? Border.all(color: AppTheme.neonCyan.withAlpha(100), width: 1)
                    : Border.all(color: AppTheme.dividerColor, width: 1),
                boxShadow: isMe ? AppTheme.neonCyanGlow : [],
              ),
              child: Text(
                msg['content'] ?? '',
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg['createdAt'] as String?),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
