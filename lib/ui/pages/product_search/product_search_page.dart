import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/colors.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/custom_app_bar.dart';

class ProductSearchPage extends ConsumerStatefulWidget {
  const ProductSearchPage({super.key});

  static const String routeName = 'productSearch';
  static const String routePath = '/products/search';

  @override
  ConsumerState<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends ConsumerState<ProductSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(productSearchProvider.notifier).search(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(productSearchProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Cari Produk Manual',
        showLogoutButton: false,
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Nama produk atau barcode',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: results.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const _EmptyState();
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = items[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryBlue,
                          child: Text(
                            product.name.isNotEmpty
                                ? product.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(product.name),
                        subtitle: Text(
                          'Rp ${product.price.toStringAsFixed(0)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            cartNotifier.addProduct(product);
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} ditambahkan'),
                                ),
                              );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(message: '$error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('Belum ada hasil pencarian'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red.shade700),
            ),
            const SizedBox(height: 8),
            const Text('Coba ulangi pencarian atau periksa koneksi'),
          ],
        ),
      ),
    );
  }
}
