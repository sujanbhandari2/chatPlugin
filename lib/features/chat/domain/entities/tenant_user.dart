import '../../../../core/models/app_role.dart';

class TenantUser {
  const TenantUser({
    required this.id,
    required this.tenantId,
    required this.username,
    required this.role,
    required this.isOnline,
    required this.createdAt,
  });

  final String id;
  final String tenantId;
  final String username;
  final AppRole role;
  final bool isOnline;
  final DateTime createdAt;

  factory TenantUser.fromJson(Map<String, dynamic> json) {
    return TenantUser(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      username: json['username'] as String,
      role: parseRole(json['role'] as String),
      isOnline: json['isOnline'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
