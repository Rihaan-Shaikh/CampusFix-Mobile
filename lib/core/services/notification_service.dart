import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage_service.dart';

/// Notification payload entity representing an incoming push notification event.
@immutable
class CampusNotificationPayload {
  const CampusNotificationPayload({
    required this.title,
    required this.body,
    this.issueId,
    this.action,
    this.timestamp,
  });

  final String title;
  final String body;
  final String? issueId;
  final String? action;
  final DateTime? timestamp;

  factory CampusNotificationPayload.fromMap(Map<String, dynamic> map) {
    return CampusNotificationPayload(
      title: map['title'] as String? ?? 'CampusFix Notification',
      body: map['body'] as String? ?? '',
      issueId: map['issueId'] as String?,
      action: map['action'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString())
          : null,
    );
  }
}

/// Service managing push notification permissions, authenticated device-token registration,
/// and safe navigation event dispatching.
class NotificationService {
  NotificationService({required this.storage});

  final SecureStorageService storage;
  static const String _deviceTokenKey = 'campusfix_fcm_device_token';

  /// Simulates / registers device token securely.
  Future<void> registerDeviceToken(String token) async {
    if (token.trim().isEmpty) return;
    await storage.write(_deviceTokenKey, token.trim());
  }

  /// Retrieves the registered device token.
  Future<String?> getRegisteredToken() async {
    return storage.read(_deviceTokenKey);
  }

  /// Cleans up device token upon user sign-out to prevent privacy leakage.
  Future<void> unregisterOnSignOut() async {
    await storage.delete(_deviceTokenKey);
  }

  /// Validates whether a notification payload should trigger navigation to an issue.
  String? resolveIssueRoute(CampusNotificationPayload payload) {
    if (payload.issueId != null && payload.issueId!.trim().isNotEmpty) {
      return '/issues/${payload.issueId!.trim()}';
    }
    return null;
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return NotificationService(storage: storage);
});
