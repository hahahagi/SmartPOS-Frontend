import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/env.dart';
import '../../utils/hive_boxes.dart';

class LocalStorageService {
  LocalStorageService(this._preferences);

  final SharedPreferences _preferences;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _lastLoginKey = 'last_login_timestamp';

  String? readAuthToken() => _preferences.getString(_tokenKey);

  Future<void> writeAuthToken(String token) async {
    await _preferences.setString(_tokenKey, token);
    await _preferences.setInt(
      _lastLoginKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> clearAuth() async {
    await _preferences.remove(_tokenKey);
    await _preferences.remove(_userKey);
    await _preferences.remove(_lastLoginKey);
  }

  Future<void> writeUserJson(Map<String, dynamic> json) async {
    await _preferences.setString(_userKey, jsonEncode(json));
  }

  Map<String, dynamic>? readUserJson() {
    final raw = _preferences.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Placeholder for Hive initialization side-effects. Keeps Hive box names
  /// referenced to avoid accidental removal by tree shaking.
  Future<void> warmupHive() async {
    if (AppEnv.enableVerboseLogging) {
      // ignore: avoid_print
      print(
        'Hive boxes ready: ${[HiveBoxes.appCache, HiveBoxes.productCache, HiveBoxes.offlineTransactions]}',
      );
    }
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((_) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});
