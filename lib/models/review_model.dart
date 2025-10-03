import 'package:cut_match_app/models/user_model.dart';

class Review {
  final String id;
  final int rating;
  final String comment;
  final User user;
  final String createdAt;

  Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.user,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      user: User.fromJson(json['user']),
      createdAt: json['createdAt'] ?? '',
    );
  }
}