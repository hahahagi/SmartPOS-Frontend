import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/category_model.dart';
import '../../../../data/models/category_payload.dart';
import '../../../../providers/admin/category_management_provider.dart';

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, this.initial});

  final CategoryModel? initial;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActive = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final category = widget.initial;
    if (category != null) {
      _nameController.text = category.name;
      _descriptionController.text = category.description ?? '';
      _isActive = category.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final payload = CategoryPayload(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: _isActive,
    );
    final notifier = ref.read(categoryManagementProvider.notifier);
    setState(() => _errorMessage = null);
    try {
      if (widget.initial == null) {
        await notifier.createCategory(payload);
      } else {
        await notifier.updateCategory(widget.initial!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() => _errorMessage = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryManagementProvider);
    final isSaving = state.isSaving;

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
                    widget.initial == null
                        ? 'Tambah Kategori'
                        : 'Ubah Kategori',
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
                decoration: const InputDecoration(labelText: 'Nama kategori'),
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
                title: const Text('Kategori aktif'),
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
