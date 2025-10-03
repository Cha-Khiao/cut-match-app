class Hairstyle {
  final String id;
  final String name;
  final String description;
  final List<String> imageUrls;
  final String overlayImageUrl;
  final String gender;
  final List<String> tags;
  final List<String> suitableFaceShapes;
  final int numReviews;
  final double averageRating;

  Hairstyle({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrls,
    required this.overlayImageUrl,
    required this.gender,
    required this.tags,
    required this.suitableFaceShapes,
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
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      suitableFaceShapes: json['suitableFaceShapes'] != null
          ? List<String>.from(json['suitableFaceShapes'])
          : [],
      numReviews: json['numReviews'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'imageUrls': imageUrls,
      'overlayImageUrl': overlayImageUrl,
      'gender': gender,
      'tags': tags,
      'suitableFaceShapes': suitableFaceShapes,
      'numReviews': numReviews,
      'averageRating': averageRating,
    };
  }

  Hairstyle copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? imageUrls,
    String? overlayImageUrl,
    String? gender,
    List<String>? tags,
    List<String>? suitableFaceShapes,
    int? numReviews,
    double? averageRating,
  }) {
    return Hairstyle(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      overlayImageUrl: overlayImageUrl ?? this.overlayImageUrl,
      gender: gender ?? this.gender,
      tags: tags ?? this.tags,
      suitableFaceShapes: suitableFaceShapes ?? this.suitableFaceShapes,
      numReviews: numReviews ?? this.numReviews,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}
