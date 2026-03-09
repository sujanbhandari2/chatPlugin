import '../domain/auth_repository.dart';
import '../domain/entities/auth_session.dart';
import 'auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api);

  final AuthApi _api;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final payload = await _api.login(username: username, password: password);
    return AuthSession.fromJson(payload);
  }

  @override
  Future<AuthSession> register({
    required String username,
    required String password,
  }) async {
    final payload = await _api.register(username: username, password: password);
    return AuthSession.fromJson(payload);
  }
}
