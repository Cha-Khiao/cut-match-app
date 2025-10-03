import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/comment_model.dart';
import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:flutter/material.dart';

class PostDetailProvider with ChangeNotifier {
  final Post post;
  final String token;
  final FeedProvider feedProvider;

  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PostDetailProvider({
    required this.post,
    required this.token,
    required this.feedProvider,
  }) {
    fetchComments();
  }

  Future<void> fetchComments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _comments = await ApiService.getComments(post.id, token);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createComment(String text) async {
    await ApiService.createComment(post.id, text, token);
    feedProvider.incrementCommentCount(post.id);
    await fetchComments();
  }

  Future<void> replyToComment(String parentCommentId, String text) async {
    await ApiService.replyToComment(parentCommentId, text, token);
    await fetchComments();
  }

  Future<void> updateComment(String commentId, String text) async {
    await ApiService.updateComment(commentId, text, token);
    await fetchComments();
  }

  Future<void> deleteComment(String commentId) async {
    await ApiService.deleteComment(commentId, token);
    feedProvider.decrementCommentCount(post.id);
    await fetchComments();
  }
}