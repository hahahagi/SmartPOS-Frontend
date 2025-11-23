import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/colors.dart';
import '../../../data/exceptions/app_exception.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/cart_item_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../payment/payment_page.dart';
import '../scanner/scanner_page.dart';

class StartTransactionPage extends ConsumerStatefulWidget {
  const StartTransactionPage({super.key});

  static const String routeName = 'startTransaction';
  static const String routePath = '/transaction/start';

  @override
  ConsumerState<StartTransactionPage> createState() =>
      _StartTransactionPageState();
}

class _StartTransactionPageState extends ConsumerState<StartTransactionPage> {
  final _barcodeController = TextEditingController();
  final _barcodeFocusNode = FocusNode();
  String? _lastLookup;
  ProviderSubscription<AsyncValue<ProductModel?>>? _barcodeSubscription;

  @override
  void initState() {
    super.initState();
    _barcodeSubscription = ref.listenManual<AsyncValue<ProductModel?>>(
      productBarcodeProvider,
      (previous, next) {
        next.whenOrNull(
          data: (product) {
            if (product != null) {
              _barcodeController.clear();
              _lastLookup = null;
            }
          },
          error: (error, _) => _handleLookupError(error),
        );
      },
    );
  }

  @override
  void dispose() {
    _barcodeSubscription?.close();
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final barcodeAsync = ref.watch(productBarcodeProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Transaksi Baru',
        subtitle:
            'Item: ${cart.totalItems} · Total: Rp ${cart.total.toStringAsFixed(0)}',
        showLogoutButton: false,
        showBackButton: true,
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: cart.items.isEmpty
                ? null
                : () => context.push(PaymentPage.routePath),
            child: const Text('Bayar'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _barcodeController,
                        focusNode: _barcodeFocusNode,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Masukkan / scan barcode',
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        onSubmitted: _lookupBarcode,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await context.push<String>(
                          ScannerPage.routePath,
                        );
                        if (result != null && result.isNotEmpty) {
                          _lookupBarcode(result);
                        }
                      },
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Scan'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                barcodeAsync.when(
                  data: (product) {
                    if (product == null) return const SizedBox();
                    return ListTile(
                      tileColor: AppColors.lightGray.withOpacity(.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(product.name),
                      subtitle: Text('Rp ${product.price.toStringAsFixed(0)}'),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.primaryBlue,
                        ),
                        onPressed: () =>
                            ref.read(cartProvider.notifier).addProduct(product),
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (err, _) => _LookupErrorMessage(
                    message: _errorMessage(err),
                    onRetry: _lastLookup == null
                        ? null
                        : () => _lookupBarcode(_lastLookup!),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: cart.items.isEmpty
                      ? const Center(child: Text('Keranjang kosong'))
                      : ListView.separated(
                          itemCount: cart.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = cart.items[index];
                            return CartItemWidget(
                              item: item,
                              onIncrement: () => ref
                                  .read(cartProvider.notifier)
                                  .incrementItem(item.product.id),
                              onDecrement: () => ref
                                  .read(cartProvider.notifier)
                                  .decrementItem(item.product.id),
                              onRemove: () => ref
                                  .read(cartProvider.notifier)
                                  .removeItem(item.product.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _CheckoutSummary(
              totalItems: cart.totalItems,
              totalAmount: cart.total,
              disabled: cart.items.isEmpty,
              onCheckout: () => context.push(PaymentPage.routePath),
            ),
          ),
        ],
      ),
    );
  }

  void _lookupBarcode(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _lastLookup = trimmed;
    ref.read(productBarcodeProvider.notifier).lookup(trimmed);
  }

  void _handleLookupError(Object error) {
    final message = _errorMessage(error);
    if (!mounted) return;
    if (error is BarcodeNotFoundException) {
      _showBarcodeNotFoundDialog(message);
    } else {
      _showErrorSnackBar(message);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _showBarcodeNotFoundDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Produk tidak ditemukan'),
        content: Text('$message\nInput manual barcode atau nama produk?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _barcodeFocusNode.requestFocus();
              _barcodeController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _barcodeController.text.length,
              );
            },
            child: const Text('Input Manual'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _barcodeController.clear();
              _barcodeFocusNode.requestFocus();
            },
            child: const Text('Scan Ulang'),
          ),
        ],
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is AppException) return error.message;
    if (error is DioException) {
      return error.message ?? 'Terjadi kesalahan, coba beberapa saat lagi.';
    }
    return 'Terjadi kesalahan, coba beberapa saat lagi.';
  }
}

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary({
    required this.totalItems,
    required this.totalAmount,
    required this.disabled,
    required this.onCheckout,
  });

  final int totalItems;
  final double totalAmount;
  final bool disabled;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Item',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      '$totalItems pcs',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Belanja',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      'Rp ${totalAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: disabled ? null : onCheckout,
                icon: const Icon(Icons.point_of_sale),
                label: const Text('Lanjut ke Pembayaran'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LookupErrorMessage extends StatelessWidget {
  const _LookupErrorMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red.shade700),
            ),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
        ],
      ),
    );
  }
}
