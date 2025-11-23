import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/transaction_history_model.dart';
import '../../../providers/transaction_history_provider.dart';
import '../../../utils/formatters.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  static const String routeName = 'history';
  static const String routePath = '/history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionHistoryProvider);
    final notifier = ref.read(transactionHistoryProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: Column(
        children: [
          _FilterBar(state: state, notifier: notifier),
          if (state.meta != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total ${state.meta!.total} transaksi terdata',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: notifier.refresh,
              child: _HistoryList(state: state, notifier: notifier),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state, required this.notifier});

  final TransactionHistoryState state;
  final TransactionHistoryNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final dateLabel = state.selectedDate != null
        ? formatDate(state.selectedDate!)
        : 'Semua tanggal';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  await notifier.setDate(picked);
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(dateLabel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: state.paymentMethod ?? 'all',
              decoration: const InputDecoration(
                labelText: 'Metode',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              items: [
                DropdownMenuItem(value: 'all', child: Text('Semua')),
                DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                DropdownMenuItem(value: 'debit', child: Text('Debit')),
              ],
              onChanged: (value) {
                notifier.setPaymentMethod(value == 'all' ? null : value);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Reset filter',
            onPressed: state.selectedDate == null && state.paymentMethod == null
                ? null
                : () => notifier.clearFilters(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.state, required this.notifier});

  final TransactionHistoryState state;
  final TransactionHistoryNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: _ErrorState(
              message: state.errorMessage!,
              onRetry: () => notifier.refresh(),
            ),
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(padding: EdgeInsets.only(top: 80), child: _EmptyState()),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 100 &&
              state.hasMore &&
              !state.isLoadingMore) {
            notifier.loadMore();
          }
        }
        return false;
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final transaction = state.items[index];
          return _HistoryTile(item: transaction);
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final TransactionHistoryItem item;

  Color _paymentColor() {
    switch (item.paymentMethod) {
      case 'cash':
        return Colors.green.shade100;
      case 'qris':
        return Colors.blue.shade100;
      case 'debit':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.code, style: Theme.of(context).textTheme.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _paymentColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(item.paymentMethod.toUpperCase()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(item.totalAmount),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(item.cashierName),
              const SizedBox(width: 12),
              const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${item.itemsCount} item'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(formatDateTime(item.createdAt)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
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
        children: [
          Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Belum ada transaksi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
