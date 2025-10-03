import 'dart:io';
import 'dart:ui';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/screens/hairstyles/hairstyle_detail_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class HairstyleCard extends StatelessWidget {
  final Hairstyle hairstyle;

  const HairstyleCard({super.key, required this.hairstyle});

  Future<void> _showImageSourceDialog(BuildContext context) async {
    if (hairstyle.overlayImageUrl.isEmpty) {
      NotificationHelper.showError(
        context,
        message: 'ขออภัย, ทรงนี้ยังไม่รองรับการลองเสมือนจริง',
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppTheme.primary,
                ),
                title: Text(
                  'ถ่ายภาพใหม่',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppTheme.primary,
                ),
                title: Text(
                  'เลือกจากอัลบั้ม',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      _startVirtualTryOn(context, source);
    }
  }

  Future<void> _startVirtualTryOn(
    BuildContext context,
    ImageSource source,
  ) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
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

  Widget _buildGlassmorphismButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    required Color iconColor,
    required String tooltip,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            iconSize: 22,
            padding: EdgeInsets.zero,
            icon: Icon(icon, color: iconColor),
            onPressed: onPressed,
            tooltip: tooltip,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isFavorited = authProvider.isFavorite(hairstyle.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HairstyleDetailScreen(hairstyle: hairstyle),
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.network(
                hairstyle.imageUrls.isNotEmpty
                    ? hairstyle.imageUrls.first
                    : 'https://via.placeholder.com/300',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.background,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 40,
                    color: AppTheme.lightText,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                hairstyle.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    const Shadow(blurRadius: 2.0, color: Colors.black54),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Positioned(
              top: 8,
              right: 8,
              child: _buildGlassmorphismButton(
                context: context,
                icon: isFavorited ? Icons.favorite : Icons.favorite_border,
                iconColor: isFavorited ? AppTheme.primary : Colors.white,
                onPressed: () => authProvider.toggleFavorite(hairstyle.id),
                tooltip: 'Add to Favorites',
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: _buildGlassmorphismButton(
                context: context,
                icon: Icons.face_retouching_natural_outlined,
                iconColor: Colors.white,
                onPressed: () => _showImageSourceDialog(context),
                tooltip: 'Try this style!',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
