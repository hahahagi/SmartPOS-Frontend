class StockAdjustmentResult {
  const StockAdjustmentResult({
    required this.productId,
    required this.productName,
    required this.newStock,
  });

  final int productId;
  final String productName;
  final int newStock;

  factory StockAdjustmentResult.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? const {};
    return StockAdjustmentResult(
      productId: _asInt(product['id']),
      productName: product['name'] as String? ?? '-',
      newStock: _asInt(json['new_stock']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
