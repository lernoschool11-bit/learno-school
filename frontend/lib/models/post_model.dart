class PostModel {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final String authorName;
  final String authorRole;
  final String school;
  final String type;
  final String timeAgo;
  final String? authorAvatar;
  int likes;
  int comments;
  bool isLiked;
  final String? mediaUrl;
  final List<CommentModel> commentsList;

  PostModel({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.authorName,
    required this.authorRole,
    required this.school,
    required this.type,
    required this.timeAgo,
    required this.likes,
    required this.comments,
    this.isLiked = false,
    this.mediaUrl,
    this.authorAvatar,
    this.commentsList = const [],
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final commentsList = (json['comments'] as List<dynamic>? ?? [])
        .map((c) => CommentModel.fromJson(c))
        .toList();

    return PostModel(
      id: json['id'] ?? '',
      authorId: json['author']?['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorName: json['author']?['fullName'] ?? 'مستخدم غير معروف',
      authorRole: json['author']?['role'] ?? 'STUDENT',
      school: json['author']?['school'] ?? 'غير محدد',
      type: json['type'] ?? 'TEXT',
      timeAgo: _calculateTimeAgo(json['createdAt']),
      likes: json['likesCount'] ?? 0,
      comments: json['commentsCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      mediaUrl: json['mediaUrl'],
      authorAvatar: json['author']?['avatarUrl'],
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
  final String authorId;
  final String content;
  final String authorName;
  final String authorRole;
  final String? authorAvatar;
  final String timeAgo;

  CommentModel({
    required this.id,
    required this.authorId,
    required this.content,
    required this.authorName,
    required this.authorRole,
    this.authorAvatar,
    required this.timeAgo,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      authorId: json['author']?['id'] ?? '',
      content: json['content'] ?? '',
      authorName: json['author']?['fullName'] ?? 'مستخدم غير معروف',
      authorRole: json['author']?['role'] ?? 'STUDENT',
      authorAvatar: json['author']?['avatarUrl'],
      timeAgo: PostModel._calculateTimeAgo(json['createdAt']),
    );
  }
}