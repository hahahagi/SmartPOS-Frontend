import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/product_model.dart';
import '../data/repositories/product_repository.dart';

class ProductSearchNotifier
    extends AutoDisposeAsyncNotifier<List<ProductModel>> {
  @override
  Future<List<ProductModel>> build() async => const [];

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).search(query),
    );
  }
}

final productSearchProvider =
    AutoDisposeAsyncNotifierProvider<ProductSearchNotifier, List<ProductModel>>(
      ProductSearchNotifier.new,
    );

class ProductBarcodeLookup extends AutoDisposeAsyncNotifier<ProductModel?> {
  @override
  Future<ProductModel?> build() async => null;

  Future<void> lookup(String barcode) async {
    if (barcode.isEmpty) {
      state = const AsyncData(null);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).getByBarcode(barcode),
    );
  }
}

final productBarcodeProvider =
    AutoDisposeAsyncNotifierProvider<ProductBarcodeLookup, ProductModel?>(
      ProductBarcodeLookup.new,
    );
