import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/models/user_model.dart';

class Post {
  final String id;
  final User author;
  final String text;
  final List<String> imageUrls;
  final Hairstyle? linkedHairstyle;
  final List<String> likes;
  final int commentCount;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.author,
    required this.text,
    required this.imageUrls,
    this.linkedHairstyle,
    required this.likes,
    required this.commentCount,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'],
      author: User.fromJson(json['author']),
      text: json['text'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      linkedHairstyle: json['linkedHairstyle'] != null
          ? Hairstyle.fromJson(json['linkedHairstyle'])
          : null,
      likes: List<String>.from(json['likes'] ?? []),
      commentCount: json['commentCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Post copyWith({
    String? id,
    User? author,
    String? text,
    List<String>? imageUrls,
    Hairstyle? linkedHairstyle,
    List<String>? likes,
    int? commentCount,
    DateTime? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      text: text ?? this.text,
      imageUrls: imageUrls ?? this.imageUrls,
      linkedHairstyle: linkedHairstyle ?? this.linkedHairstyle,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'author': author.toJson(),
      'text': text,
      'imageUrls': imageUrls,
      'linkedHairstyle': linkedHairstyle?.toJson(),
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}