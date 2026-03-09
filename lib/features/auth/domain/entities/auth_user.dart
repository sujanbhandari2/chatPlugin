import '../../../../core/models/app_role.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.tenantId,
    required this.role,
    required this.username,
  });

  final String id;
  final String tenantId;
  final AppRole role;
  final String username;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      role: parseRole(json['role'] as String),
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'role': role.apiValue,
      'username': username,
    };
  }
}
