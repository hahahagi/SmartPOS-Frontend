import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../exceptions/app_exception.dart';
import '../models/product_list_response.dart';
import '../models/product_model.dart';
import '../models/product_payload.dart';
import '../services/api_client.dart';
import '../services/product_cache_service.dart';

class ProductRepository {
  ProductRepository(this._dio, this._cache);

  final Dio _dio;
  final ProductCacheService _cache;

  Future<ProductListResponse> fetchProducts({
    int page = 1,
    int perPage = 10,
    String? search,
    int? categoryId,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '/products',
      queryParameters: query,
    );
    final data = response.data ?? <String, dynamic>{};
    final listResponse = ProductListResponse.fromJson(data);
    await _cache.saveProducts(listResponse.items);
    return listResponse;
  }

  Future<ProductModel> getByBarcode(String barcode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/products/barcode/$barcode',
      );
      final body =
          response.data?['data'] as Map<String, dynamic>? ??
          <String, dynamic>{};
      final product = ProductModel.fromJson(body);
      await _cache.saveProduct(product);
      return product;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw BarcodeNotFoundException(
          'Produk dengan barcode tersebut tidak ditemukan',
        );
      }
      if (_shouldUseCache(error)) {
        final cached = _cache.getByBarcode(barcode);
        if (cached != null) {
          return cached;
        }
        throw AppException('Offline: produk belum pernah di-cache.');
      }
      rethrow;
    }
  }

  Future<List<ProductModel>> search(String query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/products',
        queryParameters: {'search': query, 'per_page': 30},
      );
      final listResponse = ProductListResponse.fromJson(
        response.data ?? <String, dynamic>{},
      );
      final products = listResponse.items;
      await _cache.saveProducts(products);
      return products;
    } on DioException catch (error) {
      if (_shouldUseCache(error)) {
        final cached = _cache.searchLocally(query);
        if (cached.isNotEmpty) {
          return cached;
        }
        throw AppException('Offline: produk belum tersedia pada cache.');
      }
      rethrow;
    }
  }

  Future<ProductModel> createProduct(ProductPayload payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/products',
      data: payload.toJson(),
    );
    final body =
        response.data?['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ProductModel.fromJson(body);
  }

  Future<ProductModel> updateProduct(int id, ProductPayload payload) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/products/$id',
      data: payload.toJson(),
    );
    final body =
        response.data?['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ProductModel.fromJson(body);
  }

  Future<ProductModel> updateProductStatus(int id, bool isActive) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/products/$id',
      data: {'is_active': isActive},
    );
    final body =
        response.data?['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ProductModel.fromJson(body);
  }

  Future<void> deleteProduct(int id) async {
    await _dio.delete<void>('/products/$id');
  }

  bool _shouldUseCache(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    return error.error is SocketException;
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  final cache = ref.watch(productCacheServiceProvider);
  return ProductRepository(dio, cache);
});
