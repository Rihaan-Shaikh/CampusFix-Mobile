import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'secure_storage_service.dart';

@immutable
class IssueDraft {
  const IssueDraft({
    this.title = '',
    this.category = 'Classroom Equipment',
    this.location = '',
    this.priority = 'Medium',
    this.description = '',
    this.attachmentPaths = const [],
    required this.lastModified,
  });

  final String title;
  final String category;
  final String location;
  final String priority;
  final String description;
  final List<String> attachmentPaths;
  final DateTime lastModified;

  bool get isEmpty =>
      title.trim().isEmpty &&
      location.trim().isEmpty &&
      description.trim().isEmpty &&
      attachmentPaths.isEmpty;

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category,
    'location': location,
    'priority': priority,
    'description': description,
    'attachmentPaths': attachmentPaths,
    'lastModified': lastModified.toIso8601String(),
  };

  factory IssueDraft.fromJson(Map<String, dynamic> json) {
    return IssueDraft(
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'Classroom Equipment',
      location: json['location'] as String? ?? '',
      priority: json['priority'] as String? ?? 'Medium',
      description: json['description'] as String? ?? '',
      attachmentPaths:
          (json['attachmentPaths'] as List?)?.whereType<String>().toList() ??
          const [],
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class DraftStorageService {
  DraftStorageService({required this.storage});

  final SecureStorageService storage;
  static const String _draftKey = 'campusfix_issue_draft_v1';

  Future<void> saveDraft(IssueDraft draft) async {
    if (draft.isEmpty) {
      await clearDraft();
      return;
    }
    final rawJson = jsonEncode(draft.toJson());
    await storage.write(_draftKey, rawJson);
  }

  Future<IssueDraft?> getDraft() async {
    final rawJson = await storage.read(_draftKey);
    if (rawJson == null || rawJson.isEmpty) return null;
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final draft = IssueDraft.fromJson(map);
      return draft.isEmpty ? null : draft;
    } catch (_) {
      await clearDraft();
      return null;
    }
  }

  Future<void> clearDraft() async {
    await storage.delete(_draftKey);
  }
}

final draftStorageServiceProvider = Provider<DraftStorageService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return DraftStorageService(storage: storage);
});
