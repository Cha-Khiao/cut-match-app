import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  String? _token;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get token => _token;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnreadNotifications => unreadCount > 0;

  void updateToken(String? token) {
    _token = token;
    if (token != null) {
      fetchNotifications();
    } else {
      _notifications = [];
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

      if (isBackgroundRefresh) {
        final trulyNewNotifications = newNotifications
            .where((n) => !oldNotificationIds.contains(n.id))
            .toList();
        if (trulyNewNotifications.isNotEmpty) {
          _notifications = newNotifications;
          _showInAppNotification(trulyNewNotifications.first);
          notifyListeners();
        }
      } else {
        _notifications = newNotifications;
      }
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
      case 'follow':
        return 'started following you.';
      default:
        return 'sent a notification.';
    }
  }

  Future<void> markAllAsRead() async {
    if (_token == null || unreadCount == 0) return;

    final originalNotifications = _notifications;
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();

    try {
      await ApiService.markAllAsRead(_token!);
    } catch (e) {
      _notifications = originalNotifications;
      notifyListeners();
      print('Failed to mark as read: $e');
    }
  }

  void markOneAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      final updatedNotification = _notifications[index].copyWith(isRead: true);
      _notifications[index] = updatedNotification;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (_token == null) return;
    final existingIndex = _notifications.indexWhere(
      (n) => n.id == notificationId,
    );
    if (existingIndex == -1) return;

    final existingNotification = _notifications[existingIndex];
    _notifications.removeAt(existingIndex);
    notifyListeners();

    try {
      await ApiService.deleteNotification(notificationId, _token!);
    } catch (e) {
      print('Failed to delete notification on server: $e');
      _notifications.insert(existingIndex, existingNotification);
      notifyListeners();
    }
  }
}