import 'package:cut_match_app/models/user_model.dart';

class Comment {
  final String id;
  final User author;
  final String text;
  final DateTime createdAt;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    var replyList = <Comment>[];
    if (json['replies'] != null) {
      // แปลงข้อมูล replies ที่ซ้อนกันอยู่ให้เป็น Comment object ด้วย
      replyList = (json['replies'] as List)
          .map((r) => Comment.fromJson(r))
          .toList();
    }
    return Comment(
      id: json['_id'],
      author: User.fromJson(json['author']),
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
      replies: replyList, // <-- ✨ เพิ่มเข้ามา
    );
  }
}