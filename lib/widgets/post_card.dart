import 'dart:io';
import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:cut_match_app/screens/social/posts/edit_post_screen.dart';
import 'package:cut_match_app/screens/hairstyles/hairstyle_detail_screen.dart';
import 'package:cut_match_app/screens/social/posts/post_detail_screen.dart';
import 'package:cut_match_app/screens/profiles/profile_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _sharePost(BuildContext context) async {
    final text = '${widget.post.text}\n\nShared from Cut Match app!';
    try {
      if (widget.post.imageUrls.isNotEmpty) {
        final response = await http.get(Uri.parse(widget.post.imageUrls.first));
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/post_image.png';
        await File(path).writeAsBytes(bytes);
        await Share.shareXFiles([XFile(path)], text: text);
      } else {
        await Share.share(text);
      }
    } catch (e) {
      if (context.mounted) {
        NotificationHelper.showError(context, message: 'ไม่สามารถแชร์โพสต์ได้');
      }
    }
  }

  void _showPostOptions(BuildContext context, FeedProvider feedProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppTheme.darkText,
              ),
              title: Text(
                'แก้ไขโพสต์',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPostScreen(post: widget.post),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'ลบโพสต์',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () async {
                Navigator.of(ctx).pop();
                await feedProvider.deletePost(widget.post.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final feedProvider = context.watch<FeedProvider>();

    final updatedPost =
        feedProvider.findPostById(widget.post.id) ?? widget.post;

    final currentUserId = authProvider.user?.id;
    final isOwner = currentUserId == updatedPost.author.id;
    final isLiked = updatedPost.likes.contains(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(userId: updatedPost.author.id),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: AppTheme.background,
              backgroundImage: updatedPost.author.profileImageUrl.isNotEmpty
                  ? NetworkImage(updatedPost.author.profileImageUrl)
                  : null,
              child: updatedPost.author.profileImageUrl.isEmpty
                  ? const Icon(Icons.person, color: AppTheme.lightText)
                  : null,
            ),
            title: Text(
              updatedPost.author.username,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat(
                'd MMM yyyy, HH:mm',
              ).format(updatedPost.createdAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: isOwner
                ? IconButton(
                    icon: const Icon(
                      Icons.more_horiz,
                      color: AppTheme.lightText,
                    ),
                    onPressed: () => _showPostOptions(context, feedProvider),
                  )
                : null,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: updatedPost),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (updatedPost.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      updatedPost.text,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),

                if (updatedPost.imageUrls.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: updatedPost.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              updatedPost.imageUrls[index],
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                        if (updatedPost.imageUrls.length > 1)
                          Positioned(
                            bottom: 10,
                            child: SmoothPageIndicator(
                              controller: _pageController,
                              count: updatedPost.imageUrls.length,
                              effect: const WormEffect(
                                dotHeight: 8,
                                dotWidth: 8,
                                activeDotColor: AppTheme.primary,
                                dotColor: Colors.white70,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                if (updatedPost.linkedHairstyle != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HairstyleDetailScreen(
                              hairstyle: updatedPost.linkedHairstyle!,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                updatedPost.linkedHairstyle!.imageUrls.first,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ทรงผมที่แนบมา',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.lightText),
                                  ),
                                  Text(
                                    updatedPost.linkedHairstyle!.name,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppTheme.lightText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: '${updatedPost.likes.length}',
                  onPressed: () {
                    if (authProvider.token != null && currentUserId != null) {
                      feedProvider.toggleLike(
                        updatedPost.id,
                        authProvider.token!,
                        currentUserId,
                      );
                    }
                  },
                  color: isLiked ? AppTheme.primary : AppTheme.lightText,
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: '${updatedPost.commentCount}',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PostDetailScreen(post: updatedPost),
                      ),
                    );
                  },
                  color: AppTheme.lightText,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.share_outlined,
                    color: AppTheme.lightText,
                  ),
                  onPressed: () => _sharePost(context),
                  tooltip: 'Share Post',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}