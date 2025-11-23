import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/category_model.dart';
import '../data/repositories/category_repository.dart';

final categoryListProvider = FutureProvider.autoDispose<List<CategoryModel>>((
  ref,
) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.fetchAll();
});
