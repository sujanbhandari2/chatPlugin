import 'package:flutter/material.dart';

import '../../../../core/models/app_role.dart';
import '../../domain/entities/tenant_user.dart';
import 'avatar_circle.dart';

class OnlineUserTile extends StatelessWidget {
  const OnlineUserTile({
    super.key,
    required this.user,
    required this.avatarLabel,
    required this.displayName,
    required this.isOpening,
    required this.onTap,
  });

  final TenantUser user;
  final String avatarLabel;
  final String displayName;
  final bool isOpening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarCircle(label: avatarLabel, compact: true, size: 34),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: user.isOnline
                        ? const Color(0xFF10B981)
                        : const Color(0xFF9CA3AF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${user.role.label} • ${user.isOnline ? 'Online' : 'Offline'}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: isOpening ? null : onTap,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B74E4),
              foregroundColor: Colors.white,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(isOpening ? '...' : 'Chat'),
          ),
        ],
      ),
    );
  }
}
