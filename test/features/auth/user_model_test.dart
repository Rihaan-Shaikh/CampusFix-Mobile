import 'package:campusfix/features/auth/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel JSON serialization & logic', () {
    test('parses full user JSON correctly', () {
      final json = {
        'id': 'usr_abc123',
        'name': 'Sarah Connor',
        'email': 'sconnor@campus.edu',
        'role': 'ADMIN',
        'emailVerified': true,
        'image': 'https://campus.edu/avatars/sarah.jpg',
        'createdAt': '2026-05-10T14:30:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'usr_abc123');
      expect(user.name, 'Sarah Connor');
      expect(user.email, 'sconnor@campus.edu');
      expect(user.role, 'ADMIN');
      expect(user.isAdmin, isTrue);
      expect(user.isMember, isFalse);
      expect(user.emailVerified, isTrue);
      expect(user.image, 'https://campus.edu/avatars/sarah.jpg');
      expect(user.createdAt, DateTime.parse('2026-05-10T14:30:00.000Z'));
    });

    test('handles missing optional fields and fallback defaults', () {
      final json = {
        'id': 'usr_default',
        'name': 'Alex',
        'email': 'alex@campus.edu',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'usr_default');
      expect(user.role, 'MEMBER');
      expect(user.isAdmin, isFalse);
      expect(user.isMember, isTrue);
      expect(user.emailVerified, isFalse);
      expect(user.image, isNull);
      expect(user.createdAt, isNull);
    });

    test('toJson produces valid serializable map', () {
      final user = UserModel(
        id: 'u1',
        name: 'Jordan',
        email: 'jordan@campus.edu',
        role: 'MEMBER',
        emailVerified: true,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final map = user.toJson();

      expect(map['id'], 'u1');
      expect(map['name'], 'Jordan');
      expect(map['email'], 'jordan@campus.edu');
      expect(map['role'], 'MEMBER');
      expect(map['emailVerified'], isTrue);
      expect(map['createdAt'], '2026-01-01T00:00:00.000Z');
    });

    test('copyWith updates specified fields only', () {
      const user = UserModel(
        id: 'u1',
        name: 'Jordan',
        email: 'jordan@campus.edu',
        role: 'MEMBER',
      );

      final updated = user.copyWith(name: 'Jordan Smith', role: 'ADMIN');

      expect(updated.id, 'u1');
      expect(updated.name, 'Jordan Smith');
      expect(updated.role, 'ADMIN');
      expect(updated.email, 'jordan@campus.edu');
    });

    test('equality and hashcode behave correctly', () {
      const u1 = UserModel(
        id: 'u1',
        name: 'Jordan',
        email: 'jordan@campus.edu',
        role: 'MEMBER',
      );
      const u2 = UserModel(
        id: 'u1',
        name: 'Jordan',
        email: 'jordan@campus.edu',
        role: 'MEMBER',
      );
      const u3 = UserModel(
        id: 'u2',
        name: 'Jordan',
        email: 'jordan@campus.edu',
        role: 'MEMBER',
      );

      expect(u1, equals(u2));
      expect(u1.hashCode, equals(u2.hashCode));
      expect(u1, isNot(equals(u3)));
    });
  });
}
