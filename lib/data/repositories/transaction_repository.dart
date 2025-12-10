import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/receipt_summary.dart';
import '../models/transaction_payload.dart';
import '../models/transaction_history_model.dart';
import '../services/api_client.dart';

class TransactionRepository {
  TransactionRepository(this._dio);

  final Dio _dio;

  Future<ReceiptSummary> submit(TransactionPayload payload) async {
    final fallback = ReceiptSummary.fromPayload(payload);
    final response = await _dio.post<Map<String, dynamic>>(
      '/transactions',
      data: payload.toJson(),
    );
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      return ReceiptSummary.fromApi(
        data,
        fallbackLocalId: payload.localId,
        fallbackPaymentMethod: payload.paymentMethod,
        fallbackItems: fallback.items,
        fallbackTotal: fallback.total,
        fallbackCashReceived: fallback.cashReceived,
      );
    }
    return fallback;
  }

  Future<void> submitJson(Map<String, dynamic> json) async {
    await _dio.post('/transactions', data: json);
  }

  Future<TransactionHistoryResponse> fetchHistory({
    int page = 1,
    String? date,
    String? paymentMethod,
  }) async {
    final query = <String, dynamic>{'page': page};
    if (date != null && date.isNotEmpty) {
      query['date'] = date;
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      query['payment_method'] = paymentMethod;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/transactions',
      queryParameters: query,
    );
    final data = response.data ?? <String, dynamic>{};
    return TransactionHistoryResponse.fromJson(data);
  }

  Future<TransactionTodaySummary> fetchTodaySummary() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/transactions/summary/today',
    );
    final data = response.data ?? <String, dynamic>{};
    return TransactionTodaySummary.fromJson(data);
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return TransactionRepository(dio);
});
