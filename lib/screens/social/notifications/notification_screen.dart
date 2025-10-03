import 'package:cut_match_app/models/notification_model.dart';
import 'package:cut_match_app/providers/notification_provider.dart';
import 'package:cut_match_app/screens/social/posts/post_detail_screen.dart';
import 'package:cut_match_app/screens/profiles/profile_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  String _getNotificationMessage(NotificationModel notif) {
    switch (notif.type) {
      case 'like':
        return 'ถูกใจโพสต์ของคุณ';
      case 'comment':
        return 'แสดงความคิดเห็นบนโพสต์ของคุณ';
      case 'reply':
        return 'ตอบกลับความคิดเห็นของคุณ';
      case 'follow':
        return 'เริ่มติดตามคุณ';
      default:
        return 'ส่งการแจ้งเตือนถึงคุณ';
    }
  }

  IconData _getNotificationIcon(NotificationModel notif) {
    switch (notif.type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.maps_ugc;
      case 'reply':
        return Icons.reply;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationIconColor(NotificationModel notif) {
    switch (notif.type) {
      case 'like':
        return Colors.pink;
      case 'comment':
        return Colors.blue;
      case 'reply':
        return Colors.green;
      case 'follow':
        return AppTheme.primary;
      default:
        return AppTheme.lightText;
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
    final notificationProvider = context.watch<NotificationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          if (notificationProvider.unreadCount > 0)
            TextButton(
              onPressed: () => notificationProvider.markAllAsRead(),
              child: const Text('อ่านทั้งหมด'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notificationProvider.fetchNotifications(),
        color: theme.colorScheme.primary,
        child: notificationProvider.notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_off_outlined,
                      size: 80,
                      color: AppTheme.lightText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ยังไม่มีการแจ้งเตือน',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: notificationProvider.notifications.length,
                itemBuilder: (context, index) {
                  final notif = notificationProvider.notifications[index];
                  final timeAgo = DateFormat(
                    'd MMM yyyy, HH:mm',
                  ).format(notif.createdAt.toLocal());

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: notif.isRead
                        ? Colors.white
                        : AppTheme.primary.withOpacity(0.05),
                    child: Dismissible(
                      key: Key(notif.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        notificationProvider.deleteNotification(notif.id);
                        NotificationHelper.showSuccess(
                          context,
                          message: 'ลบการแจ้งเตือนแล้ว',
                        );
                      },
                      background: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(
                          Icons.delete_sweep,
                          color: Colors.white,
                        ),
                      ),
                      child: ListTile(
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProfileScreen(userId: notif.sender.id),
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: AppTheme.background,
                                backgroundImage:
                                    notif.sender.profileImageUrl.isNotEmpty
                                    ? NetworkImage(notif.sender.profileImageUrl)
                                    : null,
                                child: notif.sender.profileImageUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        color: AppTheme.lightText,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: _getNotificationIconColor(
                                  notif,
                                ),
                                child: Icon(
                                  _getNotificationIcon(notif),
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyLarge,
                            children: [
                              TextSpan(
                                text: notif.sender.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(text: ' '),
                              TextSpan(
                                text: _getNotificationMessage(notif),
                                style: const TextStyle(
                                  color: AppTheme.darkText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        subtitle: Text(
                          timeAgo,
                          style: theme.textTheme.bodySmall,
                        ),
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
                        onTap: () => _onNotificationTapped(context, notif),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}