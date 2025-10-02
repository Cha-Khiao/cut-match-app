class User {
  final String id;
  final String username;
  final String email;
  final String role;
  final String profileImageUrl;
  final List<String> following;
  final String salonName;
  final String salonMapUrl;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.profileImageUrl,
    required this.following,
    required this.salonName,
    required this.salonMapUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      profileImageUrl: json['profileImageUrl'] ?? '',
      following: json['following'] != null
          ? List<String>.from(json['following'].map((item) => item.toString()))
          : [],
      // --- ✨ แก้ไข 2 บรรทัดนี้ ✨ ---
      // ตรวจสอบก่อนว่าข้อมูลเป็น String หรือไม่ ถ้าไม่ใช่ให้ใช้ค่าว่าง '' แทน
      salonName: json['salonName'] is String ? json['salonName'] : '',
      salonMapUrl: json['salonMapUrl'] is String ? json['salonMapUrl'] : '',
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
    };
  }
}
