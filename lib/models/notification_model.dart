import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/models/user_model.dart';

class NotificationModel {
  final String id;
  final User sender;
  final String type;
  final Post? post;
  bool isRead; // <-- ✨ แก้ไขบรรทัดนี้ (เอา final ออก)
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.sender,
    required this.type,
    this.post,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // สร้าง Post object เฉพาะเมื่อมีข้อมูล post จริงๆ
    Post? postObject;
    if (json['post'] != null && json['post'] is Map<String, dynamic>) {
      // ตรวจสอบว่า author ใน post ไม่ใช่แค่ ID
      if (json['post']['author'] != null &&
          json['post']['author'] is Map<String, dynamic>) {
        postObject = Post.fromJson(json['post']);
      }
    }

    return NotificationModel(
      id: json['_id'],
      sender: User.fromJson(json['sender']),
      type: json['type'],
      post: postObject,
      isRead: json['isRead'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}