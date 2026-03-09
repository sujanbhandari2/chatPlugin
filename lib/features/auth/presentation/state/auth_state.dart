import '../../../auth/domain/entities/auth_session.dart';

enum AuthMode { login, register }

class AuthState {
  const AuthState({
    required this.isInitializing,
    required this.isLoading,
    required this.mode,
    this.session,
    this.error,
  });

  factory AuthState.initial() {
    return const AuthState(
      isInitializing: true,
      isLoading: false,
      mode: AuthMode.login,
    );
  }

  final bool isInitializing;
  final bool isLoading;
  final AuthMode mode;
  final AuthSession? session;
  final String? error;

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    bool? isInitializing,
    bool? isLoading,
    AuthMode? mode,
    AuthSession? session,
    String? error,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      mode: mode ?? this.mode,
      session: clearSession ? null : (session ?? this.session),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
