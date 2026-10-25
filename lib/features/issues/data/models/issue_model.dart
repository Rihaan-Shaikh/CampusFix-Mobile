import 'package:flutter/foundation.dart';

const List<String> kIssueCategories = [
  'Classroom Equipment',
  'Electrical',
  'Network',
  'Furniture',
  'Cleanliness',
  'Laboratory',
  'Plumbing',
  'Other',
];

const List<String> kIssuePriorities = ['Low', 'Medium', 'High'];

@immutable
class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
    );
  }
}

@immutable
class UserSummaryModel {
  const UserSummaryModel({required this.id, required this.name, this.email});

  final String id;
  final String name;
  final String? email;

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserSummaryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Reporter',
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (email != null) 'email': email,
  };
}

@immutable
class StatusHistoryItemModel {
  const StatusHistoryItemModel({
    required this.id,
    required this.newStatus,
    required this.changedBy,
    required this.createdAt,
    this.previousStatus,
    this.note,
  });

  final String id;
  final String? previousStatus;
  final String newStatus;
  final UserSummaryModel changedBy;
  final String? note;
  final DateTime createdAt;

  factory StatusHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return StatusHistoryItemModel(
      id: json['id'] as String? ?? '',
      previousStatus: json['previousStatus'] as String?,
      newStatus: json['newStatus'] as String? ?? 'OPEN',
      changedBy: json['changedBy'] is Map<String, dynamic>
          ? UserSummaryModel.fromJson(json['changedBy'] as Map<String, dynamic>)
          : const UserSummaryModel(id: '', name: 'System'),
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@immutable
class IssueModel {
  const IssueModel({
    required this.id,
    required this.referenceCode,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.location,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
    this.resolvedAt,
    this.assignedTo,
    this.statusHistory,
    this.attachments = const [],
  });

  final String id;
  final String referenceCode;
  final String title;
  final String description;
  final String category;
  final String priority; // 'LOW', 'MEDIUM', 'HIGH'
  final String status; // 'OPEN', 'IN_PROGRESS', 'RESOLVED'
  final String location;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final UserSummaryModel createdBy;
  final UserSummaryModel? assignedTo;
  final List<StatusHistoryItemModel>? statusHistory;
  final List<String> attachments;

  bool get isOpen => status.toUpperCase() == 'OPEN';
  bool get isInProgress => status.toUpperCase() == 'IN_PROGRESS';
  bool get isResolved => status.toUpperCase() == 'RESOLVED';

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      id: json['id'] as String? ?? '',
      referenceCode: json['referenceCode'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      priority: (json['priority'] as String? ?? 'MEDIUM').toUpperCase(),
      status: (json['status'] as String? ?? 'OPEN').toUpperCase(),
      location: json['location'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
      createdBy: json['createdBy'] is Map<String, dynamic>
          ? UserSummaryModel.fromJson(json['createdBy'] as Map<String, dynamic>)
          : const UserSummaryModel(id: '', name: 'Reporter'),
      assignedTo: json['assignedTo'] is Map<String, dynamic>
          ? UserSummaryModel.fromJson(
              json['assignedTo'] as Map<String, dynamic>,
            )
          : null,
      statusHistory: json['statusHistory'] is List
          ? (json['statusHistory'] as List)
                .whereType<Map<String, dynamic>>()
                .map(StatusHistoryItemModel.fromJson)
                .toList()
          : null,
      attachments:
          (json['attachments'] as List?)?.whereType<String>().toList() ??
          (json['imageUrl'] != null ? [json['imageUrl'] as String] : const []),
    );
  }
}

@immutable
class IssueCreateRequest {
  const IssueCreateRequest({
    required this.title,
    required this.category,
    required this.location,
    required this.priority,
    required this.description,
    this.attachments = const [],
  });

  final String title;
  final String category;
  final String location;
  final String priority;
  final String description;
  final List<String> attachments;

  Map<String, dynamic> toJson() => {
    'title': title.trim(),
    'category': category,
    'location': location.trim(),
    'priority': priority,
    'description': description.trim(),
    if (attachments.isNotEmpty) 'attachments': attachments,
  };
}
