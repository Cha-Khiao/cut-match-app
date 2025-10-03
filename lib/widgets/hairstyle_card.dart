import 'dart:io';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/screens/hairstyles/hairstyle_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class HairstyleCard extends StatelessWidget {
  final Hairstyle hairstyle;

  const HairstyleCard({super.key, required this.hairstyle});

  // --- ✨ 1. สร้างฟังก์ชันสำหรับแสดงตัวเลือกแหล่งที่มาของรูปภาพ ✨ ---
  Future<void> _showImageSourceDialog(BuildContext context) async {
    // ตรวจสอบก่อนว่าทรงผมนี้มี overlay image หรือไม่
    if (hairstyle.overlayImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sorry, try-on is not available for this style yet.'),
        ),
      );
      return;
    }

    // แสดง BottomSheet ให้ผู้ใช้เลือก
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      _startVirtualTryOn(context, source);
    }
  }

  // --- ✨ 2. แก้ไขฟังก์ชันนี้ให้รับ ImageSource เข้ามา ✨ ---
  Future<void> _startVirtualTryOn(
    BuildContext context,
    ImageSource source,
  ) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source, // ใช้ source ที่ผู้ใช้เลือก
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
    );

    if (image != null && context.mounted) {
      Navigator.pushNamed(
        context,
        '/tryon',
        arguments: {
          'userImageFile': File(image.path),
          'hairstyleOverlayUrl': hairstyle.overlayImageUrl,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isFavorited = authProvider.isFavorite(hairstyle.id);

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- รูปภาพหลักและชื่อทรงผม ---
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HairstyleDetailScreen(hairstyle: hairstyle),
                    ),
                  );
                },
                child: GridTile(
                  footer: GridTileBar(
                    backgroundColor: Colors.black54,
                    title: Text(hairstyle.name, textAlign: TextAlign.center),
                  ),
                  child: Image.network(
                    hairstyle.imageUrls.isNotEmpty
                        ? hairstyle.imageUrls.first
                        : 'https://via.placeholder.com/300',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

              // --- ปุ่ม ถูกใจ (มุมขวาบน) ---
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  radius: 20,
                  child: IconButton(
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: isFavorited ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: () => authProvider.toggleFavorite(hairstyle.id),
                    tooltip: 'Add to Favorites',
                  ),
                ),
              ),

              // --- ปุ่ม ลองทรงผม (มุมซ้ายบน) ---
              Positioned(
                top: 8,
                left: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  radius: 20,
                  child: IconButton(
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    // --- ✨ 3. เปลี่ยนให้เรียกฟังก์ชันแสดงตัวเลือก ✨ ---
                    onPressed: () => _showImageSourceDialog(context),
                    tooltip: 'Try this style!',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
