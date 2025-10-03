import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:cut_match_app/providers/notification_provider.dart';
import 'package:cut_match_app/screens/social/notifications/notification_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Feed'),
        centerTitle: false,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, child) {
              return Badge(
                label: Text('${notifProvider.unreadCount}'),
                isLabelVisible: notifProvider.hasUnreadNotifications,
                backgroundColor: theme.colorScheme.error,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  ),
                  tooltip: 'การแจ้งเตือน',
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
            tooltip: 'สร้างโพสต์',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/user_search'),
            tooltip: 'ค้นหาผู้ใช้',
          ),
        ],
      ),
      body: Consumer<FeedProvider>(
        builder: (context, feedProvider, child) {
          if (feedProvider.isLoading && feedProvider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (feedProvider.errorMessage != null) {
            return Center(
              child: Text('เกิดข้อผิดพลาด: ${feedProvider.errorMessage}'),
            );
          }
          if (feedProvider.posts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.dynamic_feed_outlined,
                      size: 80,
                      color: AppTheme.lightText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ฟีดของคุณยังว่าง',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.darkText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ลองค้นหาและติดตามเพื่อนๆ หรือช่างทำผมที่คุณสนใจสิ!',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refreshFeed,
            color: theme.colorScheme.primary,
            child: ListView.builder(
              itemCount: feedProvider.posts.length,
              itemBuilder: (context, index) {
                return PostCard(post: feedProvider.posts[index]);
              },
            ),
          );
        },
      ),
    );
  }
}