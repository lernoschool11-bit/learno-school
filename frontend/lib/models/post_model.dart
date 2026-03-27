class PostModel {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String school;
  final String type;
  final String timeAgo;
  int likes;
  int comments;
  final String? mediaUrl;
  final String? authorAvatar;
  bool isLiked;
  final List<CommentModel> commentsList;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.school,
    required this.type,
    required this.timeAgo,
    required this.likes,
    required this.comments,
    this.mediaUrl,
    this.authorAvatar,
    this.isLiked = false,
    this.commentsList = const [],
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final commentsList = (json['comments'] as List<dynamic>? ?? [])
        .map((c) => CommentModel.fromJson(c))
        .toList();
    return PostModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorId: json['author']?['id'] ?? '',
      authorName: json['author']?['fullName'] ?? 'مستخدم غير معروف',
      authorRole: json['author']?['role'] ?? 'STUDENT',
      school: json['author']?['school'] ?? 'غير محدد',
      type: json['type'] ?? 'TEXT',
      timeAgo: _calculateTimeAgo(json['createdAt']),
      likes: json['likesCount'] ?? 0,
      comments: json['commentsCount'] ?? (json['comments'] as List?)?.length ?? 0,
      mediaUrl: json['mediaUrl'],
      authorAvatar: json['author']?['avatarUrl'],
      isLiked: json['isLiked'] ?? false,
      commentsList: commentsList,
    );
  }

  static String _calculateTimeAgo(String? dateStr) {
    if (dateStr == null) return 'غير معروف';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'غير معروف';
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) return 'منذ ${difference.inDays} أيام';
    if (difference.inHours > 0) return 'منذ ${difference.inHours} ساعات';
    if (difference.inMinutes > 0) return 'منذ ${difference.inMinutes} دقائق';
    return 'الآن';
  }
}

class CommentModel {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String? authorAvatar;
  final String timeAgo;

  CommentModel({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    this.authorAvatar,
    required this.timeAgo,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      authorId: json['author']?['id'] ?? '',
      authorName: json['author']?['fullName'] ?? 'مستخدم غير معروف',
      authorRole: json['author']?['role'] ?? 'STUDENT',
      authorAvatar: json['author']?['avatarUrl'],
      timeAgo: PostModel._calculateTimeAgo(json['createdAt']),
    );
  }
}
