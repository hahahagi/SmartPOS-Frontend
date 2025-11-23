import 'transaction_history_model.dart';

class ReportSummary {
  const ReportSummary({
    required this.totalTransactions,
    required this.totalAmount,
    required this.averageTransaction,
  });

  final int totalTransactions;
  final double totalAmount;
  final double averageTransaction;

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalTransactions: _asInt(json['total_transactions']),
      totalAmount: _asDouble(json['total_amount']),
      averageTransaction: _asDouble(json['average_transaction']),
    );
  }

  static const empty = ReportSummary(
    totalTransactions: 0,
    totalAmount: 0,
    averageTransaction: 0,
  );
}

class PaymentMethodStat {
  const PaymentMethodStat({
    required this.method,
    required this.count,
    required this.amount,
  });

  final String method;
  final int count;
  final double amount;

  double get averageTicket => count == 0 ? 0 : amount / count;

  factory PaymentMethodStat.fromJson(Map<String, dynamic> json) {
    return PaymentMethodStat(
      method: (json['payment_method'] as String? ?? '-').toUpperCase(),
      count: _asInt(json['count']),
      amount: _asDouble(json['amount']),
    );
  }
}

class DailyReportModel {
  const DailyReportModel({
    required this.date,
    required this.summary,
    required this.paymentMethods,
    required this.transactions,
  });

  final DateTime date;
  final ReportSummary summary;
  final List<PaymentMethodStat> paymentMethods;
  final List<TransactionHistoryItem> transactions;

  factory DailyReportModel.fromJson(Map<String, dynamic> json) {
    final paymentList = json['payment_methods'] as List<dynamic>? ?? const [];
    final transactions = json['transactions'] as List<dynamic>? ?? const [];
    return DailyReportModel(
      date: _parseDate(json['date']),
      summary: ReportSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      paymentMethods: paymentList
          .whereType<Map<String, dynamic>>()
          .map(PaymentMethodStat.fromJson)
          .toList(),
      transactions: transactions
          .whereType<Map<String, dynamic>>()
          .map(TransactionHistoryItem.fromJson)
          .toList(),
    );
  }
}

class MonthlyReportModel {
  const MonthlyReportModel({
    required this.period,
    required this.summary,
    required this.dailySummary,
    required this.transactions,
  });

  final String period;
  final ReportSummary summary;
  final List<DailySalesStat> dailySummary;
  final List<TransactionHistoryItem> transactions;

  int get month => _extractMonth(period);
  int get year => _extractYear(period);

  factory MonthlyReportModel.fromJson(Map<String, dynamic> json) {
    final daily = json['daily_summary'] as List<dynamic>? ?? const [];
    final transactions = json['transactions'] as List<dynamic>? ?? const [];
    return MonthlyReportModel(
      period: json['period'] as String? ?? '-',
      summary: ReportSummary.fromJson(
        json['monthly_summary'] as Map<String, dynamic>? ?? const {},
      ),
      dailySummary: daily
          .whereType<Map<String, dynamic>>()
          .map(DailySalesStat.fromJson)
          .toList(),
      transactions: transactions
          .whereType<Map<String, dynamic>>()
          .map(TransactionHistoryItem.fromJson)
          .toList(),
    );
  }
}

class DailySalesStat {
  const DailySalesStat({
    required this.date,
    required this.totalTransactions,
    required this.totalAmount,
  });

  final DateTime date;
  final int totalTransactions;
  final double totalAmount;

  factory DailySalesStat.fromJson(Map<String, dynamic> json) {
    return DailySalesStat(
      date: _parseDate(json['date']),
      totalTransactions: _asInt(json['total_transactions']),
      totalAmount: _asDouble(json['total_amount']),
    );
  }
}

class BestsellerProductStat {
  const BestsellerProductStat({
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.totalSold,
    required this.totalRevenue,
  });

  final int productId;
  final String productName;
  final String barcode;
  final int totalSold;
  final double totalRevenue;

  factory BestsellerProductStat.fromJson(Map<String, dynamic> json) {
    return BestsellerProductStat(
      productId: _asInt(json['id']),
      productName: json['name'] as String? ?? '-',
      barcode: json['barcode'] as String? ?? '-',
      totalSold: _asInt(json['total_sold']),
      totalRevenue: _asDouble(json['total_revenue']),
    );
  }
}

class BestsellerReportModel {
  const BestsellerReportModel({
    required this.period,
    required this.bestsellers,
  });

  final String period;
  final List<BestsellerProductStat> bestsellers;

  factory BestsellerReportModel.fromJson(Map<String, dynamic> json) {
    final list = json['bestsellers'] as List<dynamic>? ?? const [];
    return BestsellerReportModel(
      period: json['period'] as String? ?? '-',
      bestsellers: list
          .whereType<Map<String, dynamic>>()
          .map(BestsellerProductStat.fromJson)
          .toList(),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _asDouble(dynamic value) {
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
  }
  return DateTime.now();
}

int _extractYear(String period) {
  final parts = period.split('-');
  if (parts.length >= 1) {
    final year = int.tryParse(parts[0]);
    if (year != null) return year;
  }
  return DateTime.now().year;
}

int _extractMonth(String period) {
  final parts = period.split('-');
  if (parts.length >= 2) {
    final month = int.tryParse(parts[1]);
    if (month != null) return month;
  }
  return DateTime.now().month;
}
