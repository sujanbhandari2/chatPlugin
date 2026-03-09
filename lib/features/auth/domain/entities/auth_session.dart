import 'dart:convert';

import 'auth_user.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user.toJson()};
  }

  String serialize() => jsonEncode(toJson());

  static AuthSession? deserialize(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AuthSession.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
