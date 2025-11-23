import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/receipt_summary.dart';
import '../../../providers/transaction_provider.dart';
import '../../../utils/formatters.dart';

class ReceiptPage extends ConsumerWidget {
  const ReceiptPage({super.key});

  static const String routeName = 'receipt';
  static const String routePath = '/receipt';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionProvider);
    final receipt = transactionState.lastReceipt;

    return Scaffold(
      appBar: AppBar(title: const Text('Struk Transaksi')),
      body: receipt == null
          ? const Center(child: Text('Belum ada transaksi terbaru.'))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReceiptHeader(receipt: receipt),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: receipt.items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = receipt.items[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.productName),
                          subtitle: Text(
                            '${item.quantity} x ${formatCurrency(item.price)}',
                          ),
                          trailing: Text(formatCurrency(item.subtotal)),
                        );
                      },
                    ),
                  ),
                  const Divider(thickness: 1.5),
                  _ReceiptSummary(receipt: receipt),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Selesai'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ReceiptHeader extends StatelessWidget {
  const _ReceiptHeader({required this.receipt});

  final ReceiptSummary receipt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invoice ${_displayCode(receipt).toUpperCase()}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          formatDateTime(receipt.createdAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          'Metode: ${receipt.paymentMethod.name.toUpperCase()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (receipt.invoiceCode == null)
          Text(
            'Menunggu sinkronisasi server',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.orange.shade700),
          ),
      ],
    );
  }
}

String _displayCode(ReceiptSummary receipt) {
  if (receipt.invoiceCode != null && receipt.invoiceCode!.isNotEmpty) {
    return receipt.invoiceCode!;
  }
  if (receipt.localId.length <= 8) {
    return receipt.localId;
  }
  return receipt.localId.substring(0, 8);
}

class _ReceiptSummary extends StatelessWidget {
  const _ReceiptSummary({required this.receipt});

  final ReceiptSummary receipt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [const Text('Total'), Text(formatCurrency(receipt.total))],
        ),
        if (receipt.cashReceived != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cash Diterima'),
              Text(formatCurrency(receipt.cashReceived!)),
            ],
          ),
          if (receipt.change > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembalian'),
                Text(formatCurrency(receipt.change)),
              ],
            ),
        ],
      ],
    );
  }
}
