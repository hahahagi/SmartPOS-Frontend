import 'pagination_meta.dart';
import 'product_model.dart';

class ProductListResponse {
  const ProductListResponse({required this.items, required this.meta});

  final List<ProductModel> items;
  final PaginationMeta meta;

  bool get hasMore => meta.hasMore;

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? const [];
    final metaJson = json['meta'] as Map<String, dynamic>? ?? const {};
    return ProductListResponse(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList(),
      meta: PaginationMeta.fromJson(metaJson),
    );
  }
}
