import 'package:campusfix/core/services/notification_service.dart';
import 'package:campusfix/core/storage/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecureStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);
}

void main() {
  group('NotificationService & CampusNotificationPayload', () {
    late _FakeSecureStorage storage;
    late NotificationService service;

    setUp(() {
      storage = _FakeSecureStorage();
      service = NotificationService(storage: storage);
    });

    test(
      'CampusNotificationPayload.fromMap deserializes payload fields correctly',
      () {
        final map = {
          'title': 'Issue Status Updated',
          'body': 'Your reported issue CFX-4921 has been resolved.',
          'issueId': 'iss_123',
          'action': 'STATUS_CHANGE',
          'timestamp': '2026-10-17T00:00:00.000Z',
        };

        final payload = CampusNotificationPayload.fromMap(map);
        expect(payload.title, 'Issue Status Updated');
        expect(payload.body, 'Your reported issue CFX-4921 has been resolved.');
        expect(payload.issueId, 'iss_123');
        expect(payload.action, 'STATUS_CHANGE');
        expect(payload.timestamp, isNotNull);
      },
    );

    test(
      'resolveIssueRoute returns valid issue route when issueId is provided',
      () {
        const payload = CampusNotificationPayload(
          title: 'Assigned',
          body: 'Assigned to you',
          issueId: 'iss_abc890',
        );

        final route = service.resolveIssueRoute(payload);
        expect(route, '/issues/iss_abc890');
      },
    );

    test('resolveIssueRoute returns null when issueId is null or empty', () {
      const payloadNoId = CampusNotificationPayload(
        title: 'System Announcement',
        body: 'Campus facilities maintenance tonight',
      );
      expect(service.resolveIssueRoute(payloadNoId), isNull);

      const payloadEmptyId = CampusNotificationPayload(
        title: 'System Announcement',
        body: 'Campus facilities maintenance tonight',
        issueId: '  ',
      );
      expect(service.resolveIssueRoute(payloadEmptyId), isNull);
    });

    test('registers, retrieves, and unregisters device token', () async {
      await service.registerDeviceToken('fcm_token_xyz_98765');
      expect(await service.getRegisteredToken(), 'fcm_token_xyz_98765');

      await service.unregisterOnSignOut();
      expect(await service.getRegisteredToken(), isNull);
    });
  });
}
