import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/session_storage.dart';
import '../../data/auth_api.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/auth_repository.dart';
import '../../domain/entities/auth_session.dart';
import '../state/auth_state.dart';

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(),
);

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.read(dioProvider);
  return AuthApi(dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.read(authApiProvider);
  return AuthRepositoryImpl(api);
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final repository = ref.read(authRepositoryProvider);
    final storage = ref.read(sessionStorageProvider);
    final controller = AuthController(repository, storage);
    controller.initialize();
    return controller;
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._storage) : super(AuthState.initial());

  final AuthRepository _repository;
  final SessionStorage _storage;

  Future<void> initialize() async {
    final raw = await _storage.loadSessionRaw();
    final session = AuthSession.deserialize(raw);

    state = state.copyWith(
      isInitializing: false,
      session: session,
      clearError: true,
    );
  }

  void setMode(AuthMode mode) {
    state = state.copyWith(mode: mode, clearError: true);
  }

  Future<void> authenticate({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final normalized = username.trim().toLowerCase();
      final session = state.mode == AuthMode.register
          ? await _repository.register(username: normalized, password: password)
          : await _repository.login(username: normalized, password: password);

      await _storage.saveSessionRaw(session.serialize());
      state = state.copyWith(
        isLoading: false,
        session: session,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
    await _storage.clearSelectedConversationId();
    state = state.copyWith(
      clearSession: true,
      clearError: true,
      mode: AuthMode.login,
    );
  }
}
