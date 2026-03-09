import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        final message = data is Map<String, dynamic>
            ? (data['message']?.toString() ?? data['error']?.toString())
            : null;

        final wrapped = DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error:
              message ??
              'Request failed${statusCode != null ? ' ($statusCode)' : ''}',
        );
        handler.reject(wrapped);
      },
    ),
  );

  return dio;
});
