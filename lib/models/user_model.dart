class User {
  final String id;
  final String username;
  final String email;
  final String role;
  final String profileImageUrl;
  final List<String> following;
  final String salonName;
  final String salonMapUrl;
  final int? postCount;
  final int? followerCount;
  final int? followingCount;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.profileImageUrl,
    required this.following,
    required this.salonName,
    required this.salonMapUrl,
    this.postCount,
    this.followerCount,
    this.followingCount,
  });

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? profileImageUrl,
    List<String>? following,
    String? salonName,
    String? salonMapUrl,
    int? postCount,
    int? followerCount,
    int? followingCount,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      following: following ?? this.following,
      salonName: salonName ?? this.salonName,
      salonMapUrl: salonMapUrl ?? this.salonMapUrl,
      postCount: postCount ?? this.postCount,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    String parseStringFromArray(dynamic value) {
      if (value is String) {
        return value;
      }
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
      return '';
    }

    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      profileImageUrl: json['profileImageUrl'] ?? '',
      following: json['following'] != null
          ? List<String>.from(json['following'].map((item) => item.toString()))
          : [],

      salonName: parseStringFromArray(json['salonName']),
      salonMapUrl: parseStringFromArray(json['salonMapUrl']),
      postCount: json['postCount'],
      followerCount: json['followerCount'],
      followingCount: json['followingCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'following': following,
      'salonName': salonName,
      'salonMapUrl': salonMapUrl,
      'postCount': postCount,
      'followerCount': followerCount,
      'followingCount': followingCount,
    };
  }
}
