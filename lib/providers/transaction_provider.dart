import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/receipt_summary.dart';
import '../data/models/transaction_payload.dart';
import '../data/repositories/transaction_repository.dart';
import '../providers/cart_provider.dart';
import '../providers/offline_queue_provider.dart';

class TransactionState {
  const TransactionState({
    this.isSubmitting = false,
    this.errorMessage,
    this.lastSyncedId,
    this.lastReceipt,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final String? lastSyncedId;
  final ReceiptSummary? lastReceipt;

  TransactionState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    String? lastSyncedId,
    ReceiptSummary? lastReceipt,
  }) {
    return TransactionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      lastSyncedId: lastSyncedId ?? this.lastSyncedId,
      lastReceipt: lastReceipt ?? this.lastReceipt,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  TransactionNotifier(this._repository, this._cartNotifier, this._offlineQueue)
    : super(const TransactionState());

  final TransactionRepository _repository;
  final CartNotifier _cartNotifier;
  final OfflineQueueNotifier _offlineQueue;

  Future<void> submit(PaymentMethod method, {double? cashReceived}) async {
    if (_cartNotifier.state.items.isEmpty) {
      state = state.copyWith(errorMessage: 'Keranjang kosong');
      return;
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final payload = TransactionPayload(
      localId: const Uuid().v4(),
      items: _cartNotifier.state.items,
      paymentMethod: method,
      cashReceived: cashReceived,
    );
    late final ReceiptSummary receipt;
    try {
      receipt = await _repository.submit(payload);
      _cartNotifier.clear();
      state = state.copyWith(
        isSubmitting: false,
        lastSyncedId: payload.localId,
        lastReceipt: receipt,
      );
    } catch (error) {
      receipt = ReceiptSummary.fromPayload(payload);
      await _offlineQueue.enqueue(payload);
      _cartNotifier.clear();
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            'Transaksi offline, tersimpan untuk sinkronisasi (${_offlineQueue.state.pending} antre).',
        lastReceipt: receipt,
      );
    }
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
      final repo = ref.watch(transactionRepositoryProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      final offlineQueueNotifier = ref.read(offlineQueueProvider.notifier);
      return TransactionNotifier(repo, cartNotifier, offlineQueueNotifier);
    });
