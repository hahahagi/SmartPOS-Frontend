import 'product_model.dart';

class ProductPayload {
  const ProductPayload({
    required this.name,
    required this.barcode,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    required this.categoryId,
    this.description,
    this.isActive = true,
  });

  final String name;
  final String barcode;
  final double buyPrice;
  final double sellPrice;
  final int stock;
  final int categoryId;
  final String? description;
  final bool isActive;

  factory ProductPayload.fromModel(ProductModel model) {
    return ProductPayload(
      name: model.name,
      barcode: model.barcode,
      buyPrice: model.buyPrice ?? 0,
      sellPrice: model.sellPrice,
      stock: model.stock,
      categoryId: model.categoryId ?? 0,
      description: model.description,
      isActive: model.isActive,
    );
  }

  ProductPayload copyWith({
    String? name,
    String? barcode,
    double? buyPrice,
    double? sellPrice,
    int? stock,
    int? categoryId,
    String? description,
    bool? isActive,
  }) {
    return ProductPayload(
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'barcode': barcode,
    'buy_price': buyPrice,
    'sell_price': sellPrice,
    'stock': stock,
    'category_id': categoryId,
    'description': description,
    'is_active': isActive,
  };
}
