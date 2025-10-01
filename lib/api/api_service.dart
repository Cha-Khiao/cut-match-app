import 'dart:convert';
import 'dart:io';
import 'package:cut_match_app/models/comment_model.dart';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/models/notification_model.dart';
import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/models/review_model.dart';
import 'package:cut_match_app/models/salon_model.dart';
import 'package:cut_match_app/models/user_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://cut-match-api.vercel.app/api';

  //============================================
  // Auth Functions (No Token Required)
  //============================================

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return body;
    } else {
      if (body['errors'] != null) {
        throw Exception(body['errors'][0]['msg']);
      }
      throw Exception(body['message'] ?? 'Failed to register');
    }
  }

  // --- Login User ---
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    // --- ✨ เพิ่มโค้ด 3 บรรทัดนี้เข้ามาเพื่อ Debug ✨ ---
    print('--- RAW JSON RESPONSE FROM LOGIN ---');
    print(response.body);
    print('------------------------------------');
    // ------------------------------------------

    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return body; // Success
    } else {
      throw Exception(body['message'] ?? 'Failed to login');
    }
  }

  //============================================
  // Public Functions (No Token Required)
  //============================================

  static Future<List<Hairstyle>> getHairstyles({
    String? gender,
    String? search,
    String? tags,
  }) async {
    try {
      // สร้าง URI object
      var uri = Uri.parse('$_baseUrl/hairstyles');

      // สร้าง Map สำหรับเก็บ query parameters
      final Map<String, String> queryParams = {};
      if (gender != null && gender.isNotEmpty) {
        queryParams['gender'] = gender;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags;
      }
      // เพิ่ม query parameters เข้าไปใน URI ถ้ามี
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((dynamic item) => Hairstyle.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load hairstyles');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  //============================================
  // Protected User Functions (Token Required)
  //============================================

  static Future<List<Hairstyle>> getFavorites(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Hairstyle.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load favorites');
    }
  }

  static Future<void> addFavorite(String hairstyleId, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/favorites'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'hairstyleId': hairstyleId}),
    );
    if (response.statusCode != 200) {
      print('Add Favorite Error: ${response.body}');
      throw Exception('Failed to add favorite');
    }
  }

  static Future<void> removeFavorite(String hairstyleId, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/users/favorites/$hairstyleId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      print('Remove Favorite Error: ${response.body}');
      throw Exception('Failed to remove favorite');
    }
  }

  //============================================
  // Admin Functions (Token Required)
  //============================================

  static Future<Hairstyle> createHairstyle(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/hairstyles'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return Hairstyle.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      print('Create Hairstyle Error: ${response.body}');
      throw Exception('Failed to create hairstyle');
    }
  }

  static Future<Hairstyle> updateHairstyle(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/hairstyles/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return Hairstyle.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      print('Update Hairstyle Error: ${response.body}');
      throw Exception('Failed to update hairstyle');
    }
  }

  static Future<void> deleteHairstyle(String id, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/hairstyles/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      print('Delete Hairstyle Error: ${response.body}');
      throw Exception('Failed to delete hairstyle');
    }
  }

  // --- Review Functions ---
  static Future<List<Review>> getReviewsForHairstyle(String hairstyleId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/hairstyles/$hairstyleId/reviews'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Review.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  static Future<void> submitReview({
    required String token,
    required String hairstyleId,
    required double rating,
    required String comment,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/hairstyles/$hairstyleId/reviews'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to submit review');
    }
  }

  // --- Update User Profile (with image) ---
  static Future<Map<String, dynamic>> updateUserProfile({
    required String token,
    String? username,
    String? email,
    String? password,
    String? salonName,
    String? salonMapUrl,
    File? imageFile,
  }) async {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('$_baseUrl/users/profile'),
    );

    // Add headers
    request.headers['Authorization'] = 'Bearer $token';

    // Add text fields
    if (username != null) request.fields['username'] = username;
    if (email != null) request.fields['email'] = email;
    if (password != null) request.fields['password'] = password;
    // สามารถเพิ่ม password ได้ถ้าต้องการ

    // Add image file
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profileImage', // ชื่อ field นี้ต้องตรงกับใน uploadMiddleware ของ API
          imageFile.path,
        ),
      );
    }

    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return body;
    } else {
      throw Exception(body['message'] ?? 'Failed to update profile');
    }
  }

  static Future<List<String>> getSavedLooks(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/saved-looks'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return List<String>.from(body);
    } else {
      throw Exception('Failed to load saved looks');
    }
  }

  static Future<void> addSavedLook(String token, File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/users/saved-looks'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('savedLookImage', imageFile.path),
    );

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode != 201) {
      throw Exception('Failed to upload saved look');
    }
  }

  static Future<void> deleteSavedLook(String token, String imageUrl) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/users/saved-looks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'imageUrl': imageUrl}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete saved look');
    }
  }

  // --- Post System ---
  static Future<List<Post>> getFeed(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/posts/feed'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Post.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load feed');
    }
  }

  static Future<List<Post>> getUserPosts(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/posts/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Post.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load user posts');
    }
  }

  static Future<Map<String, dynamic>> getUserPublicProfile(
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/public/$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  static Future<void> followUser(String userId, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/$userId/follow'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Failed to follow user');
  }

  static Future<void> unfollowUser(String userId, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/users/$userId/follow'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Failed to unfollow user');
  }

  // --- ✨ เพิ่มฟังก์ชันนี้ ✨ ---
  static Future<Post> likePost(String postId, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/posts/$postId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Post.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to like post');
    }
  }

  // ...
  static Future<Post> createPost({
    required String token,
    String? text,
    List<File>? imageFiles, // <-- ✨ แก้ไข
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/posts'));
    request.headers['Authorization'] = 'Bearer $token';

    if (text != null) request.fields['text'] = text;

    // --- ✨ วนลูปเพื่อเพิ่มไฟล์ทั้งหมด ✨ ---
    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (var imageFile in imageFiles) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'postImages',
            imageFile.path,
          ), // ชื่อ field ต้องตรงกับ API
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return Post.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to create post: ${response.body}');
    }
  }

  // --- ✨ Comment System Functions ✨ ---
  static Future<List<Comment>> getComments(String postId, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/posts/$postId/comments'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Comment.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load comments');
    }
  }

  static Future<Comment> createComment(
    String postId,
    String text,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/posts/$postId/comments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode == 201) {
      return Comment.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to create comment');
    }
  }

  // --- ✨ เพิ่ม 3 ฟังก์ชันนี้เข้ามา ✨ ---
  static Future<Comment> replyToComment(
    String parentCommentId,
    String text,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/comments/$parentCommentId/reply'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode == 201) {
      return Comment.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to reply to comment');
    }
  }

  static Future<Comment> updateComment(
    String commentId,
    String text,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/comments/$commentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode == 200) {
      return Comment.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to update comment');
    }
  }

  static Future<void> deleteComment(String commentId, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/comments/$commentId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete comment');
    }
  }

  // --- ✨ เพิ่ม 2 ฟังก์ชันนี้เข้ามา ✨ ---
  static Future<Post> updatePost({
    required String token,
    required String postId,
    required String text,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/posts/$postId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode == 200) {
      return Post.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to update post');
    }
  }

  static Future<void> deletePost(String postId, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/posts/$postId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete post');
    }
  }

  // --- ✨ เพิ่มฟังก์ชันนี้เข้ามา ✨ ---
  static Future<List<User>> searchUsers(String query, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/search?q=$query'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => User.fromJson(item)).toList();
    } else {
      throw Exception('Failed to search users');
    }
  }

  // --- Salon Finder Functions ---
  static Future<List<Salon>> findNearbySalons(
    double lat,
    double lng, {
    String? search,
  }) async {
    var uri = Uri.parse('$_baseUrl/salons/nearby?lat=$lat&lng=$lng');
    if (search != null && search.isNotEmpty) {
      uri = uri.replace(
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'search': search,
        },
      );
    }
    final response = await http.get(
      Uri.parse('$_baseUrl/salons/nearby?lat=$lat&lng=$lng'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Salon.fromJson(item)).toList();
    } else {
      throw Exception('Failed to find nearby salons');
    }
  }

  static Future<List<Salon>> getSalons(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/salons'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Salon.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load salons');
    }
  }

  static Future<Salon> createSalon(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/salons'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return Salon.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to create salon');
    }
  }

  static Future<Salon> updateSalon(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/salons/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return Salon.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to update salon');
    }
  }

  static Future<void> deleteSalon(String id, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/salons/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete salon');
    }
  }

  // --- ✨ Notification Functions ✨ ---
  static Future<List<NotificationModel>> getNotifications(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body
          .map((dynamic item) => NotificationModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  static Future<void> markAllAsRead(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/notifications/mark-read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark notifications as read');
    }
  }

  // --- ✨ เพิ่มฟังก์ชันนี้ ✨ ---
  static Future<void> deleteNotification(
    String notificationId,
    String token,
  ) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/notifications/$notificationId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete notification');
    }
  }
}
