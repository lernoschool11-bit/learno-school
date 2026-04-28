class OnlineClassModel {
  final String id;
  final String title;
  final String meetingUrl;
  final DateTime startTime;
  final bool isActive;
  final String teacherId;
  final String teacherName;
  final String? teacherAvatar;
  final String? grade;
  final String? section;
  final String? subject;

  OnlineClassModel({
    required this.id,
    required this.title,
    required this.meetingUrl,
    required this.startTime,
    required this.isActive,
    required this.teacherId,
    required this.teacherName,
    this.teacherAvatar,
    this.grade,
    this.section,
    this.subject,
  });

  factory OnlineClassModel.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacher'] ?? {};
    return OnlineClassModel(
      id: json['id'],
      title: json['title'],
      meetingUrl: json['meetingUrl'],
      startTime: DateTime.parse(json['startTime']),
      isActive: json['isActive'],
      teacherId: json['teacherId'],
      teacherName: teacher['fullName'] ?? 'Unknown',
      teacherAvatar: teacher['avatarUrl'],
      grade: json['grade'],
      section: json['section'],
      subject: json['subject'],
    );
  }
}
