import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';
import '../models/category_payload.dart';
import '../services/api_client.dart';

class CategoryRepository {
  CategoryRepository(this._dio);

  final Dio _dio;

  Future<List<CategoryModel>> fetchAll() async {
    final response = await _dio.get<Map<String, dynamic>>('/categories');
    final data = response.data ?? <String, dynamic>{};
    final items = data['data'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .toList();
  }

  Future<CategoryModel> createCategory(CategoryPayload payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/categories',
      data: payload.toJson(),
    );
    final body =
        response.data?['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return CategoryModel.fromJson(body);
  }

  Future<CategoryModel> updateCategory(int id, CategoryPayload payload) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/categories/$id',
      data: payload.toJson(),
    );
    final body =
        response.data?['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return CategoryModel.fromJson(body);
  }

  Future<void> deleteCategory(int id) async {
    await _dio.delete<void>('/categories/$id');
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return CategoryRepository(dio);
});
