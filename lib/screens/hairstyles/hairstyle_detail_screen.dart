import 'dart:io';
import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/models/review_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class HairstyleDetailScreen extends StatefulWidget {
  final Hairstyle hairstyle;
  const HairstyleDetailScreen({super.key, required this.hairstyle});

  @override
  State<HairstyleDetailScreen> createState() => _HairstyleDetailScreenState();
}

class _HairstyleDetailScreenState extends State<HairstyleDetailScreen> {
  int _currentImageIndex = 0;
  // ใช้ key เพื่อให้สามารถ refresh FutureBuilder ของรีวิวได้
  final GlobalKey<_ReviewSectionState> _reviewSectionKey = GlobalKey();

  // ฟังก์ชันสำหรับ Refresh ข้อมูลรีวิวหลังจากมีการ submit ใหม่
  void _refreshData() {
    _reviewSectionKey.currentState?.refreshReviews();
    // ในอนาคตอาจจะต้อง refresh ตัว hairstyle object ทั้งหมดเพื่ออัปเดต rating
  }

  // ฟังก์ชันสำหรับแสดง Dialog เพิ่มรีวิว
  void _showAddReviewDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to write a review.')),
      );
      return;
    }

    double ratingValue = 3;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Write a Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar.builder(
              initialRating: ratingValue,
              minRating: 1,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) => ratingValue = rating,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Your comment...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.submitReview(
                  token: authProvider.token!,
                  hairstyleId: widget.hairstyle.id,
                  rating: ratingValue,
                  comment: commentController.text,
                );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Review submitted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _refreshData();
              } catch (e) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสำหรับแสดงตัวเลือกแหล่งที่มาของรูปภาพ
  Future<void> _showImageSourceDialog() async {
    if (widget.hairstyle.overlayImageUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sorry, try-on is not available for this style yet.'),
          ),
        );
      }
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      _startVirtualTryOn(source);
    }
  }

  // ฟังก์ชันสำหรับเริ่ม Virtual Try-On
  Future<void> _startVirtualTryOn(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
    );

    if (image != null && mounted) {
      Navigator.pushNamed(
        context,
        '/tryon',
        arguments: {
          'userImageFile': File(image.path),
          'hairstyleOverlayUrl': widget.hairstyle.overlayImageUrl,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              if (widget.hairstyle.imageUrls.isNotEmpty) {
                Share.share(
                  'Check out this hairstyle: ${widget.hairstyle.name}\nFind more on Cut Match!\n${widget.hairstyle.imageUrls.first}',
                );
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.hairstyle.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: widget.hairstyle.averageRating,
                        itemBuilder: (context, index) =>
                            const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 20.0,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${widget.hairstyle.numReviews} Reviews)',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.hairstyle.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.hairstyle.tags.isNotEmpty)
                    _buildChipSection('Tags', widget.hairstyle.tags),
                  if (widget.hairstyle.suitableFaceShapes.isNotEmpty)
                    _buildChipSection(
                      'Suitable for',
                      widget.hairstyle.suitableFaceShapes,
                    ),
                  const Divider(height: 32),
                  ReviewSection(
                    key: _reviewSectionKey,
                    hairstyle: widget.hairstyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildImageGallery() {
    if (widget.hairstyle.imageUrls.isEmpty) {
      return Container(
        height: 400,
        color: Colors.grey.shade300,
        child: const Center(child: Icon(Icons.image_not_supported, size: 50)),
      );
    }
    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.hairstyle.imageUrls.length,
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              return Image.network(
                widget.hairstyle.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error),
              );
            },
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.hairstyle.imageUrls.length, (
                index,
              ) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentImageIndex == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: items
              .map(
                (item) => Chip(
                  label: Text(item),
                  backgroundColor: Colors.grey.shade200,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.face_retouching_natural),
              label: const Text('Try This Style!'),
              onPressed: _showImageSourceDialog, // เรียกฟังก์ชันแสดงตัวเลือก
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final isFavorited = authProvider.isFavorite(
                    widget.hairstyle.id,
                  );
                  return IconButton(
                    onPressed: () =>
                        authProvider.toggleFavorite(widget.hairstyle.id),
                    icon: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: isFavorited ? Colors.red : Colors.grey,
                      size: 30,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showAddReviewDialog(context),
                  child: const Text('Write a Review'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget แยกสำหรับจัดการและแสดงผลรีวิวโดยเฉพาะ
class ReviewSection extends StatefulWidget {
  final Hairstyle hairstyle;
  const ReviewSection({super.key, required this.hairstyle});

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  late Future<List<Review>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    refreshReviews();
  }

  void refreshReviews() {
    setState(() {
      _reviewsFuture = ApiService.getReviewsForHairstyle(widget.hairstyle.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Review>>(
          future: _reviewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No reviews yet. Be the first!'));
            }
            final reviews = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length > 3
                  ? 3
                  : reviews.length, // แสดงสูงสุด 3 รีวิว
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(review.user.username),
                    subtitle: Text(review.comment),
                    leading: RatingBarIndicator(
                      rating: review.rating.toDouble(),
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemSize: 16.0,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
