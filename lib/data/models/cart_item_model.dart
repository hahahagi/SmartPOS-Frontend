import 'product_model.dart';

class CartItemModel {
  CartItemModel({required this.product, this.quantity = 1});

  final ProductModel product;
  int quantity;

  double get subtotal => product.price * quantity;

  void increment() => quantity++;

  void decrement() {
    if (quantity > 1) quantity--;
  }
}
