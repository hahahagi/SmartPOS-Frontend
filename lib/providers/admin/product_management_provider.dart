import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pagination_meta.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_payload.dart';
import '../../data/repositories/product_repository.dart';

class ProductManagementState {
  const ProductManagementState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.errorMessage,
    this.searchQuery = '',
    this.categoryId,
    this.meta,
    this.busyProductIds = const <int>{},
    this.isSaving = false,
  });

  final List<ProductModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? errorMessage;
  final String searchQuery;
  final int? categoryId;
  final PaginationMeta? meta;
  final Set<int> busyProductIds;
  final bool isSaving;

  bool get isEmpty => !isLoading && items.isEmpty;

  ProductManagementState copyWith({
    List<ProductModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
    int? categoryId,
    bool clearCategory = false,
    PaginationMeta? meta,
    Set<int>? busyProductIds,
    bool? isSaving,
  }) {
    return ProductManagementState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      meta: meta ?? this.meta,
      busyProductIds: busyProductIds ?? this.busyProductIds,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class ProductManagementNotifier extends StateNotifier<ProductManagementState> {
  ProductManagementNotifier(this._repository)
    : super(const ProductManagementState()) {
    loadInitial();
  }

  final ProductRepository _repository;
  static const _perPage = 10;

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoading: true,
      page: 1,
      hasMore: true,
      clearError: true,
    );
    try {
      final response = await _repository.fetchProducts(
        page: 1,
        perPage: _perPage,
        search: state.searchQuery,
        categoryId: state.categoryId,
      );
      state = state.copyWith(
        isLoading: false,
        items: response.items,
        hasMore: response.hasMore,
        page: 1,
        meta: response.meta,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Tidak dapat memuat produk: $error',
      );
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) {
      return;
    }
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final response = await _repository.fetchProducts(
        page: nextPage,
        perPage: _perPage,
        search: state.searchQuery,
        categoryId: state.categoryId,
      );
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...response.items],
        page: nextPage,
        hasMore: response.hasMore,
        meta: response.meta,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Tidak dapat memuat halaman berikutnya: $error',
      );
    }
  }

  Future<void> setSearch(String query) async {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
    await loadInitial();
  }

  Future<void> setCategory(int? categoryId) async {
    if (categoryId == state.categoryId) return;
    state = state.copyWith(categoryId: categoryId, page: 1);
    await loadInitial();
  }

  Future<void> clearFilters() async {
    if (state.searchQuery.isEmpty && state.categoryId == null) {
      return;
    }
    state = state.copyWith(searchQuery: '', clearCategory: true);
    await loadInitial();
  }

  Future<void> createProduct(ProductPayload payload) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repository.createProduct(payload);
      await loadInitial();
    } catch (error) {
      state = state.copyWith(errorMessage: 'Gagal menyimpan produk: $error');
      rethrow;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> updateProduct(int id, ProductPayload payload) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repository.updateProduct(id, payload);
      await loadInitial();
    } catch (error) {
      state = state.copyWith(errorMessage: 'Gagal memperbarui produk: $error');
      rethrow;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> deleteProduct(int id) async {
    final busy = {...state.busyProductIds, id};
    state = state.copyWith(busyProductIds: busy, clearError: true);
    try {
      await _repository.deleteProduct(id);
      await loadInitial();
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Tidak dapat menghapus produk: $error',
      );
      rethrow;
    } finally {
      final updated = {...state.busyProductIds}..remove(id);
      state = state.copyWith(busyProductIds: updated);
    }
  }

  Future<void> toggleProductStatus(ProductModel product, bool isActive) async {
    final busy = {...state.busyProductIds, product.id};
    state = state.copyWith(busyProductIds: busy, clearError: true);
    try {
      final updated = await _repository.updateProductStatus(
        product.id,
        isActive,
      );
      final items = state.items
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      state = state.copyWith(items: items);
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Tidak dapat memperbarui status: $error',
      );
      rethrow;
    } finally {
      final updatedBusy = {...state.busyProductIds}..remove(product.id);
      state = state.copyWith(busyProductIds: updatedBusy);
    }
  }
}

final productManagementProvider =
    StateNotifierProvider.autoDispose<
      ProductManagementNotifier,
      ProductManagementState
    >((ref) {
      final repository = ref.watch(productRepositoryProvider);
      return ProductManagementNotifier(repository);
    });
