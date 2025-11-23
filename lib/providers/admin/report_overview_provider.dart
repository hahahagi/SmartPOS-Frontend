import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/report_models.dart';
import '../../data/repositories/report_repository.dart';

class ReportOverviewState {
  const ReportOverviewState({
    this.dailyReport,
    this.monthlyReport,
    this.bestsellerReport,
    this.dailyError,
    this.monthlyError,
    this.bestsellerError,
    required this.dailyDate,
    required this.monthlyYear,
    required this.monthlyMonth,
    required this.bestsellerStartDate,
    required this.bestsellerEndDate,
    this.isLoadingDaily = false,
    this.isLoadingMonthly = false,
    this.isLoadingBestseller = false,
  });

  final DailyReportModel? dailyReport;
  final MonthlyReportModel? monthlyReport;
  final BestsellerReportModel? bestsellerReport;
  final String? dailyError;
  final String? monthlyError;
  final String? bestsellerError;
  final bool isLoadingDaily;
  final bool isLoadingMonthly;
  final bool isLoadingBestseller;
  final DateTime dailyDate;
  final int monthlyYear;
  final int monthlyMonth;
  final DateTime bestsellerStartDate;
  final DateTime bestsellerEndDate;

  factory ReportOverviewState.initial() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final today = DateTime(now.year, now.month, now.day);
    return ReportOverviewState(
      dailyDate: today,
      monthlyYear: now.year,
      monthlyMonth: now.month,
      bestsellerStartDate: startOfMonth,
      bestsellerEndDate: today,
    );
  }

  ReportOverviewState copyWith({
    DailyReportModel? dailyReport,
    bool clearDailyReport = false,
    bool? isLoadingDaily,
    String? dailyError,
    bool clearDailyError = false,
    DateTime? dailyDate,
    MonthlyReportModel? monthlyReport,
    bool clearMonthlyReport = false,
    bool? isLoadingMonthly,
    String? monthlyError,
    bool clearMonthlyError = false,
    int? monthlyYear,
    int? monthlyMonth,
    BestsellerReportModel? bestsellerReport,
    bool clearBestsellerReport = false,
    bool? isLoadingBestseller,
    String? bestsellerError,
    bool clearBestsellerError = false,
    DateTime? bestsellerStartDate,
    DateTime? bestsellerEndDate,
  }) {
    return ReportOverviewState(
      dailyReport: clearDailyReport ? null : (dailyReport ?? this.dailyReport),
      isLoadingDaily: isLoadingDaily ?? this.isLoadingDaily,
      dailyError: clearDailyError ? null : (dailyError ?? this.dailyError),
      dailyDate: dailyDate ?? this.dailyDate,
      monthlyReport: clearMonthlyReport
          ? null
          : (monthlyReport ?? this.monthlyReport),
      isLoadingMonthly: isLoadingMonthly ?? this.isLoadingMonthly,
      monthlyError: clearMonthlyError
          ? null
          : (monthlyError ?? this.monthlyError),
      monthlyYear: monthlyYear ?? this.monthlyYear,
      monthlyMonth: monthlyMonth ?? this.monthlyMonth,
      bestsellerReport: clearBestsellerReport
          ? null
          : (bestsellerReport ?? this.bestsellerReport),
      isLoadingBestseller: isLoadingBestseller ?? this.isLoadingBestseller,
      bestsellerError: clearBestsellerError
          ? null
          : (bestsellerError ?? this.bestsellerError),
      bestsellerStartDate: bestsellerStartDate ?? this.bestsellerStartDate,
      bestsellerEndDate: bestsellerEndDate ?? this.bestsellerEndDate,
    );
  }
}

class ReportOverviewNotifier extends StateNotifier<ReportOverviewState> {
  ReportOverviewNotifier(this._repository)
    : super(ReportOverviewState.initial()) {
    _initialize();
  }

  final ReportRepository _repository;

  Future<void> _initialize() async {
    await Future.wait([
      loadDailyReport(),
      loadMonthlyReport(),
      loadBestsellerReport(),
    ]);
  }

  Future<void> loadDailyReport({DateTime? date}) async {
    final targetDate = _normalizeDate(date ?? state.dailyDate);
    state = state.copyWith(
      isLoadingDaily: true,
      clearDailyError: true,
      dailyDate: targetDate,
    );
    try {
      final report = await _repository.fetchDailyReport(date: targetDate);
      state = state.copyWith(isLoadingDaily: false, dailyReport: report);
    } catch (error) {
      state = state.copyWith(
        isLoadingDaily: false,
        dailyError: 'Gagal memuat laporan harian: $error',
      );
    }
  }

  Future<void> refreshDailyReport() => loadDailyReport(date: state.dailyDate);

  Future<void> loadMonthlyReport({int? year, int? month}) async {
    final targetYear = year ?? state.monthlyYear;
    final targetMonth = month ?? state.monthlyMonth;
    state = state.copyWith(
      isLoadingMonthly: true,
      clearMonthlyError: true,
      monthlyYear: targetYear,
      monthlyMonth: targetMonth,
    );
    try {
      final report = await _repository.fetchMonthlyReport(
        year: targetYear,
        month: targetMonth,
      );
      state = state.copyWith(isLoadingMonthly: false, monthlyReport: report);
    } catch (error) {
      state = state.copyWith(
        isLoadingMonthly: false,
        monthlyError: 'Gagal memuat laporan bulanan: $error',
      );
    }
  }

  Future<void> refreshMonthlyReport() => loadMonthlyReport();

  Future<void> loadBestsellerReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var start = _normalizeDate(startDate ?? state.bestsellerStartDate);
    var end = _normalizeDate(endDate ?? state.bestsellerEndDate);
    if (start.isAfter(end)) {
      final temp = start;
      start = end;
      end = temp;
    }

    state = state.copyWith(
      isLoadingBestseller: true,
      clearBestsellerError: true,
      bestsellerStartDate: start,
      bestsellerEndDate: end,
    );
    try {
      final report = await _repository.fetchBestsellerReport(
        startDate: start,
        endDate: end,
      );
      state = state.copyWith(
        isLoadingBestseller: false,
        bestsellerReport: report,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingBestseller: false,
        bestsellerError: 'Gagal memuat produk terlaris: $error',
      );
    }
  }

  Future<void> refreshBestsellerReport() => loadBestsellerReport();

  DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

final reportOverviewProvider =
    StateNotifierProvider.autoDispose<
      ReportOverviewNotifier,
      ReportOverviewState
    >((ref) {
      final repository = ref.watch(reportRepositoryProvider);
      return ReportOverviewNotifier(repository);
    });
