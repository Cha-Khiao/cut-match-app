import 'dart:io';
import 'dart:ui';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/models/review_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/providers/hairstyle_detail_provider.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HairstyleDetailScreen extends StatelessWidget {
  final Hairstyle hairstyle;
  const HairstyleDetailScreen({super.key, required this.hairstyle});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HairstyleDetailProvider(hairstyle),
      child: _HairstyleDetailView(hairstyle: hairstyle),
    );
  }
}

class _HairstyleDetailView extends StatefulWidget {
  final Hairstyle hairstyle;
  const _HairstyleDetailView({required this.hairstyle});

  @override
  State<_HairstyleDetailView> createState() => __HairstyleDetailViewState();
}

class __HairstyleDetailViewState extends State<_HairstyleDetailView> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final detailProvider = context.watch<HairstyleDetailProvider>();
    final isFavorited = authProvider.isFavorite(widget.hairstyle.id);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            backgroundColor: theme.appBarTheme.backgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildGlassmorphismButton(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildGlassmorphismButton(
                  icon: Icons.share_outlined,
                  onPressed: () {
                    if (widget.hairstyle.imageUrls.isNotEmpty) {
                      Share.share(
                        'ดูทรงผมนี้สิ: ${widget.hairstyle.name}\n${widget.hairstyle.imageUrls.first}\n\nจากแอป Cut Match!',
                      );
                    }
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _buildImageGallery(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.hairstyle.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRatingIndicator(detailProvider.hairstyle),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                  if (widget.hairstyle.tags.isNotEmpty)
                    _buildChipSection('แท็ก', widget.hairstyle.tags),
                  if (widget.hairstyle.suitableFaceShapes.isNotEmpty)
                    _buildChipSection(
                      'เหมาะสำหรับ',
                      widget.hairstyle.suitableFaceShapes,
                    ),
                  const Divider(height: 40),
                  _buildReviewSection(detailProvider, authProvider),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionButtons(isFavorited, authProvider),
    );
  }

  Widget _buildGlassmorphismButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            iconSize: 20,
            padding: EdgeInsets.zero,
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    if (widget.hairstyle.imageUrls.isEmpty) {
      return Container(
        color: AppTheme.background,
        child: const Icon(
          Icons.image_not_supported,
          size: 60,
          color: AppTheme.lightText,
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.hairstyle.imageUrls.length,
          itemBuilder: (context, index) => Image.network(
            widget.hairstyle.imageUrls[index],
            fit: BoxFit.cover,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: widget.hairstyle.imageUrls.length,
              effect: const WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: AppTheme.primary,
                dotColor: Colors.white70,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingIndicator(Hairstyle hairstyle) {
    final theme = Theme.of(context);
    return Row(
      children: [
        RatingBarIndicator(
          rating: hairstyle.averageRating,
          itemBuilder: (context, index) =>
              const Icon(Icons.star, color: AppTheme.accent),
          itemCount: 5,
          itemSize: 20.0,
        ),
        const SizedBox(width: 8),
        Text(
          '(${hairstyle.numReviews} รีวิว)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightText,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('รายละเอียด', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          widget.hairstyle.description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.lightText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChipSection(String title, List<String> items) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: items.map((item) => Chip(label: Text(item))).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReviewSection(
    HairstyleDetailProvider provider,
    AuthProvider authProvider,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'รีวิว (${provider.reviews.length})',
              style: theme.textTheme.titleLarge,
            ),
            if (authProvider.isAuthenticated)
              TextButton(
                onPressed: () => _showAddReviewDialog(context, provider),
                child: const Text('เขียนรีวิว'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator()),
        if (provider.errorMessage != null)
          Center(child: Text(provider.errorMessage!)),
        if (!provider.isLoading && provider.reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('ยังไม่มีรีวิวสำหรับทรงผมนี้'),
            ),
          ),
        if (!provider.isLoading && provider.reviews.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.reviews.length,
            itemBuilder: (context, index) =>
                _ReviewItem(review: provider.reviews[index]),
          ),
      ],
    );
  }

  Widget _buildActionButtons(bool isFavorited, AuthProvider authProvider) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: () => authProvider.toggleFavorite(widget.hairstyle.id),
            style: OutlinedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
              side: BorderSide(
                color: isFavorited ? AppTheme.primary : AppTheme.lightText,
              ),
            ),
            child: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? AppTheme.primary : AppTheme.lightText,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.face_retouching_natural_outlined),
              label: const Text('ลองทรงผมนี้!'),
              onPressed: _showImageSourceDialog,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReviewDialog(
    BuildContext context,
    HairstyleDetailProvider provider,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      NotificationHelper.showError(
        context,
        message: 'กรุณาเข้าสู่ระบบเพื่อเขียนรีวิว',
      );
      return;
    }

    double ratingValue = 3;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เขียนรีวิว'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: ratingValue,
                minRating: 1,
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: AppTheme.accent),
                onRatingUpdate: (rating) => ratingValue = rating,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'เขียนความคิดเห็นของคุณ...',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.submitReview(
                  token: authProvider.token!,
                  rating: ratingValue,
                  comment: commentController.text,
                );
                Navigator.of(ctx).pop();
                NotificationHelper.showSuccess(
                  context,
                  message: 'ส่งรีวิวเรียบร้อยแล้ว!',
                );
              } catch (e) {
                Navigator.of(ctx).pop();
                NotificationHelper.showError(context, message: e.toString());
              }
            },
            child: const Text('ส่ง'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    if (widget.hairstyle.overlayImageUrl.isEmpty) {
      if (mounted) {
        NotificationHelper.showError(
          context,
          message: 'ไม่รองรับการลองทรงผมสำหรับสไตล์นี้',
        );
      }
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายภาพใหม่'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากอัลบั้ม'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) _startVirtualTryOn(source);
  }

  Future<void> _startVirtualTryOn(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
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
}

class _ReviewItem extends StatelessWidget {
  final Review review;
  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.background,
          backgroundImage: review.user.profileImageUrl.isNotEmpty
              ? NetworkImage(review.user.profileImageUrl)
              : null,
          child: review.user.profileImageUrl.isEmpty
              ? const Icon(Icons.person, color: AppTheme.lightText)
              : null,
        ),
        title: Text(
          review.user.username,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(review.comment, style: theme.textTheme.bodyMedium),
        ),
        trailing: RatingBarIndicator(
          rating: review.rating.toDouble(),
          itemBuilder: (context, _) =>
              const Icon(Icons.star, color: AppTheme.accent),
          itemSize: 16,
        ),
      ),
    );
  }
}
