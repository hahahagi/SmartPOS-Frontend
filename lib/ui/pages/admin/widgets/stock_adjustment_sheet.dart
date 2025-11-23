import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/product_model.dart';
import '../../../../data/models/stock_adjustment_payload.dart';
import '../../../../providers/admin/stock_management_provider.dart';

class StockAdjustmentSheet extends ConsumerStatefulWidget {
  const StockAdjustmentSheet({super.key, required this.isStockIn});

  final bool isStockIn;

  @override
  ConsumerState<StockAdjustmentSheet> createState() =>
      _StockAdjustmentSheetState();
}

class _StockAdjustmentSheetState extends ConsumerState<StockAdjustmentSheet> {
  final _formKey = GlobalKey<FormState>();
  ProductModel? _selectedProduct;
  final _quantityController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int _parseQuantity(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  Future<void> _handleSubmit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_selectedProduct == null) {
      setState(() => _errorMessage = 'Pilih produk terlebih dahulu');
      return;
    }
    final payload = StockAdjustmentPayload(
      productId: _selectedProduct!.id,
      quantity: _parseQuantity(_quantityController.text),
      description: _descriptionController.text.trim(),
    );
    final notifier = ref.read(stockManagementProvider.notifier);
    setState(() => _errorMessage = null);
    try {
      final result = widget.isStockIn
          ? await notifier.submitStockIn(payload)
          : await notifier.submitStockOut(payload);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error) {
      setState(() => _errorMessage = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(stockProductOptionsProvider);
    final managementState = ref.watch(stockManagementProvider);
    final isSaving = managementState.isSubmitting;
    final title = widget.isStockIn ? 'Stok Masuk' : 'Stok Keluar';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            options.when(
              data: (products) => _ProductDropdown(
                products: products,
                value: _selectedProduct,
                onChanged: (product) => setState(() {
                  _selectedProduct = product;
                }),
              ),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, _) => Text(
                'Produk gagal dimuat: $error',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Kuantitas'),
                    validator: (value) {
                      final qty = _parseQuantity(value ?? '0');
                      if (qty <= 0) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Catatan'),
                    minLines: 2,
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Catatan wajib diisi';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSaving ? null : _handleSubmit,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isStockIn ? 'Simpan' : 'Keluarkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDropdown extends StatefulWidget {
  const _ProductDropdown({
    required this.products,
    required this.value,
    required this.onChanged,
  });

  final List<ProductModel> products;
  final ProductModel? value;
  final ValueChanged<ProductModel?> onChanged;

  @override
  State<_ProductDropdown> createState() => _ProductDropdownState();
}

class _ProductDropdownState extends State<_ProductDropdown> {
  late List<ProductModel> _filtered;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.products;
    _searchController.addListener(_filterProducts);
  }

  @override
  void didUpdateWidget(covariant _ProductDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products) {
      _filtered = widget.products;
      _filterProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      if (keyword.isEmpty) {
        _filtered = widget.products;
      } else {
        _filtered = widget.products
            .where(
              (product) =>
                  product.name.toLowerCase().contains(keyword) ||
                  product.barcode.toLowerCase().contains(keyword),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Cari produk',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Pilih produk',
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProductModel>(
              isExpanded: true,
              value: widget.value,
              items: _filtered
                  .map(
                    (product) => DropdownMenuItem<ProductModel>(
                      value: product,
                      child: Text('${product.name} • ${product.barcode}'),
                    ),
                  )
                  .toList(),
              onChanged: widget.onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
