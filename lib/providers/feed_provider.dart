import 'dart:io';
import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/models/user_model.dart';
import 'package:flutter/material.dart';

class FeedProvider with ChangeNotifier {
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _token;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateToken(String? token) {
    _token = token;
  }

  Post? findPostById(String postId) {
    try {
      return _posts.firstWhere((post) => post.id == postId);
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchFeed(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      _posts = await ApiService.getFeed(token);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleLike(
    String postId,
    String token,
    String currentUserId,
  ) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final isLiked = post.likes.contains(currentUserId);

    if (isLiked) {
      _posts[postIndex].likes.remove(currentUserId);
    } else {
      _posts[postIndex].likes.add(currentUserId);
    }
    notifyListeners();

    try {
      await ApiService.likePost(postId, token);
    } catch (e) {
      if (isLiked) {
        _posts[postIndex].likes.add(currentUserId);
      } else {
        _posts[postIndex].likes.remove(currentUserId);
      }
      notifyListeners();
    }
  }

  Future<bool> createPost({String? text, List<File>? imageFiles}) async {
    if (_token == null) {
      _errorMessage = "You must be logged in to post.";
      return false;
    }
    try {
      final newPost = await ApiService.createPost(
        token: _token!,
        text: text,
        imageFiles: imageFiles,
      );
      _posts.insert(0, newPost);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  void _updateCommentCount(String postId, int value) {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final oldPost = _posts[postIndex];
      final newCount = oldPost.commentCount + value;
      if (newCount >= 0) {
        final newPost = oldPost.copyWith(commentCount: newCount);
        _posts[postIndex] = newPost;
        notifyListeners();
      }
    }
  }

  void incrementCommentCount(String postId) {
    _updateCommentCount(postId, 1);
  }

  void decrementCommentCount(String postId) {
    _updateCommentCount(postId, -1);
  }

  Future<bool> updatePost(String postId, String text) async {
    if (_token == null) return false;
    try {
      final updatedPost = await ApiService.updatePost(
        token: _token!,
        postId: postId,
        text: text,
      );
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex] = updatedPost;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<void> deletePost(String postId) async {
    if (_token == null) return;
    final originalPosts = List<Post>.from(_posts);
    _posts.removeWhere((p) => p.id == postId);
    notifyListeners();

    try {
      await ApiService.deletePost(postId, _token!);
    } catch (e) {
      _errorMessage = e.toString();
      _posts = originalPosts;
      notifyListeners();
    }
  }

  void updateUserInfoInPosts(User updatedUser) {
    _posts = _posts.map((post) {
      if (post.author.id == updatedUser.id) {
        return post.copyWith(author: updatedUser);
      }
      return post;
    }).toList();
    notifyListeners();
  }
}