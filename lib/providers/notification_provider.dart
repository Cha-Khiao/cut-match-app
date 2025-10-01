import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  String? _token;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get token => _token;

  void updateToken(String? token) {
    _token = token;
    if (token != null) {
      fetchNotifications();
    } else {
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> fetchNotifications({bool isBackgroundRefresh = false}) async {
    if (_token == null) return;

    if (!isBackgroundRefresh) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final Set<String> oldNotificationIds = _notifications
          .map((n) => n.id)
          .toSet();

      final newNotifications = await ApiService.getNotifications(_token!);
      _notifications = newNotifications;
      _unreadCount = _notifications.where((n) => !n.isRead).length;

      // --- ✨ แก้ไข Logic การค้นหาที่นี่ ✨ ---
      if (isBackgroundRefresh) {
        // 1. กรองหา notification ทั้งหมดที่ยังไม่เคยเห็น
        final trulyNewNotifications = _notifications
            .where((n) => !oldNotificationIds.contains(n.id))
            .toList();

        // 2. ถ้ามี notification ใหม่ๆ เกิดขึ้น
        if (trulyNewNotifications.isNotEmpty) {
          // 3. ให้แสดงแบนเนอร์ของอันแรกสุดที่เจอ
          _showInAppNotification(trulyNewNotifications.first);
        }
      }
      // ------------------------------------
    } catch (e) {
      print('Failed to fetch notifications: $e');
    }

    if (!isBackgroundRefresh) {
      _isLoading = false;
    }
    notifyListeners();
  }

  void _showInAppNotification(NotificationModel notif) {
    showSimpleNotification(
      Text("${notif.sender.username} ${_getNotificationMessage(notif)}"),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(notif.sender.profileImageUrl),
      ),
      background: Colors.white,
      duration: const Duration(seconds: 4),
      elevation: 4,
    );
  }

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
        return 'sent a notification.';
    }
  }

  Future<void> markAllAsRead() async {
    if (_token == null || _unreadCount == 0) return;

    final tempNotifications = List<NotificationModel>.from(_notifications);
    _unreadCount = 0;
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();

    try {
      await ApiService.markAllAsRead(_token!);
    } catch (e) {
      _notifications = tempNotifications;
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
      print('Failed to mark as read: $e');
    }
  }

  void markOneAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      _unreadCount--;
      if (_unreadCount < 0) _unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (_token == null) return;

    final int existingIndex = _notifications.indexWhere(
      (n) => n.id == notificationId,
    );
    if (existingIndex == -1) return;

    final NotificationModel existingNotification =
        _notifications[existingIndex];

    _notifications.removeAt(existingIndex);
    if (!existingNotification.isRead) {
      _unreadCount--;
    }
    notifyListeners();

    try {
      await ApiService.deleteNotification(notificationId, _token!);
    } catch (e) {
      print('Failed to delete notification on server: $e');
      _notifications.insert(existingIndex, existingNotification);
      if (!existingNotification.isRead) {
        _unreadCount++;
      }
      notifyListeners();
    }
  }
}