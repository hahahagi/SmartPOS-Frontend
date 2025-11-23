import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/transaction_payload.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../utils/formatters.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/payment_method_tile.dart';
import '../receipt/receipt_page.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  static const String routeName = 'payment';
  static const String routePath = '/payment';

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  PaymentMethod _method = PaymentMethod.cash;
  final TextEditingController _cashController = TextEditingController();

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final transactionState = ref.watch(transactionProvider);

    final total = cart.total;
    final cashReceived = double.tryParse(_cashController.text);
    final change = (cashReceived ?? 0) - total;

    ref.listen(transactionProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      } else if (previous?.isSubmitting == true &&
          next.isSubmitting == false &&
          next.errorMessage == null) {
        context.go(ReceiptPage.routePath);
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Pembayaran',
        showBackButton: true,
        showLogoutButton: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Belanja',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    formatCurrency(total),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pilih Metode Pembayaran',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: PaymentMethod.values.map((method) {
                      final config = _methodConfig(method);
                      return PaymentMethodTile(
                        icon: config.icon,
                        label: config.label,
                        subtitle: config.subtitle,
                        selected: method == _method,
                        onTap: () => setState(() => _method = method),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  if (_method == PaymentMethod.cash) ...[
                    Text(
                      'Uang Diterima',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cashController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        hintText: 'Masukkan nominal cash',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    if (cashReceived != null)
                      Text(
                        change >= 0
                            ? 'Kembalian: ${formatCurrency(change)}'
                            : 'Kurang: ${formatCurrency(change.abs())}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: change >= 0
                                  ? Colors.green
                                  : Colors.redAccent,
                            ),
                      ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: transactionState.isSubmitting
                          ? null
                          : () => _submit(total),
                      child: transactionState.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Konfirmasi Pembayaran'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  _MethodConfig _methodConfig(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return const _MethodConfig(
          icon: Icons.payments_outlined,
          label: 'Cash',
          subtitle: 'Masukkan nominal',
        );
      case PaymentMethod.qris:
        return const _MethodConfig(
          icon: Icons.qr_code,
          label: 'QRIS',
          subtitle: 'Scan QR customer',
        );
      case PaymentMethod.debit:
        return const _MethodConfig(
          icon: Icons.credit_card,
          label: 'Debit',
          subtitle: 'Gunakan mesin EDC',
        );
    }
  }

  Future<void> _submit(double total) async {
    double? cashReceived;
    if (_method == PaymentMethod.cash) {
      cashReceived = double.tryParse(_cashController.text);
      if (cashReceived == null || cashReceived < total) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('Cash belum mencukupi')));
        return;
      }
    }

    await ref
        .read(transactionProvider.notifier)
        .submit(_method, cashReceived: cashReceived);
  }
}

class _MethodConfig {
  const _MethodConfig({required this.icon, required this.label, this.subtitle});

  final IconData icon;
  final String label;
  final String? subtitle;
}
