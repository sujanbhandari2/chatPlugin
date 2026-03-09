import 'dart:io';

class AppConfig {
  const AppConfig._();

  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000/api';
    }

    return 'http://localhost:4000/api';
  }

  static String get socketUrl {
    const fromDefine = String.fromEnvironment('SOCKET_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000';
    }

    return 'http://localhost:4000';
  }
}
