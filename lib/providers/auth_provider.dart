import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auth_payload.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/local_storage_service.dart';
import 'auto_logout_provider.dart';

enum AuthStatus {
  unknown,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.authenticating;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isManager => user?.isManager ?? false;
  bool get isCashier => user?.isCashier ?? false;
  String get roleLabel => user?.roleLabel ?? '-';

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool clearUser = false,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref, this._repository, this._storage)
    : super(const AuthState()) {
    _ref.listen<int>(autoLogoutSignalProvider, (previous, next) {
      if (previous == next) return;
      if (next > 0 && state.status == AuthStatus.authenticated) {
        forceLogout();
      }
    });
  }

  final Ref _ref;
  final AuthRepository _repository;
  final LocalStorageService _storage;

  Future<void> hydrateSession() async {
    if (state.status == AuthStatus.authenticating) return;
    final token = _storage.readAuthToken();
    if (token == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final cachedUserJson = _storage.readUserJson();
      if (cachedUserJson != null) {
        final user = UserModel.fromJson(cachedUserJson);
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      }

      final profile = await _repository.fetchProfile();
      await _storage.writeUserJson(profile.toJson());
      state = state.copyWith(status: AuthStatus.authenticated, user: profile);
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        clearUser: true,
        errorMessage: '$error',
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      errorMessage: null,
    );
    try {
      final payload = await _repository.login(email: email, password: password);
      await _persistPayload(payload);
      await _storage.addEmailToHistory(email);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: payload.user,
      );
    } catch (error) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: '$error');
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      await _storage.clearAuth();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    }
  }

  Future<void> forceLogout() async {
    await _storage.clearAuth();
    state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
  }

  Future<void> _persistPayload(AuthPayload payload) async {
    await _storage.writeAuthToken(payload.token);
    await _storage.writeUserJson(payload.user.toJson());
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(localStorageServiceProvider);
  return AuthNotifier(ref, repository, storage);
});
