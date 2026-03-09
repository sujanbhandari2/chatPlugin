import 'package:dio/dio.dart';

class PushTokenApi {
  PushTokenApi(this._dio);

  final Dio _dio;

  Future<void> registerToken({
    required String authToken,
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    await _dio.post(
      '/users/push-token',
      data: {
        'token': token,
        'platform': platform,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      },
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
  }

  Future<void> unregisterToken({
    required String authToken,
    required String token,
  }) async {
    await _dio.delete(
      '/users/push-token',
      data: {'token': token},
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
  }
}
