import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';

class CartState {
  const CartState({this.items = const []});

  final List<CartItemModel> items;

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({List<CartItemModel>? items}) =>
      CartState(items: items ?? this.items);
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addProduct(ProductModel product) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex != -1) {
      state.items[existingIndex].increment();
    } else {
      state = CartState(
        items: [
          ...state.items,
          CartItemModel(product: product),
        ],
      );
    }
    state = CartState(items: List<CartItemModel>.from(state.items));
  }

  void incrementItem(int productId) {
    final index = state.items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index == -1) return;
    state.items[index].increment();
    state = CartState(items: List<CartItemModel>.from(state.items));
  }

  void decrementItem(int productId) {
    final index = state.items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index == -1) return;
    state.items[index].decrement();
    state = CartState(items: List<CartItemModel>.from(state.items));
  }

  void removeItem(int productId) {
    state.items.removeWhere((item) => item.product.id == productId);
    state = CartState(items: List<CartItemModel>.from(state.items));
  }

  void clear() => state = const CartState();
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);
