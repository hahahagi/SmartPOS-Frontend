import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/report_models.dart';
import '../services/api_client.dart';

class ReportRepository {
  ReportRepository(this._dio);

  final Dio _dio;
  static final _dateFormatter = DateFormat('yyyy-MM-dd');

  Future<DailyReportModel> fetchDailyReport({DateTime? date}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reports/daily',
      queryParameters: {if (date != null) 'date': _dateFormatter.format(date)},
    );
    return DailyReportModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<MonthlyReportModel> fetchMonthlyReport({int? year, int? month}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reports/monthly',
      queryParameters: {
        if (year != null) 'year': year,
        if (month != null) 'month': month,
      },
    );
    return MonthlyReportModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<BestsellerReportModel> fetchBestsellerReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reports/bestseller',
      queryParameters: {
        if (startDate != null) 'start_date': _dateFormatter.format(startDate),
        if (endDate != null) 'end_date': _dateFormatter.format(endDate),
      },
    );
    return BestsellerReportModel.fromJson(response.data ?? <String, dynamic>{});
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return ReportRepository(dio);
});
