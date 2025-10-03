import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/models/user_model.dart';
import 'package:flutter/material.dart';

class ProfileProvider with ChangeNotifier {
  final String userId;
  final String? token;

  User? _user;
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  User? get user => _user;
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProfileProvider({required this.userId, required this.token}) {
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.getUserPublicProfile(userId),
        if (token != null) ApiService.getUserPosts(userId, token!),
      ]);

      _user = User.fromJson(results[0] as Map<String, dynamic>);
      if (results.length > 1) {
        _posts = results[1] as List<Post>;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
