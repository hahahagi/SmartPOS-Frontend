import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/category_model.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/product_payload.dart';
import '../../../../providers/admin/product_management_provider.dart';
import '../../../../providers/category_provider.dart';

class ProductFormSheet extends ConsumerStatefulWidget {
  const ProductFormSheet({super.key, this.initial});

  final ProductModel? initial;

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _decimalFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9.,]'),
  );

  int? _selectedCategoryId;
  bool _isActive = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final product = widget.initial;
    if (product != null) {
      _nameController.text = product.name;
      _barcodeController.text = product.barcode;
      _buyPriceController.text = (product.buyPrice ?? 0).toStringAsFixed(0);
      _sellPriceController.text = product.sellPrice.toStringAsFixed(0);
      _stockController.text = product.stock.toString();
      _descriptionController.text = product.description ?? '';
      _selectedCategoryId = product.categoryId;
      _isActive = product.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double _parseDouble(String value) {
    final normalized = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  int _parseInt(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  Future<void> _handleSubmit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final payload = ProductPayload(
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim(),
      buyPrice: _parseDouble(_buyPriceController.text.trim()),
      sellPrice: _parseDouble(_sellPriceController.text.trim()),
      stock: _parseInt(_stockController.text.trim()),
      categoryId: _selectedCategoryId!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: _isActive,
    );
    setState(() => _errorMessage = null);
    final notifier = ref.read(productManagementProvider.notifier);
    try {
      if (widget.initial == null) {
        await notifier.createProduct(payload);
      } else {
        await notifier.updateProduct(widget.initial!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() => _errorMessage = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final managementState = ref.watch(productManagementProvider);
    final isSaving = managementState.isSaving;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.initial == null ? 'Tambah Produk' : 'Ubah Produk',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama produk'),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(labelText: 'Barcode'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Barcode wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _CategoryDropdown(
                categoriesAsync: categoriesAsync,
                selectedId: _selectedCategoryId,
                onChanged: (value) => setState(() {
                  _selectedCategoryId = value;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _buyPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_decimalFormatter],
                decoration: const InputDecoration(labelText: 'Harga beli'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Harga beli wajib diisi';
                  }
                  if (_parseDouble(value) <= 0) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sellPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_decimalFormatter],
                decoration: const InputDecoration(labelText: 'Harga jual'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Harga jual wajib diisi';
                  }
                  if (_parseDouble(value) <= 0) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Stok awal'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Stok wajib diisi';
                  }
                  if (_parseInt(value) < 0) {
                    return 'Angka tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Produk aktif'),
                subtitle: const Text(
                  'Nonaktifkan jika produk tidak boleh dijual',
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
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
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.initial == null ? 'Simpan' : 'Perbarui'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categoriesAsync,
    required this.selectedId,
    required this.onChanged,
  });

  final AsyncValue<List<CategoryModel>> categoriesAsync;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return categoriesAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Text('Belum ada kategori aktif.');
        }
        final validValue = items.any((item) => item.id == selectedId)
            ? selectedId
            : null;
        return DropdownButtonFormField<int>(
          value: validValue,
          decoration: const InputDecoration(labelText: 'Kategori'),
          items: items
              .map(
                (category) => DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (value) => value == null ? 'Pilih kategori' : null,
        );
      },
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (error, _) => Text(
        'Kategori gagal dimuat: $error',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.red),
      ),
    );
  }
}
