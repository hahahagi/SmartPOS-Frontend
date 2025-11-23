import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category_model.dart';
import '../../data/models/category_payload.dart';
import '../../data/repositories/category_repository.dart';
import '../category_provider.dart';

class CategoryManagementState {
  const CategoryManagementState({
    this.items = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.searchQuery = '',
    this.busyCategoryIds = const <int>{},
  });

  final List<CategoryModel> items;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String searchQuery;
  final Set<int> busyCategoryIds;

  List<CategoryModel> get filteredItems {
    if (searchQuery.isEmpty) return items;
    final keyword = searchQuery.toLowerCase();
    return items
        .where(
          (category) =>
              category.name.toLowerCase().contains(keyword) ||
              (category.description?.toLowerCase().contains(keyword) ?? false),
        )
        .toList();
  }

  bool get isEmpty => !isLoading && filteredItems.isEmpty;

  CategoryManagementState copyWith({
    List<CategoryModel>? items,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
    Set<int>? busyCategoryIds,
  }) {
    return CategoryManagementState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      busyCategoryIds: busyCategoryIds ?? this.busyCategoryIds,
    );
  }
}

class CategoryManagementNotifier
    extends StateNotifier<CategoryManagementState> {
  CategoryManagementNotifier(this._ref, this._repository)
    : super(const CategoryManagementState()) {
    loadCategories();
  }

  final Ref _ref;
  final CategoryRepository _repository;

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final categories = await _repository.fetchAll();
      state = state.copyWith(isLoading: false, items: categories);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Tidak dapat memuat kategori: $error',
      );
    }
  }

  Future<void> refresh() async => loadCategories();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> createCategory(CategoryPayload payload) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final category = await _repository.createCategory(payload);
      state = state.copyWith(items: [category, ...state.items]);
      _invalidateCategoryCache();
    } catch (error) {
      state = state.copyWith(errorMessage: 'Gagal membuat kategori: $error');
      rethrow;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> updateCategory(int id, CategoryPayload payload) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repository.updateCategory(id, payload);
      final items = state.items
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      state = state.copyWith(items: items);
      _invalidateCategoryCache();
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Gagal memperbarui kategori: $error',
      );
      rethrow;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> deleteCategory(int id) async {
    final busy = {...state.busyCategoryIds, id};
    state = state.copyWith(busyCategoryIds: busy, clearError: true);
    try {
      await _repository.deleteCategory(id);
      state = state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
      );
      _invalidateCategoryCache();
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Tidak dapat menghapus kategori: $error',
      );
      rethrow;
    } finally {
      final updatedBusy = {...state.busyCategoryIds}..remove(id);
      state = state.copyWith(busyCategoryIds: updatedBusy);
    }
  }

  Future<void> toggleCategory(CategoryModel category, bool isActive) async {
    final busy = {...state.busyCategoryIds, category.id};
    state = state.copyWith(busyCategoryIds: busy, clearError: true);
    try {
      final payload = CategoryPayload(
        name: category.name,
        description: category.description,
        isActive: isActive,
      );
      final updated = await _repository.updateCategory(category.id, payload);
      final items = state.items
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      state = state.copyWith(items: items);
      _invalidateCategoryCache();
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Tidak dapat memperbarui status: $error',
      );
      rethrow;
    } finally {
      final updatedBusy = {...state.busyCategoryIds}..remove(category.id);
      state = state.copyWith(busyCategoryIds: updatedBusy);
    }
  }

  void _invalidateCategoryCache() {
    _ref.invalidate(categoryListProvider);
  }
}

final categoryManagementProvider =
    StateNotifierProvider.autoDispose<
      CategoryManagementNotifier,
      CategoryManagementState
    >((ref) {
      final repository = ref.watch(categoryRepositoryProvider);
      return CategoryManagementNotifier(ref, repository);
    });
