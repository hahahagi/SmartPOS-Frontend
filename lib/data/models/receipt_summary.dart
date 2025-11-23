import 'transaction_payload.dart';

class ReceiptItemSummary {
  const ReceiptItemSummary({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  final String productName;
  final int quantity;
  final double price;

  double get subtotal => price * quantity;

  factory ReceiptItemSummary.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return ReceiptItemSummary(
      productName:
          product?['name'] as String? ?? json['product_name'] as String? ?? '-',
      quantity: json['quantity'] as int? ?? 0,
      price: _asDouble(json['unit_price'] ?? json['price']),
    );
  }
}

class ReceiptSummary {
  const ReceiptSummary({
    required this.localId,
    this.remoteId,
    this.invoiceCode,
    required this.createdAt,
    required this.paymentMethod,
    required this.items,
    required this.total,
    this.cashReceived,
    this.changeAmount,
  });

  final String localId;
  final int? remoteId;
  final String? invoiceCode;
  final DateTime createdAt;
  final PaymentMethod paymentMethod;
  final List<ReceiptItemSummary> items;
  final double total;
  final double? cashReceived;
  final double? changeAmount;

  double get change {
    if (changeAmount != null) {
      return changeAmount!.clamp(0, double.infinity);
    }
    if (cashReceived != null) {
      return (cashReceived! - total).clamp(0, double.infinity);
    }
    return 0;
  }

  factory ReceiptSummary.fromPayload(TransactionPayload payload) {
    final summaries = payload.items
        .map(
          (item) => ReceiptItemSummary(
            productName: item.product.name,
            quantity: item.quantity,
            price: item.product.price,
          ),
        )
        .toList();

    return ReceiptSummary(
      localId: payload.localId,
      createdAt: DateTime.now(),
      paymentMethod: payload.paymentMethod,
      items: summaries,
      total: payload.total,
      cashReceived: payload.cashReceived,
    );
  }

  factory ReceiptSummary.fromApi(
    Map<String, dynamic> json, {
    required String fallbackLocalId,
    required PaymentMethod fallbackPaymentMethod,
    List<ReceiptItemSummary>? fallbackItems,
    double? fallbackTotal,
    double? fallbackCashReceived,
  }) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    final parsedItems = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(ReceiptItemSummary.fromJson)
        .toList();
    return ReceiptSummary(
      localId: fallbackLocalId,
      remoteId: json['id'] as int?,
      invoiceCode: json['transaction_code'] as String?,
      createdAt: _parseDate(json['created_at']),
      paymentMethod: _parsePaymentMethod(
        json['payment_method'] as String?,
        fallbackPaymentMethod,
      ),
      items: parsedItems.isNotEmpty ? parsedItems : (fallbackItems ?? const []),
      total: json['total_amount'] == null
          ? (fallbackTotal ?? 0)
          : _asDouble(json['total_amount']),
      cashReceived: json['cash_amount'] == null
          ? fallbackCashReceived
          : _asDouble(json['cash_amount']),
      changeAmount: json['change_amount'] == null
          ? null
          : _asDouble(json['change_amount']),
    );
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime _parseDate(dynamic value) {
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
  }
  if (value is DateTime) return value.toLocal();
  return DateTime.now();
}

PaymentMethod _parsePaymentMethod(String? value, PaymentMethod fallback) {
  if (value == null) return fallback;
  final normalized = value.toLowerCase();
  for (final method in PaymentMethod.values) {
    if (method.name.toLowerCase() == normalized) {
      return method;
    }
  }
  return fallback;
}
