import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../config/env.dart';
import '../../providers/auto_logout_provider.dart';
import '../../utils/api_error.dart';
import 'local_storage_service.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final logger = Logger(
    printer: PrettyPrinter(colors: false, printTime: true, methodCount: 0),
  );

  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      logPrint: (msg) => logger.d(msg),
      retries: 3,
      retryDelays: const [
        Duration(milliseconds: 500),
        Duration(seconds: 1),
        Duration(seconds: 3),
      ],
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = storage.readAuthToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final message = ApiErrorUtils.friendlyMessage(error);
        if (AppEnv.enableVerboseLogging) {
          logger.e('[API ERROR] $message', error: error);
        }

        if (error.response?.statusCode == 401) {
          final notifier = ref.read(autoLogoutSignalProvider.notifier);
          notifier.state = notifier.state + 1;
        }

        return handler.next(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: error.error,
            stackTrace: error.stackTrace,
            message: message,
          ),
        );
      },
    ),
  );

  return dio;
});
