import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

class NotificationHelper {
  static void showSuccess(BuildContext context, {required String message}) {
    showSimpleNotification(
      Text(message, style: const TextStyle(color: Colors.white)),
      leading: const Icon(Icons.check_circle_outline, color: Colors.white),
      background: Colors.green.shade600,
      duration: const Duration(seconds: 3),
      elevation: 4,
    );
  }

  static void showError(BuildContext context, {required String message}) {
    final theme = Theme.of(context);

    showSimpleNotification(
      Text(message, style: const TextStyle(color: Colors.white)),
      leading: const Icon(Icons.error_outline, color: Colors.white),
      background: theme.colorScheme.error,
      duration: const Duration(seconds: 4),
      elevation: 4,
    );
  }
}
