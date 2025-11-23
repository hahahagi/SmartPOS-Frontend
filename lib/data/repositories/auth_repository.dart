import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env.dart';
import '../models/auth_payload.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthPayload> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/login',
      data: {
        'email': email,
        'password': password,
        'device_name': AppEnv.appName,
      },
    );

    final body = response.data ?? <String, dynamic>{};
    return AuthPayload.fromJson(body);
  }

  Future<UserModel> fetchProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/user');
    final body = response.data ?? <String, dynamic>{};
    return UserModel.fromJson(body);
  }

  Future<void> logout() async {
    await _dio.post('/logout');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AuthRepository(dio);
});
