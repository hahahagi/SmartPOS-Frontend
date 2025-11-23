import 'cart_item_model.dart';

enum PaymentMethod { cash, qris, debit }

class TransactionPayload {
  const TransactionPayload({
    required this.localId,
    required this.items,
    required this.paymentMethod,
    this.cashReceived,
  });

  final String localId;
  final List<CartItemModel> items;
  final PaymentMethod paymentMethod;
  final double? cashReceived;

  double get total =>
      items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  double get cashAmount =>
      paymentMethod == PaymentMethod.cash ? (cashReceived ?? 0) : total;

  double get changeAmount {
    if (paymentMethod != PaymentMethod.cash) {
      return 0;
    }
    final difference = (cashReceived ?? 0) - total;
    return difference <= 0 ? 0 : difference;
  }

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'payment_method': paymentMethod.name,
    'cash_received': cashReceived,
    'total_amount': total,
    'cash_amount': cashAmount,
    'change_amount': changeAmount,
    'items': items
        .map(
          (item) => {'product_id': item.product.id, 'quantity': item.quantity},
        )
        .toList(),
  };
}
