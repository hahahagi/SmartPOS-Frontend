class StockAdjustmentPayload {
  const StockAdjustmentPayload({
    required this.productId,
    required this.quantity,
    required this.description,
  });

  final int productId;
  final int quantity;
  final String description;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity': quantity,
    'description': description,
  };
}
