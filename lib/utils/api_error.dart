import 'package:dio/dio.dart';

class ApiErrorUtils {
  static String friendlyMessage(DioException error) {
    final response = error.response;
    if (response != null) {
      final message = _messageFromResponse(response.data);
      if (message != null && message.isNotEmpty) {
        return message;
      }
      if (response.statusCode != null) {
        if (response.statusCode! >= 500) {
          return 'Terjadi kesalahan server, coba beberapa saat lagi.';
        }
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return 'Koneksi lemah, mencoba kembali...';
      default:
        return 'Terjadi kesalahan, coba beberapa saat lagi.';
    }
  }

  static String? _messageFromResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['message'] is String) {
        return data['message'] as String;
      }
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        final firstKey = errors.keys.cast<String?>().firstWhere(
          (key) => key != null,
          orElse: () => null,
        );
        if (firstKey != null) {
          final value = errors[firstKey];
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
          if (value is String) return value;
        }
      }
    } else if (data is List && data.isNotEmpty) {
      return data.first.toString();
    } else if (data is String) {
      return data;
    }
    return null;
  }
}
