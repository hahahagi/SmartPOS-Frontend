import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/transaction_history_model.dart';
import '../data/repositories/transaction_repository.dart';

class TransactionHistoryState {
  const TransactionHistoryState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.page = 1,
    this.hasMore = true,
    this.selectedDate,
    this.paymentMethod,
    this.meta,
  });

  final List<TransactionHistoryItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int page;
  final bool hasMore;
  final DateTime? selectedDate;
  final String? paymentMethod;
  final TransactionHistoryMeta? meta;

  TransactionHistoryState copyWith({
    List<TransactionHistoryItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    int? page,
    bool? hasMore,
    DateTime? selectedDate,
    bool clearDate = false,
    String? paymentMethod,
    bool clearPaymentMethod = false,
    TransactionHistoryMeta? meta,
  }) {
    return TransactionHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
      paymentMethod: clearPaymentMethod
          ? null
          : (paymentMethod ?? this.paymentMethod),
      meta: meta ?? this.meta,
    );
  }
}

class TransactionHistoryNotifier
    extends StateNotifier<TransactionHistoryState> {
  TransactionHistoryNotifier(this._repository)
    : super(const TransactionHistoryState()) {
    loadInitial();
  }

  final TransactionRepository _repository;
  final _dateFormatter = DateFormat('yyyy-MM-dd');

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, page: 1, clearError: true);
    try {
      final response = await _repository.fetchHistory(
        page: 1,
        date: state.selectedDate != null
            ? _dateFormatter.format(state.selectedDate!)
            : null,
        paymentMethod: state.paymentMethod,
      );
      state = state.copyWith(
        isLoading: false,
        items: response.items,
        page: 1,
        hasMore: response.meta.hasMore,
        meta: response.meta,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Tidak bisa memuat riwayat: $error',
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
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.page + 1;
    try {
      final response = await _repository.fetchHistory(
        page: nextPage,
        date: state.selectedDate != null
            ? _dateFormatter.format(state.selectedDate!)
            : null,
        paymentMethod: state.paymentMethod,
      );
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...response.items],
        page: nextPage,
        hasMore: response.meta.hasMore,
        meta: response.meta,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Tidak bisa memuat halaman berikutnya: $error',
      );
    }
  }

  Future<void> setDate(DateTime? date) async {
    state = state.copyWith(selectedDate: date, page: 1);
    await loadInitial();
  }

  Future<void> setPaymentMethod(String? method) async {
    state = state.copyWith(paymentMethod: method, page: 1);
    await loadInitial();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(clearDate: true, clearPaymentMethod: true);
    await loadInitial();
  }
}

final transactionHistoryProvider =
    StateNotifierProvider.autoDispose<
      TransactionHistoryNotifier,
      TransactionHistoryState
    >((ref) {
      final repository = ref.watch(transactionRepositoryProvider);
      return TransactionHistoryNotifier(repository);
    });

class TransactionTodaySummaryNotifier
    extends AutoDisposeAsyncNotifier<TransactionTodaySummary> {
  @override
  Future<TransactionTodaySummary> build() async {
    return _fetch();
  }

  Future<TransactionTodaySummary> _fetch() async {
    final repo = ref.read(transactionRepositoryProvider);
    return repo.fetchTodaySummary();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final transactionTodaySummaryProvider =
    AutoDisposeAsyncNotifierProvider<
      TransactionTodaySummaryNotifier,
      TransactionTodaySummary
    >(TransactionTodaySummaryNotifier.new);
