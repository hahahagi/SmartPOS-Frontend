import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../utils/hive_boxes.dart';
import '../models/product_model.dart';

class ProductCacheService {
  ProductCacheService(this._box);

  final Box<dynamic> _box;
  static const int _maxEntries = 250;

  Future<void> saveProduct(ProductModel product) async {
    await _box.put(_productKey(product.barcode), {
      'data': product.toJson(),
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    });
    await _enforceLimit();
  }

  Future<void> saveProducts(Iterable<ProductModel> products) async {
    if (products.isEmpty) return;
    final entries = <String, Map<String, dynamic>>{};
    final cachedAt = DateTime.now().millisecondsSinceEpoch;
    for (final product in products) {
      entries[_productKey(product.barcode)] = {
        'data': product.toJson(),
        'cached_at': cachedAt,
      };
    }
    await _box.putAll(entries);
    await _enforceLimit();
  }

  ProductModel? getByBarcode(String barcode) {
    final json = _extractJson(_box.get(_productKey(barcode)));
    if (json == null) return null;
    return ProductModel.fromJson(json);
  }

  List<ProductModel> searchLocally(String query) {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return const <ProductModel>[];
    final results = <ProductModel>[];
    for (final raw in _box.values) {
      final json = _extractJson(raw);
      if (json == null) continue;
      final name = (json['name'] as String? ?? '').toLowerCase();
      final barcode = (json['barcode'] as String? ?? '').toLowerCase();
      if (name.contains(keyword) || barcode.contains(keyword)) {
        results.add(ProductModel.fromJson(json));
      }
    }
    return results;
  }

  Future<void> _enforceLimit() async {
    final overflow = _box.length - _maxEntries;
    if (overflow <= 0) return;
    final entries = <_CacheEntry>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      entries.add(_CacheEntry(key, _cachedAt(raw)));
    }
    entries.sort((a, b) => a.cachedAt.compareTo(b.cachedAt));
    final keysToRemove = entries.take(overflow).map((e) => e.key).toList();
    await _box.deleteAll(keysToRemove);
  }

  Map<String, dynamic>? _extractJson(dynamic raw) {
    if (raw is Map) {
      final data = raw['data'];
      if (data is Map) {
        return data.map((key, value) => MapEntry('$key', value));
      }
    }
    return null;
  }

  int _cachedAt(dynamic raw) {
    if (raw is Map && raw['cached_at'] is int) {
      return raw['cached_at'] as int;
    }
    return 0;
  }

  String _productKey(String barcode) => 'product_$barcode';
}

class _CacheEntry {
  _CacheEntry(this.key, this.cachedAt);

  final dynamic key;
  final int cachedAt;
}

final productCacheServiceProvider = Provider<ProductCacheService>((ref) {
  final box = Hive.box<dynamic>(HiveBoxes.productCache);
  return ProductCacheService(box);
});
