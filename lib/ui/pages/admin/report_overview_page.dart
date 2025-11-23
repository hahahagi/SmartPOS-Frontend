import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/report_models.dart';
import '../../../data/models/transaction_history_model.dart';
import '../../../providers/admin/report_overview_provider.dart';
import '../../../utils/formatters.dart';
import '../../widgets/custom_app_bar.dart';

class ReportOverviewPage extends ConsumerStatefulWidget {
  const ReportOverviewPage({super.key});

  static const String routeName = 'report-overview';
  static const String routePath = '/admin/reports';

  @override
  ConsumerState<ReportOverviewPage> createState() => _ReportOverviewPageState();
}

class _ReportOverviewPageState extends ConsumerState<ReportOverviewPage> {
  final _monthLabelFormatter = DateFormat('MMMM yyyy', 'id_ID');

  ReportOverviewNotifier get _notifier =>
      ref.read(reportOverviewProvider.notifier);

  Future<void> _pickDailyDate(DateTime initialDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(initialDate.year - 1),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    await _notifier.loadDailyReport(date: picked);
  }

  Future<void> _pickMonthlyPeriod(int year, int month) async {
    final current = DateTime(year, month, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(year - 2, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'Pilih Bulan Laporan',
    );
    if (picked == null) return;
    await _notifier.loadMonthlyReport(year: picked.year, month: picked.month);
  }

  Future<void> _pickBestsellerRange(DateTime start, DateTime end) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(start.year - 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: start, end: end),
      helpText: 'Pilih Rentang Waktu',
    );
    if (range == null) return;
    await _notifier.loadBestsellerReport(
      startDate: range.start,
      endDate: range.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportOverviewProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Laporan Penjualan',
          showBackButton: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Harian'),
                  Tab(text: 'Bulanan'),
                  Tab(text: 'Produk Terlaris'),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDailyTab(state),
                  _buildMonthlyTab(state),
                  _buildBestsellerTab(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTab(ReportOverviewState state) {
    final report = state.dailyReport;
    return RefreshIndicator(
      onRefresh: () => _notifier.refreshDailyReport(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      formatDate(state.dailyDate),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Pilih tanggal',
                onPressed: () => _pickDailyDate(state.dailyDate),
                icon: const Icon(Icons.event),
              ),
              TextButton(
                onPressed: () =>
                    _notifier.loadDailyReport(date: DateTime.now()),
                child: const Text('Hari ini'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isLoadingDaily && report == null)
            const _ReportLoadingPlaceholder(),
          if (state.dailyError != null && report == null)
            _InlineError(
              message: state.dailyError!,
              onRetry: () => _notifier.refreshDailyReport(),
            ),
          if (report != null) ...[
            _SummaryGrid(summary: report.summary),
            const SizedBox(height: 16),
            _PaymentMethodList(stats: report.paymentMethods),
            const SizedBox(height: 16),
            _TransactionPreviewList(
              title: 'Transaksi Hari Ini',
              transactions: report.transactions,
              emptyMessage: 'Belum ada transaksi untuk tanggal ini.',
            ),
          ],
          if (state.isLoadingDaily && report != null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTab(ReportOverviewState state) {
    final report = state.monthlyReport;
    final label = _monthLabelFormatter.format(
      DateTime(state.monthlyYear, state.monthlyMonth, 1),
    );
    return RefreshIndicator(
      onRefresh: () => _notifier.refreshMonthlyReport(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Periode',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Pilih bulan',
                onPressed: () =>
                    _pickMonthlyPeriod(state.monthlyYear, state.monthlyMonth),
                icon: const Icon(Icons.calendar_month),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isLoadingMonthly && report == null)
            const _ReportLoadingPlaceholder(),
          if (state.monthlyError != null && report == null)
            _InlineError(
              message: state.monthlyError!,
              onRetry: () => _notifier.refreshMonthlyReport(),
            ),
          if (report != null) ...[
            _SummaryGrid(summary: report.summary),
            const SizedBox(height: 16),
            _DailyTrendList(stats: report.dailySummary),
            const SizedBox(height: 16),
            _TransactionPreviewList(
              title: 'Transaksi Bulan Ini',
              transactions: report.transactions,
              emptyMessage: 'Belum ada transaksi tercatat bulan ini.',
            ),
          ],
          if (state.isLoadingMonthly && report != null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildBestsellerTab(ReportOverviewState state) {
    final report = state.bestsellerReport;
    final rangeLabel =
        '${formatDate(state.bestsellerStartDate)} - ${formatDate(state.bestsellerEndDate)}';
    return RefreshIndicator(
      onRefresh: () => _notifier.refreshBestsellerReport(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rentang',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      rangeLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Pilih rentang',
                onPressed: () => _pickBestsellerRange(
                  state.bestsellerStartDate,
                  state.bestsellerEndDate,
                ),
                icon: const Icon(Icons.date_range),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isLoadingBestseller && report == null)
            const _ReportLoadingPlaceholder(),
          if (state.bestsellerError != null && report == null)
            _InlineError(
              message: state.bestsellerError!,
              onRetry: () => _notifier.refreshBestsellerReport(),
            ),
          if (report != null) ...[
            Text(
              'Produk Terlaris',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (report.bestsellers.isEmpty)
              const Text('Belum ada data penjualan untuk rentang ini.'),
            if (report.bestsellers.isNotEmpty)
              _BestsellerList(items: report.bestsellers),
          ],
          if (state.isLoadingBestseller && report != null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCard(
        title: 'Total Penjualan',
        value: formatCurrency(summary.totalAmount),
        icon: Icons.payments,
        accentColor: Colors.blue,
      ),
      _SummaryCard(
        title: 'Jumlah Transaksi',
        value: summary.totalTransactions.toString(),
        icon: Icons.receipt_long,
        accentColor: Colors.orange,
      ),
      _SummaryCard(
        title: 'Rata-rata Transaksi',
        value: formatCurrency(summary.averageTransaction),
        icon: Icons.trending_up,
        accentColor: Colors.green,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == cards.length - 1 ? 0 : 12,
                    ),
                    child: cards[i],
                  ),
                ),
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i != cards.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: accentColor.withOpacity(.15),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodList extends StatelessWidget {
  const _PaymentMethodList({required this.stats});

  final List<PaymentMethodStat> stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metode Pembayaran',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (stats.isEmpty) const Text('Belum ada data metode pembayaran.'),
            if (stats.isNotEmpty)
              ...stats.map((item) {
                final avatarLabel = item.method.isEmpty
                    ? '-'
                    : item.method.substring(0, 1);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueGrey.withOpacity(.15),
                    child: Text(avatarLabel),
                  ),
                  title: Text(item.method),
                  subtitle: Text(
                    '${item.count} transaksi • ${formatCurrency(item.amount)}',
                  ),
                  trailing: Text(
                    formatCurrency(item.averageTicket),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _TransactionPreviewList extends StatelessWidget {
  const _TransactionPreviewList({
    required this.title,
    required this.transactions,
    required this.emptyMessage,
  });

  final String title;
  final List<TransactionHistoryItem> transactions;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final preview = transactions.take(10).toList();
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (preview.isEmpty) Text(emptyMessage),
            if (preview.isNotEmpty)
              ...preview.map(
                (item) => Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(.15),
                        child: const Icon(Icons.receipt_long),
                      ),
                      title: Text(item.code),
                      subtitle: Text(
                        '${item.paymentMethod.toUpperCase()} • '
                        '${formatDateTime(item.createdAt)}',
                      ),
                      trailing: Text(
                        formatCurrency(item.totalAmount),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (item != preview.last) const Divider(),
                  ],
                ),
              ),
            if (transactions.length > preview.length)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '+${transactions.length - preview.length} transaksi lainnya',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DailyTrendList extends StatelessWidget {
  const _DailyTrendList({required this.stats});

  final List<DailySalesStat> stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Harian',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (stats.isEmpty)
              const Text('Belum ada data harian untuk bulan ini.'),
            if (stats.isNotEmpty)
              ...stats.map(
                (item) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(formatDate(item.date))),
                        Text('${item.totalTransactions} trx'),
                        const SizedBox(width: 12),
                        Text(
                          formatCurrency(item.totalAmount),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (item != stats.last) const Divider(height: 16),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BestsellerList extends StatelessWidget {
  const _BestsellerList({required this.items});

  final List<BestsellerProductStat> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple.withOpacity(.15),
                  child: Text('#${index + 1}'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        item.barcode,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text('${item.totalSold} terjual'),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(item.totalRevenue),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text('ID ${item.productId}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.redAccent.withOpacity(.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red.shade700),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportLoadingPlaceholder extends StatelessWidget {
  const _ReportLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Sedang memuat laporan...')),
          ],
        ),
      ),
    );
  }
}
