import 'package:dio/dio.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'username': username, 'password': password},
    );

    return Map<String, dynamic>.from(response.data as Map);
  }
}
