import 'package:campusfix/features/issues/data/models/issue_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IssueModel & PaginationMeta serialization', () {
    test('parses complete IssueModel JSON with status history', () {
      final json = {
        'id': 'iss_999',
        'referenceCode': 'CFX-1024',
        'title': 'Leaking pipe in Chemistry Lab 3',
        'description':
            'Continuous water dripping under sink #2 causing floor flooding.',
        'category': 'Plumbing',
        'priority': 'HIGH',
        'status': 'IN_PROGRESS',
        'location': 'Science Complex Room 304',
        'createdAt': '2026-04-12T09:15:00.000Z',
        'updatedAt': '2026-04-12T10:00:00.000Z',
        'resolvedAt': null,
        'createdBy': {
          'id': 'usr_1',
          'name': 'Prof. Davis',
          'email': 'davis@campus.edu',
        },
        'assignedTo': {'id': 'usr_2', 'name': 'Bob the Plumber'},
        'statusHistory': [
          {
            'id': 'sh_1',
            'previousStatus': 'OPEN',
            'newStatus': 'IN_PROGRESS',
            'changedBy': {'id': 'usr_admin', 'name': 'Admin'},
            'note': 'Assigned to plumbing team for inspection.',
            'createdAt': '2026-04-12T10:00:00.000Z',
          },
        ],
      };

      final issue = IssueModel.fromJson(json);

      expect(issue.id, 'iss_999');
      expect(issue.referenceCode, 'CFX-1024');
      expect(issue.title, 'Leaking pipe in Chemistry Lab 3');
      expect(issue.category, 'Plumbing');
      expect(issue.priority, 'HIGH');
      expect(issue.status, 'IN_PROGRESS');
      expect(issue.isInProgress, isTrue);
      expect(issue.isOpen, isFalse);
      expect(issue.isResolved, isFalse);
      expect(issue.location, 'Science Complex Room 304');
      expect(issue.createdBy.name, 'Prof. Davis');
      expect(issue.createdBy.email, 'davis@campus.edu');
      expect(issue.assignedTo?.name, 'Bob the Plumber');
      expect(issue.statusHistory?.length, 1);
      expect(issue.statusHistory?.first.newStatus, 'IN_PROGRESS');
      expect(
        issue.statusHistory?.first.note,
        'Assigned to plumbing team for inspection.',
      );
      expect(issue.resolvedAt, isNull);
    });

    test('handles minimal IssueModel JSON safely', () {
      final json = {
        'id': 'iss_min',
        'referenceCode': 'CFX-0001',
        'title': 'Broken desk chair',
        'description': 'Chair backrest is detached and unstable.',
        'category': 'Furniture',
        'location': 'Library 2F',
        'createdAt': '2026-03-01T12:00:00.000Z',
        'createdBy': {'id': 'u1', 'name': 'Student'},
      };

      final issue = IssueModel.fromJson(json);

      expect(issue.id, 'iss_min');
      expect(issue.priority, 'MEDIUM');
      expect(issue.status, 'OPEN');
      expect(issue.isOpen, isTrue);
      expect(issue.assignedTo, isNull);
      expect(issue.statusHistory, isNull);
    });

    test('parses PaginationMeta correctly', () {
      final json = {
        'page': 2,
        'limit': 20,
        'totalItems': 45,
        'totalPages': 3,
        'hasNextPage': true,
        'hasPreviousPage': true,
      };

      final meta = PaginationMeta.fromJson(json);

      expect(meta.page, 2);
      expect(meta.limit, 20);
      expect(meta.totalItems, 45);
      expect(meta.totalPages, 3);
      expect(meta.hasNextPage, isTrue);
      expect(meta.hasPreviousPage, isTrue);
    });

    test('IssueCreateRequest serializes with trim and correct schema', () {
      const request = IssueCreateRequest(
        title: '  Broken projector cord  ',
        category: 'Classroom Equipment',
        location: '  Auditorium B  ',
        priority: 'High',
        description:
            '  The cable connector is bent and no video signal outputs.  ',
      );

      final map = request.toJson();

      expect(map['title'], 'Broken projector cord');
      expect(map['category'], 'Classroom Equipment');
      expect(map['location'], 'Auditorium B');
      expect(map['priority'], 'High');
      expect(
        map['description'],
        'The cable connector is bent and no video signal outputs.',
      );
    });

    test(
      'parses attachments list and imageUrl fallback in IssueModel correctly',
      () {
        final json = {
          'id': 'iss_att_1',
          'referenceCode': 'CFX-2048',
          'title': 'Cracked window pane',
          'description': 'Outer glass layer cracked after strong winds.',
          'category': 'Facilities',
          'location': 'Gymnasium East Wing',
          'createdAt': '2026-05-01T12:00:00.000Z',
          'createdBy': {'id': 'u1', 'name': 'Staff'},
          'attachments': ['https://storage.campusfix.edu/uploads/window.jpg'],
        };

        final issue = IssueModel.fromJson(json);
        expect(issue.attachments.length, 1);
        expect(
          issue.attachments.first,
          'https://storage.campusfix.edu/uploads/window.jpg',
        );

        final fallbackJson = {
          'id': 'iss_att_2',
          'referenceCode': 'CFX-2049',
          'title': 'Broken lock',
          'description': 'Key broke inside lock',
          'category': 'Security',
          'location': 'Door 4',
          'createdAt': '2026-05-01T12:00:00.000Z',
          'createdBy': {'id': 'u1', 'name': 'Staff'},
          'imageUrl': 'https://storage.campusfix.edu/uploads/lock.jpg',
        };
        final fallbackIssue = IssueModel.fromJson(fallbackJson);
        expect(fallbackIssue.attachments.length, 1);
        expect(
          fallbackIssue.attachments.first,
          'https://storage.campusfix.edu/uploads/lock.jpg',
        );
      },
    );

    test('IssueCreateRequest includes attachments when provided', () {
      const request = IssueCreateRequest(
        title: 'Broken chair',
        category: 'Furniture',
        location: 'Room 101',
        priority: 'Low',
        description: 'Leg is loose',
        attachments: ['https://cdn.campusfix.edu/chair.png'],
      );

      final map = request.toJson();
      expect(map['attachments'], ['https://cdn.campusfix.edu/chair.png']);
    });
  });
}
