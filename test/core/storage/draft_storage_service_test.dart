import 'package:campusfix/core/storage/draft_storage_service.dart';
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
  group('DraftStorageService & IssueDraft model', () {
    late _FakeSecureStorage fakeStorage;
    late DraftStorageService draftService;

    setUp(() {
      fakeStorage = _FakeSecureStorage();
      draftService = DraftStorageService(storage: fakeStorage);
    });

    test('IssueDraft detects empty and non-empty drafts correctly', () {
      final emptyDraft = IssueDraft(lastModified: DateTime.now());
      expect(emptyDraft.isEmpty, isTrue);

      final draftWithTitle = IssueDraft(
        title: 'Broken projector',
        lastModified: DateTime.now(),
      );
      expect(draftWithTitle.isEmpty, isFalse);

      final draftWithAttachment = IssueDraft(
        attachmentPaths: const ['/tmp/photo.jpg'],
        lastModified: DateTime.now(),
      );
      expect(draftWithAttachment.isEmpty, isFalse);
    });

    test('IssueDraft serializes and deserializes correctly via JSON', () {
      final now = DateTime.now();
      final draft = IssueDraft(
        title: 'Leaking pipe',
        category: 'Plumbing',
        location: 'Library 2F',
        priority: 'High',
        description: 'Water leaking near bookshelf 4',
        attachmentPaths: const ['/data/user/0/cache/img1.jpg'],
        lastModified: now,
      );

      final json = draft.toJson();
      final restored = IssueDraft.fromJson(json);

      expect(restored.title, 'Leaking pipe');
      expect(restored.category, 'Plumbing');
      expect(restored.location, 'Library 2F');
      expect(restored.priority, 'High');
      expect(restored.description, 'Water leaking near bookshelf 4');
      expect(restored.attachmentPaths, ['/data/user/0/cache/img1.jpg']);
      expect(
        restored.lastModified.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
    });

    test('saves and recovers draft from storage', () async {
      final now = DateTime.now();
      final draft = IssueDraft(
        title: 'AC unit buzzing',
        category: 'HVAC',
        location: 'Lab 101',
        priority: 'Low',
        description: 'Loud buzzing sound when fan turns on',
        attachmentPaths: const [],
        lastModified: now,
      );

      await draftService.saveDraft(draft);

      final retrieved = await draftService.getDraft();
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'AC unit buzzing');
      expect(retrieved.location, 'Lab 101');
    });

    test('saving empty draft clears the draft from storage', () async {
      final emptyDraft = IssueDraft(lastModified: DateTime.now());
      await draftService.saveDraft(emptyDraft);

      final retrieved = await draftService.getDraft();
      expect(retrieved, isNull);
    });

    test('clearDraft removes persisted draft from storage', () async {
      final draft = IssueDraft(
        title: 'Broken chair',
        lastModified: DateTime.now(),
      );
      await draftService.saveDraft(draft);
      expect(await draftService.getDraft(), isNotNull);

      await draftService.clearDraft();
      expect(await draftService.getDraft(), isNull);
    });

    test(
      'corrupted JSON in storage returns null and self-heals by clearing',
      () async {
        await fakeStorage.write('campusfix_issue_draft_v1', '{corrupted_json:');

        final retrieved = await draftService.getDraft();
        expect(retrieved, isNull);

        final exists = await fakeStorage.containsKey(
          'campusfix_issue_draft_v1',
        );
        expect(exists, isFalse);
      },
    );
  });
}
