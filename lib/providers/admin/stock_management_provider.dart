import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/pagination_meta.dart';
import '../../data/models/product_model.dart';
import '../../data/models/stock_adjustment_payload.dart';
import '../../data/models/stock_adjustment_result.dart';
import '../../data/models/stock_log_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/stock_repository.dart';

class StockManagementState {
  const StockManagementState({
    this.logs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.errorMessage,
    this.selectedProductId,
    this.selectedType,
    this.selectedDate,
    this.meta,
    this.isSubmitting = false,
  });

  final List<StockLogModel> logs;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? errorMessage;
  final int? selectedProductId;
  final String? selectedType;
  final DateTime? selectedDate;
  final PaginationMeta? meta;
  final bool isSubmitting;

  StockManagementState copyWith({
    List<StockLogModel>? logs,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? errorMessage,
    bool clearError = false,
    int? selectedProductId,
    bool clearProduct = false,
    String? selectedType,
    bool clearType = false,
    DateTime? selectedDate,
    bool clearDate = false,
    PaginationMeta? meta,
    bool? isSubmitting,
  }) {
    return StockManagementState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedProductId: clearProduct
          ? null
          : (selectedProductId ?? this.selectedProductId),
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
      meta: meta ?? this.meta,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class StockManagementNotifier extends StateNotifier<StockManagementState> {
  StockManagementNotifier(this._repository)
    : super(const StockManagementState()) {
    loadLogs();
  }

  final StockRepository _repository;
  static const _perPage = 15;
  final _dateFormatter = DateFormat('yyyy-MM-dd');

  Future<void> loadLogs() async {
    state = state.copyWith(
      isLoading: true,
      page: 1,
      hasMore: true,
      clearError: true,
    );
    try {
      final response = await _repository.fetchLogs(
        page: 1,
        perPage: _perPage,
        productId: state.selectedProductId,
        type: state.selectedType,
        date: state.selectedDate != null
            ? _dateFormatter.format(state.selectedDate!)
            : null,
      );
      state = state.copyWith(
        isLoading: false,
        logs: response.items,
        hasMore: response.hasMore,
        page: 1,
        meta: response.meta,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Tidak bisa memuat log stok: $error',
      );
    }
  }

  Future<void> refresh() async => loadLogs();

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final response = await _repository.fetchLogs(
        page: nextPage,
        perPage: _perPage,
        productId: state.selectedProductId,
        type: state.selectedType,
        date: state.selectedDate != null
            ? _dateFormatter.format(state.selectedDate!)
            : null,
      );
      state = state.copyWith(
        isLoadingMore: false,
        logs: [...state.logs, ...response.items],
        hasMore: response.hasMore,
        page: nextPage,
        meta: response.meta,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Tidak bisa memuat log berikutnya: $error',
      );
    }
  }

  Future<void> setProduct(int? productId) async {
    state = state.copyWith(selectedProductId: productId, page: 1);
    await loadLogs();
  }

  Future<void> setType(String? type) async {
    state = state.copyWith(selectedType: type, page: 1);
    await loadLogs();
  }

  Future<void> setDate(DateTime? date) async {
    state = state.copyWith(selectedDate: date, page: 1);
    await loadLogs();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      clearProduct: true,
      clearType: true,
      clearDate: true,
    );
    await loadLogs();
  }

  Future<StockAdjustmentResult> submitStockIn(
    StockAdjustmentPayload payload,
  ) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await _repository.stockIn(payload);
      await loadLogs();
      return result;
    } catch (error) {
      state = state.copyWith(errorMessage: 'Gagal menambah stok: $error');
      rethrow;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<StockAdjustmentResult> submitStockOut(
    StockAdjustmentPayload payload,
  ) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await _repository.stockOut(payload);
      await loadLogs();
      return result;
    } catch (error) {
      state = state.copyWith(errorMessage: 'Gagal mengurangi stok: $error');
      rethrow;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

final stockManagementProvider =
    StateNotifierProvider.autoDispose<
      StockManagementNotifier,
      StockManagementState
    >((ref) {
      final repository = ref.watch(stockRepositoryProvider);
      return StockManagementNotifier(repository);
    });

final stockProductOptionsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
      final repository = ref.watch(productRepositoryProvider);
      final response = await repository.fetchProducts(page: 1, perPage: 100);
      return response.items;
    });
