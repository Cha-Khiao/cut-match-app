import 'package:cut_match_app/models/notification_model.dart';
import 'package:cut_match_app/providers/notification_provider.dart';
import 'package:cut_match_app/screens/social/posts/post_detail_screen.dart';
import 'package:cut_match_app/screens/profiles/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  String _getNotificationMessage(NotificationModel notif) {
    switch (notif.type) {
      case 'like':
        return 'liked your post.';
      case 'comment':
        return 'commented on your post.';
      case 'reply':
        return 'replied to your comment.';
      case 'follow':
        return 'started following you.';
      default:
        return 'sent you a notification.';
    }
  }

  void _onNotificationTapped(BuildContext context, NotificationModel notif) {
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    if (!notif.isRead) {
      notificationProvider.markOneAsRead(notif.id);
    }

    if (notif.type == 'follow') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: notif.sender.id),
        ),
      );
    } else if (notif.post != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: notif.post!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notificationProvider.unreadCount > 0)
            TextButton(
              onPressed: () => notificationProvider.markAllAsRead(),
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notificationProvider.fetchNotifications(),
        child: notificationProvider.notifications.isEmpty
            ? const Center(child: Text('You have no notifications yet.'))
            : ListView.builder(
                itemCount: notificationProvider.notifications.length,
                itemBuilder: (context, index) {
                  final notif = notificationProvider.notifications[index];

                  return Dismissible(
                    key: Key(notif.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      notificationProvider.deleteNotification(notif.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification dismissed')),
                      );
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(
                        Icons.delete_sweep,
                        color: Colors.white,
                      ),
                    ),
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileScreen(userId: notif.sender.id),
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(
                            notif.sender.profileImageUrl,
                          ),
                        ),
                      ),
                      // --- ✨ แก้ไขการแสดงผลข้อความที่นี่ ✨ ---
                      title: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(
                            context,
                          ).style.copyWith(fontSize: 16),
                          children: [
                            TextSpan(
                              text: notif.sender.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(text: _getNotificationMessage(notif)),
                          ],
                        ),
                      ),
                      subtitle: Text(
                        notif.createdAt.toLocal().toString().substring(0, 16),
                      ), // แสดงเวลา
                      trailing: notif.post?.imageUrls.isNotEmpty ?? false
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: Image.network(
                                notif.post!.imageUrls.first,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : null,
                      tileColor: notif.isRead
                          ? Colors.white
                          : Colors.blue.shade50,
                      onTap: () => _onNotificationTapped(context, notif),
                    ),
                  );
                },
              ),
      ),
    );
  }
}