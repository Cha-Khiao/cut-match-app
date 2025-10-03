class Hairstyle {
  final String id;
  final String name;
  final String description;
  final List<String> imageUrls;
  final String overlayImageUrl;
  final String gender;
  final List<String> tags; // <-- เพิ่มเข้ามา
  final List<String> suitableFaceShapes; // <-- เพิ่มเข้ามา
  final int numReviews;
  final double averageRating;

  Hairstyle({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrls,
    required this.overlayImageUrl,
    required this.gender,
    required this.tags, // <-- เพิ่มเข้ามา
    required this.suitableFaceShapes, // <-- เพิ่มเข้ามา
    required this.numReviews,
    required this.averageRating,
  });

  factory Hairstyle.fromJson(Map<String, dynamic> json) {
    return Hairstyle(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'No Name',
      description: json['description'] ?? '',
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
      overlayImageUrl: json['overlayImageUrl'] ?? '',
      gender: json['gender'] ?? 'Unisex',
      // แปลงค่าและป้องกัน null
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      suitableFaceShapes: json['suitableFaceShapes'] != null
          ? List<String>.from(json['suitableFaceShapes'])
          : [],
      numReviews: json['numReviews'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
    );
  }
}
