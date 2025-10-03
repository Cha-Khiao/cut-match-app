import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/models/user_model.dart';

class NotificationModel {
  final String id;
  final User sender;
  final String type;
  final Post? post;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.sender,
    required this.type,
    this.post,
    required this.isRead,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    User? sender,
    String? type,
    Post? post,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      post: post ?? this.post,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    Post? postObject;
    if (json['post'] != null && json['post'] is Map<String, dynamic>) {
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
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': sender.toJson(),
      'type': type,
      'post': post?.toJson(),
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}