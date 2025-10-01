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

  // ฟังก์ชันสำหรับรับ token จาก AuthProvider
  void updateToken(String? token) {
    _token = token;
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
    // --- 1. หาโพสต์ที่ถูกกด ---
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final isLiked = post.likes.contains(currentUserId);

    // --- 2. อัปเดต UI ทันที (Optimistic Update) ---
    if (isLiked) {
      _posts[postIndex].likes.remove(currentUserId);
    } else {
      _posts[postIndex].likes.add(currentUserId);
    }
    notifyListeners();

    // --- 3. เรียก API เบื้องหลัง ---
    try {
      await ApiService.likePost(postId, token);
    } catch (e) {
      // --- 4. ถ้า API ผิดพลาด ให้ย้อนกลับการเปลี่ยนแปลง ---
      print("Failed to like post: $e");
      if (isLiked) {
        _posts[postIndex].likes.add(currentUserId);
      } else {
        _posts[postIndex].likes.remove(currentUserId);
      }
      notifyListeners();
    }
  }

  // ...
  Future<bool> createPost({String? text, List<File>? imageFiles}) async {
    // <-- ✨ แก้ไข
    if (_token == null) {
      _errorMessage = "You must be logged in to post.";
      return false;
    }
    try {
      final newPost = await ApiService.createPost(
        token: _token!,
        text: text,
        imageFiles: imageFiles,
      ); // <-- ✨ แก้ไข
      _posts.insert(0, newPost);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
  // ...

  // --- ✨ แก้ไข 2 ฟังก์ชันนี้ ✨ ---
  void incrementCommentCount(String postId) {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final oldPost = _posts[postIndex];
      // สร้างโพสต์ใหม่ด้วยค่า commentCount + 1
      final newPost = oldPost.copyWith(commentCount: oldPost.commentCount + 1);
      _posts[postIndex] = newPost; // แทนที่โพสต์เก่าด้วยโพสต์ใหม่
      notifyListeners();
    }
  }

  void decrementCommentCount(String postId) {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final oldPost = _posts[postIndex];
      // สร้างโพสต์ใหม่ด้วยค่า commentCount - 1
      final newPost = oldPost.copyWith(commentCount: oldPost.commentCount - 1);
      _posts[postIndex] = newPost; // แทนที่โพสต์เก่าด้วยโพสต์ใหม่
      notifyListeners();
    }
  }

  // --- ✨ เพิ่ม 2 ฟังก์ชันนี้เข้ามา ✨ ---
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
    try {
      await ApiService.deletePost(postId, _token!);
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      print(_errorMessage);
    }
  }

  // --- ✨ เพิ่มฟังก์ชันนี้เข้ามา ✨ ---
  // ฟังก์ชันสำหรับอัปเดตข้อมูล author ในทุกโพสต์ที่เกี่ยวข้อง
  void updateUserInfoInPosts(User updatedUser) {
    _posts = _posts.map((post) {
      if (post.author.id == updatedUser.id) {
        // ถ้าเป็นโพสต์ของ user คนนี้ ให้สร้างโพสต์ใหม่ที่ author เป็นข้อมูลล่าสุด
        return post.copyWith(author: updatedUser);
      }
      return post;
    }).toList();
    notifyListeners();
  }
}