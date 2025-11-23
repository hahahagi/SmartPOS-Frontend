import 'pagination_meta.dart';

class StockLogModel {
  const StockLogModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productBarcode,
    required this.type,
    required this.quantity,
    required this.description,
    required this.userName,
    required this.createdAt,
  });

  final int id;
  final int productId;
  final String productName;
  final String productBarcode;
  final String type;
  final int quantity;
  final String description;
  final String userName;
  final DateTime createdAt;

  bool get isStockIn => type.toLowerCase() == 'in';
  bool get isStockOut => type.toLowerCase() == 'out';
  String get typeLabel => isStockIn ? 'Stok Masuk' : 'Stok Keluar';

  factory StockLogModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    return StockLogModel(
      id: _asInt(json['id']),
      productId: _asInt(json['product_id'] ?? product?['id']),
      productName: product?['name'] as String? ?? '-',
      productBarcode: product?['barcode'] as String? ?? '-',
      type: json['type'] as String? ?? '-',
      quantity: _asInt(json['quantity']),
      description: json['description'] as String? ?? '-',
      userName: user?['name'] as String? ?? '-',
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class StockLogResponse {
  const StockLogResponse({required this.items, required this.meta});

  final List<StockLogModel> items;
  final PaginationMeta meta;

  bool get hasMore => meta.hasMore;

  factory StockLogResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? const [];
    final metaJson = json['meta'] as Map<String, dynamic>? ?? const {};
    return StockLogResponse(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(StockLogModel.fromJson)
          .toList(),
      meta: PaginationMeta.fromJson(metaJson),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
  }
  return DateTime.now();
}
