class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.sellPrice,
    required this.stock,
    this.description,
    this.buyPrice,
    this.categoryId,
    this.categoryName,
    this.isActive = true,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String barcode;
  final double sellPrice;
  final int stock;
  final String? description;
  final double? buyPrice;
  final int? categoryId;
  final String? categoryName;
  final bool isActive;
  final String? imageUrl;

  double get price => sellPrice;

  ProductModel copyWith({
    int? id,
    String? name,
    String? barcode,
    double? sellPrice,
    int? stock,
    String? description,
    double? buyPrice,
    int? categoryId,
    String? categoryName,
    bool? isActive,
    String? imageUrl,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      buyPrice: buyPrice ?? this.buyPrice,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final rawCategoryId = json['category_id'] ?? category?['id'];
    final sellPrice = _asDouble(json['sell_price'] ?? json['price']);
    return ProductModel(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      sellPrice: sellPrice,
      stock: _asInt(json['stock']),
      description: json['description'] as String?,
      buyPrice: _asNullableDouble(json['buy_price']),
      categoryId: _asNullableInt(rawCategoryId),
      categoryName: category?['name'] as String?,
      isActive: _asBool(json['is_active'], defaultValue: true),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'barcode': barcode,
    'sell_price': sellPrice,
    'buy_price': buyPrice,
    'stock': stock,
    'description': description,
    'category_id': categoryId,
    'category_name': categoryName,
    'is_active': isActive,
    'image_url': imageUrl,
  };
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String && value.isNotEmpty) return double.tryParse(value);
  return null;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String && value.isNotEmpty) return int.tryParse(value);
  return null;
}

bool _asBool(dynamic value, {bool defaultValue = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
    final parsed = int.tryParse(lower);
    if (parsed != null) return parsed != 0;
  }
  return defaultValue;
}
