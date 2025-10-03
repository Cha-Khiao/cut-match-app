import 'package:cut_match_app/models/notification_model.dart';
import 'package:cut_match_app/screens/profiles/profile_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  String _getNotificationMessage() {
    switch (notification.type) {
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

  IconData _getNotificationIcon() {
    switch (notification.type) {
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

  Color _getNotificationIconColor() {
    switch (notification.type) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = DateFormat(
      'd MMM yyyy, HH:mm',
    ).format(notification.createdAt.toLocal());

    return ListTile(
      onTap: onTap,
      tileColor: notification.isRead
          ? null
          : AppTheme.primary.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: notification.sender.id),
              ),
            ),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: AppTheme.background,
              backgroundImage: notification.sender.profileImageUrl.isNotEmpty
                  ? NetworkImage(notification.sender.profileImageUrl)
                  : null,
              child: notification.sender.profileImageUrl.isEmpty
                  ? const Icon(
                      Icons.person,
                      color: AppTheme.lightText,
                      size: 28,
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: CircleAvatar(
              radius: 11,
              backgroundColor: theme.scaffoldBackgroundColor,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: _getNotificationIconColor(),
                child: Icon(
                  _getNotificationIcon(),
                  color: Colors.white,
                  size: 12,
                ),
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
              text: notification.sender.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: _getNotificationMessage(),
              style: const TextStyle(color: AppTheme.darkText),
            ),
          ],
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(timeAgo, style: theme.textTheme.bodySmall),
      ),
      trailing: notification.post?.imageUrls.isNotEmpty ?? false
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: Image.network(
                notification.post!.imageUrls.first,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            )
          : null,
    );
  }
}