import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/issue_model.dart';

abstract class IssueRepository {
  Future<({List<IssueModel> items, PaginationMeta meta})> listIssues({
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
    String? priority,
    String? search,
    String? scope,
  });

  Future<IssueModel> getIssueById(String id);

  Future<IssueModel> createIssue(IssueCreateRequest request);

  Future<IssueModel> updateIssueStatus({
    required String id,
    required String status,
    String? note,
  });
}

class ApiIssueRepository implements IssueRepository {
  ApiIssueRepository({required this.dio, required this.config});

  final Dio dio;
  final AppConfig config;

  @override
  Future<({List<IssueModel> items, PaginationMeta meta})> listIssues({
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
    String? priority,
    String? search,
    String? scope,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (status != null &&
          status.isNotEmpty &&
          status.toUpperCase() != 'ALL') {
        queryParams['status'] = status.toUpperCase();
      }
      if (category != null && category.isNotEmpty && category != 'All') {
        queryParams['category'] = category;
      }
      if (priority != null &&
          priority.isNotEmpty &&
          priority.toUpperCase() != 'ALL') {
        queryParams['priority'] = priority.toUpperCase();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (scope != null && scope.isNotEmpty) {
        queryParams['scope'] = scope;
      }

      final response = await dio.get<Map<String, dynamic>>(
        '${config.v1BaseUrl}/issues',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw const ApiException(
          message: 'Invalid issue list response from server.',
        );
      }

      final itemsRaw = data['data'] as List;
      final items = itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(IssueModel.fromJson)
          .toList();

      final metaJson = data['meta'] as Map<String, dynamic>? ?? {};
      final meta = PaginationMeta.fromJson(metaJson);

      return (items: items, meta: meta);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw ApiException(
        message: e.message ?? 'Failed to load issues.',
        cause: e,
      );
    }
  }

  @override
  Future<IssueModel> getIssueById(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '${config.v1BaseUrl}/issues/$id',
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw const ApiException(message: 'Issue details not found.');
      }

      return IssueModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw ApiException(
        message: e.message ?? 'Failed to load issue details.',
        cause: e,
      );
    }
  }

  @override
  Future<IssueModel> createIssue(IssueCreateRequest request) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '${config.v1BaseUrl}/issues',
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw const ApiException(message: 'Failed to create issue.');
      }

      return IssueModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw ApiException(
        message: e.message ?? 'Failed to submit issue.',
        cause: e,
      );
    }
  }

  @override
  Future<IssueModel> updateIssueStatus({
    required String id,
    required String status,
    String? note,
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': status.toUpperCase(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };

      final response = await dio.patch<Map<String, dynamic>>(
        '${config.v1BaseUrl}/issues/$id',
        data: payload,
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw const ApiException(message: 'Failed to update issue status.');
      }

      return IssueModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw ApiException(
        message: e.message ?? 'Failed to update issue status.',
        cause: e,
      );
    }
  }
}

final issueRepositoryProvider = Provider<IssueRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final config = ref.watch(appConfigProvider);
  return ApiIssueRepository(dio: dio, config: config);
});
