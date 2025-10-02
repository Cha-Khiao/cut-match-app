import 'dart:io';
import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:cut_match_app/screens/social/posts/edit_post_screen.dart';
import 'package:cut_match_app/screens/hairstyles/hairstyle_detail_screen.dart';
import 'package:cut_match_app/screens/social/posts/post_detail_screen.dart';
import 'package:cut_match_app/screens/profiles/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  Future<void> _sharePost(BuildContext context) async {
    final text = '${post.text}\n\nShared from Cut Match app!';
    try {
      if (post.imageUrls.isNotEmpty) {
        final response = await http.get(Uri.parse(post.imageUrls.first));
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/post_image.png';
        await File(path).writeAsBytes(bytes);
        await Share.shareXFiles([XFile(path)], text: text);
      } else {
        await Share.share(text);
      }
    } catch (e) {
      print('Error sharing post: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not share post.')));
      }
    }
  }

  void _showPostOptions(BuildContext context, FeedProvider feedProvider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Post'),
            onTap: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPostScreen(post: post),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Delete Post',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.of(ctx).pop();
              feedProvider.deletePost(post.id);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    final isOwner = currentUserId == post.author.id;
    final isLiked = post.likes.contains(currentUserId);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: post.author.id),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundImage: post.author.profileImageUrl.isNotEmpty
                  ? NetworkImage(post.author.profileImageUrl)
                  : null,
            ),
            title: Text(
              post.author.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              post.createdAt.toLocal().toString().substring(0, 16),
            ),
            trailing: isOwner
                ? IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () => _showPostOptions(context, feedProvider),
                  )
                : null,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: post),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(post.text),
                  ),
                if (post.imageUrls.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: post.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              post.imageUrls[index],
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                        if (post.imageUrls.length > 1)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.6),
                              radius: 16,
                              child: const Icon(
                                Icons.collections,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (post.linkedHairstyle != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: ListTile(
                        leading: Image.network(
                          post.linkedHairstyle!.imageUrls.first,
                          width: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(post.linkedHairstyle!.name),
                        subtitle: const Text('Linked Hairstyle'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HairstyleDetailScreen(
                                hairstyle: post.linkedHairstyle!,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: isLiked ? Colors.blueAccent : Colors.grey,
                      ),
                      onPressed: () {
                        // --- ✨ แก้ไขส่วนนี้ ✨ ---
                        if (authProvider.token != null &&
                            currentUserId != null) {
                          feedProvider.toggleLike(
                            post.id,
                            authProvider.token!,
                            currentUserId,
                          );
                        }
                      },
                    ),
                    Text('${post.likes.length}'),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(
                    Icons.comment_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  label: Text(
                    '${post.commentCount}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(post: post),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _sharePost(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}