import 'dart:convert';
import 'dart:io';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../api/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  List<String> _favoriteIds = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _savedLooks = [];

  // --- Getters ---
  String? get token => _token;
  User? get user => _user;
  List<String> get favoriteIds => _favoriteIds;
  List<String> get savedLooks => _savedLooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;
  bool get isAdmin => _user?.role == 'admin';

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
    }
  }

  // --- Private Helpers ---
  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> _handleSuccessfulAuth(Map<String, dynamic> response) async {
    _token = response['token'];
    _user = User.fromJson(response);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_token', _token!);
    await prefs.setString('user_data', jsonEncode(response));

    await Future.wait([fetchFavorites(), fetchSavedLooks()]);
  }

  // SECTION: Authentication
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    clearError();
    try {
      final response = await ApiService.login(email, password);
      await _handleSuccessfulAuth(response);
      _setLoading(false);
      return true;
    } catch (e) {
      _setErrorMessage(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    clearError();
    try {
      final response = await ApiService.register(username, email, password);
      await _handleSuccessfulAuth(response);
      _setLoading(false);
      return true;
    } catch (e) {
      _setErrorMessage(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('user_token') || !prefs.containsKey('user_data')) {
      return;
    }
    _token = prefs.getString('user_token');
    final userDataString = prefs.getString('user_data');
    if (userDataString == null) return;

    final userData = jsonDecode(userDataString);
    _user = User.fromJson(userData);

    await Future.wait([fetchFavorites(), fetchSavedLooks()]);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _favoriteIds = [];
    _savedLooks = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('user_token');
    notifyListeners();
  }

  // SECTION: User Data & Actions
  Future<void> fetchFavorites() async {
    if (_token == null) return;
    try {
      final favoriteHairstyles = await ApiService.getFavorites(_token!);
      _favoriteIds = favoriteHairstyles.map((h) => h.id).toList();
      notifyListeners();
    } catch (e) {
      print("Could not fetch favorites: $e");
    }
  }

  bool isFavorite(String hairstyleId) => _favoriteIds.contains(hairstyleId);

  Future<void> toggleFavorite(String hairstyleId) async {
    if (_token == null) return;

    final originalFavorites = List<String>.from(_favoriteIds);
    final isCurrentlyFavorite = isFavorite(hairstyleId);

    if (isCurrentlyFavorite) {
      _favoriteIds.remove(hairstyleId);
    } else {
      _favoriteIds.add(hairstyleId);
    }
    notifyListeners();

    try {
      if (isCurrentlyFavorite) {
        await ApiService.removeFavorite(hairstyleId, _token!);
      } else {
        await ApiService.addFavorite(hairstyleId, _token!);
      }
    } catch (e) {
      _favoriteIds = originalFavorites;
      notifyListeners();
    }
  }

  Future<void> fetchSavedLooks() async {
    if (_token == null) return;
    try {
      _savedLooks = await ApiService.getSavedLooks(_token!);
      notifyListeners();
    } catch (e) {
      print("Could not fetch saved looks: $e");
    }
  }

  Future<void> addLook(File imageFile) async {
    if (_token == null) return;
    try {
      await ApiService.addSavedLook(_token!, imageFile);
      await fetchSavedLooks();
    } catch (e) {
      _setErrorMessage("Failed to upload look.");
    }
  }

  Future<void> deleteLook(String imageUrl) async {
    if (_token == null) return;
    final originalLooks = List<String>.from(_savedLooks);
    _savedLooks.remove(imageUrl);
    notifyListeners();

    try {
      await ApiService.deleteSavedLook(_token!, imageUrl);
    } catch (e) {
      _savedLooks = originalLooks;
      notifyListeners();
    }
  }

  bool isFollowing(String userId) => _user?.following.contains(userId) ?? false;

  Future<void> toggleFollow(String userIdToToggle) async {
    if (_token == null || _user == null) return;

    final originalFollowing = List<String>.from(_user!.following);
    final isCurrentlyFollowing = isFollowing(userIdToToggle);

    if (isCurrentlyFollowing) {
      _user!.following.remove(userIdToToggle);
    } else {
      _user!.following.add(userIdToToggle);
    }
    notifyListeners();

    try {
      if (isCurrentlyFollowing) {
        await ApiService.unfollowUser(userIdToToggle, _token!);
      } else {
        await ApiService.followUser(userIdToToggle, _token!);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));
    } catch (e) {
      _user = _user!.copyWith(following: originalFollowing);
      notifyListeners();
    }
  }

  // SECTION: Account Management
  Future<bool> updateProfile({
    String? username,
    String? password,
    String? salonName,
    String? salonMapUrl,
    File? imageFile,
    FeedProvider? feedProvider,
  }) async {
    if (_token == null) return false;
    _setLoading(true);
    clearError();
    try {
      final response = await ApiService.updateUserProfile(
        token: _token!,
        username: username,
        password: password,
        salonName: salonName,
        salonMapUrl: salonMapUrl,
        imageFile: imageFile,
      );

      _user = User.fromJson(response);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(response));

      feedProvider?.updateUserInfoInPosts(_user!);

      _setLoading(false);
      return true;
    } catch (e) {
      _setErrorMessage(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    if (_token == null) return false;
    _setLoading(true);
    clearError();
    try {
      await ApiService.deleteUserAccount(_token!);
      await logout();
      _setLoading(false);
      return true;
    } catch (e) {
      _setErrorMessage(e.toString());
      _setLoading(false);
      return false;
    }
  }
}
