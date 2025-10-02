import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:cut_match_app/providers/notification_provider.dart';
import 'package:cut_match_app/screens/social/notifications/notification_screen.dart';
import 'package:cut_match_app/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFeed();
    });
  }

  Future<void> _refreshFeed() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      await Provider.of<FeedProvider>(context, listen: false).fetchFeed(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- ✨ แก้ไข AppBar ✨ ---
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, child) {
              return Badge(
                label: Text('${notifProvider.unreadCount}'),
                isLabelVisible: notifProvider.unreadCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/create_post').then((result) {
                if (result == true) {
                  _refreshFeed();
                }
              });
            },
            tooltip: 'Create Post',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/user_search'),
            tooltip: 'Search Users',
          ),
        ],
      ),
      body: Consumer<FeedProvider>(
        builder: (context, feedProvider, child) {
          if (feedProvider.isLoading && feedProvider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (feedProvider.errorMessage != null) {
            return Center(child: Text('Error: ${feedProvider.errorMessage}'));
          }
          if (feedProvider.posts.isEmpty) {
            return const Center(
              child: Text('Your feed is empty. Follow some users!'),
            );
          }
          return RefreshIndicator(
            onRefresh: _refreshFeed,
            child: ListView.builder(
              itemCount: feedProvider.posts.length,
              itemBuilder: (context, index) {
                return PostCard(post: feedProvider.posts[index]);
              },
            ),
          );
        },
      ),
      // --- ✨ ลบ FloatingActionButton ที่นี่ ✨ ---
      // floatingActionButton: ...
    );
  }
}