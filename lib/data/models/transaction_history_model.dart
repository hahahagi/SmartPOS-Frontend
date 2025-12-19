class TransactionHistoryResponse {
  const TransactionHistoryResponse({required this.items, required this.meta});

  final List<TransactionHistoryItem> items;
  final TransactionHistoryMeta meta;

  factory TransactionHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? const [];
    final metaJson = json['meta'] as Map<String, dynamic>? ?? const {};
    return TransactionHistoryResponse(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(TransactionHistoryItem.fromJson)
          .toList(),
      meta: TransactionHistoryMeta.fromJson(metaJson),
    );
  }
}

class TransactionHistoryMeta {
  const TransactionHistoryMeta({
    required this.currentPage,
    required this.total,
    required this.perPage,
  });

  final int currentPage;
  final int total;
  final int perPage;

  factory TransactionHistoryMeta.fromJson(Map<String, dynamic> json) {
    return TransactionHistoryMeta(
      currentPage: json['current_page'] as int? ?? 1,
      total: json['total'] as int? ?? 0,
      perPage: json['per_page'] as int? ?? 10,
    );
  }

  bool get hasMore => currentPage * perPage < total;
}

class TransactionHistoryItem {
  TransactionHistoryItem({
    required this.id,
    required this.code,
    required this.totalAmount,
    required this.paymentMethod,
    required this.cashReceived,
    required this.changeAmount,
    required this.createdAt,
    required this.cashierName,
    required this.items,
  });

  final int id;
  final String code;
  final double totalAmount;
  final String paymentMethod;

  /// 🔥 TAMBAHAN REVISI DOSEN
  final double cashReceived;
  final double changeAmount;

  final DateTime createdAt;
  final String cashierName;
  final List<TransactionLineItem> items;

  int get itemsCount => items.length;

  bool get isCash => paymentMethod.toLowerCase() == 'cash';

  factory TransactionHistoryItem.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return TransactionHistoryItem(
      id: json['id'] as int? ?? 0,
      code: json['transaction_code'] as String? ?? '-',
      totalAmount: _asDouble(json['total_amount']),
      paymentMethod: json['payment_method'] as String? ?? '-',

      /// 🔥 parsing kembalian & uang diterima
      cashReceived: _asDouble(json['cash_amount']),
      changeAmount: _asDouble(json['change_amount']),

      createdAt: _parseDate(json['created_  at']),
      cashierName:
          (json['user'] as Map<String, dynamic>?)?['name'] as String? ?? '-',
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(TransactionLineItem.fromJson)
          .toList(),
    );
  }
}

class TransactionLineItem {
  const TransactionLineItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final int id;
  final String productName;
  final int quantity;
  final double unitPrice;

  double get totalPrice => unitPrice * quantity;

  factory TransactionLineItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return TransactionLineItem(
      id: json['id'] as int? ?? 0,
      productName: product?['name'] as String? ?? '-',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: _asDouble(json['unit_price'] ?? product?['sell_price']),
    );
  }
}

class TransactionTodaySummary {
  const TransactionTodaySummary({
    required this.totalTransactions,
    required this.totalAmount,
  });

  final int totalTransactions;
  final double totalAmount;

  factory TransactionTodaySummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? const {};
    return TransactionTodaySummary(
      totalTransactions: summary['total_transactions'] as int? ?? 0,
      totalAmount: _asDouble(summary['total_amount']),
    );
  }

  static const empty = TransactionTodaySummary(
    totalTransactions: 0,
    totalAmount: 0,
  );
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
  }
  return DateTime.now();
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
