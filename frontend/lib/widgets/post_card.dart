import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../screens/user_profile_screen.dart';
import 'video_player_widget.dart';
import 'three_d_transformer.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback? onDeleted;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.onDeleted,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final ApiService _api = ApiService();
  bool _showComments = false;
  bool _loadingLike = false;
  bool _loadingComment = false;
  final TextEditingController _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _commentsLoaded = false;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.post.commentsList);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_loadingLike) return;
    setState(() => _loadingLike = true);
    final result = await _api.toggleLike(widget.post.id);
    setState(() {
      widget.post.isLiked = result['isLiked'] ?? widget.post.isLiked;
      widget.post.likes = result['likesCount'] ?? widget.post.likes;
      _loadingLike = false;
    });
  }

  Future<void> _loadComments() async {
    if (_commentsLoaded) return;
    final comments = await _api.getComments(widget.post.id);
    setState(() {
      _comments = comments;
      _commentsLoaded = true;
    });
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _loadingComment) return;
    setState(() => _loadingComment = true);
    final comment = await _api.addComment(widget.post.id, content);
    if (comment != null) {
      setState(() {
        _comments.add(comment);
        widget.post.comments = _comments.length;
        _commentController.clear();
      });
    }
    setState(() => _loadingComment = false);
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التعليق'),
        content: const Text('هل أنت متأكد من حذف هذا التعليق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await _api.deleteComment(widget.post.id, commentId);
    if (success) {
      setState(() {
        _comments.removeWhere((c) => c.id == commentId);
        widget.post.comments = _comments.length;
      });
    }
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المنشور'),
        content: const Text('هل أنت متأكد من حذف هذا المنشور؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await _api.deletePost(widget.post.id);
    if (success && widget.onDeleted != null) {
      widget.onDeleted!();
    }
  }

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
      if (_showComments) _loadComments();
    });
  }

  void _openUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
    );
  }

  // ==================== Avatar Widget ====================
  Widget _buildAvatar({
    required String name,
    String? avatarUrl,
    required Color backgroundColor,
    double radius = 20,
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
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.post.authorRole == 'TEACHER';
    final isMyPost = widget.post.authorId == widget.currentUserId;

    return ThreeDTransformer(
      child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس المنشور
          ListTile(
            leading: GestureDetector(
              onTap: () => _openUserProfile(widget.post.authorId),
              child: _buildAvatar(
                name: widget.post.authorName,
                avatarUrl: widget.post.authorAvatar,
                backgroundColor: isTeacher ? Colors.teal : const Color(0xFF0A2342),
              ),
            ),
            title: GestureDetector(
              onTap: () => _openUserProfile(widget.post.authorId),
              child: Text(
                widget.post.authorName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: Text(
              '${isTeacher ? 'معلم' : 'طالب'} • ${widget.post.school}\n${widget.post.timeAgo}',
              style: const TextStyle(fontSize: 12),
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getTypeColor(widget.post.type).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeLabel(widget.post.type),
                    style: TextStyle(
                      fontSize: 11,
                      color: _getTypeColor(widget.post.type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isMyPost)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: _deletePost,
                  ),
              ],
            ),
          ),

          // المحتوى النصي
          if (widget.post.content.isNotEmpty && widget.post.content != '.')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(widget.post.content, style: const TextStyle(fontSize: 15)),
            ),

          // الصورة
          if (widget.post.mediaUrl != null && widget.post.type == 'IMAGE')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.post.mediaUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),

          // الفيديو
          if (widget.post.mediaUrl != null && widget.post.type == 'VIDEO')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: VideoPlayerWidget(videoUrl: widget.post.mediaUrl!),
              ),
            ),

          // أزرار اللايك والكومنت
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _loadingLike ? null : _toggleLike,
                  icon: _loadingLike
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: widget.post.isLiked ? Colors.red : null,
                        ),
                  label: Text(
                    '${widget.post.likes}',
                    style: TextStyle(color: widget.post.isLiked ? Colors.red : null),
                  ),
                ),
                TextButton.icon(
                  onPressed: _toggleComments,
                  icon: Icon(
                    _showComments ? Icons.comment : Icons.comment_outlined,
                    size: 20,
                    color: _showComments ? const Color(0xFF0A2342) : null,
                  ),
                  label: Text(
                    '${widget.post.comments}',
                    style: TextStyle(color: _showComments ? const Color(0xFF0A2342) : null),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: const Text('مشاركة'),
                ),
              ],
            ),
          ),

          // قسم الكومنتات
          if (_showComments) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'اكتب تعليقاً...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      textDirection: TextDirection.rtl,
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _loadingComment
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: _addComment,
                          icon: const Icon(Icons.send),
                          color: const Color(0xFF0A2342),
                        ),
                ],
              ),
            ),
            if (_comments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'لا يوجد تعليقات بعد',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  final isMyComment = comment.authorId == widget.currentUserId;
                  return _CommentTile(
                    comment: comment,
                    isMyComment: isMyComment,
                    onDelete: () => _deleteComment(comment.id),
                    onTapUser: () => _openUserProfile(comment.authorId),
                  );
                },
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    ),
  );
}

  Color _getTypeColor(String type) {
    switch (type) {
      case 'IMAGE': return Colors.green;
      case 'VIDEO': return Colors.red;
      case 'STORY': return Colors.purple;
      default: return const Color(0xFF0A2342);
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'IMAGE': return 'صورة';
      case 'VIDEO': return 'فيديو';
      case 'STORY': return 'قصة';
      default: return 'نص';
    }
  }
}

// ==================== COMMENT TILE ====================
class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final bool isMyComment;
  final VoidCallback onDelete;
  final VoidCallback onTapUser;

  const _CommentTile({
    required this.comment,
    required this.isMyComment,
    required this.onDelete,
    required this.onTapUser,
  });

  @override
  Widget build(BuildContext context) {
    final isTeacher = comment.authorRole == 'TEACHER';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTapUser,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: isTeacher ? Colors.teal : const Color(0xFF0A2342),
              backgroundImage: comment.authorAvatar != null
                  ? NetworkImage(comment.authorAvatar!)
                  : null,
              child: comment.authorAvatar == null
                  ? Text(
                      comment.authorName.isNotEmpty ? comment.authorName[0] : '؟',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onTapUser,
                        child: Text(
                          comment.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isTeacher ? 'معلم' : 'طالب',
                        style: TextStyle(
                          fontSize: 11,
                          color: isTeacher ? Colors.teal : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      if (isMyComment)
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(comment.content, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    comment.timeAgo,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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