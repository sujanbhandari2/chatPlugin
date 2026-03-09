import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/conversation.dart';
import 'avatar_circle.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.title,
    required this.subtitle,
    required this.avatarLabel,
    required this.unreadCount,
    required this.isSelected,
    required this.onTap,
  });

  final Conversation conversation;
  final String title;
  final String subtitle;
  final String avatarLabel;
  final int unreadCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = conversation.createdAt;
    final isToday =
        now.year == date.year && now.month == date.month && now.day == date.day;
    final timestamp = isToday
        ? DateFormat('h:mm a').format(date)
        : DateFormat('M/d/yy').format(date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F3FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarCircle(label: avatarLabel, compact: true, size: 44),
                if (unreadCount > 0)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B74E4),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timestamp,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: unreadCount > 0
                          ? const Color(0xFF374151)
                          : const Color(0xFF6B7280),
                      fontSize: 12.8,
                      fontWeight: unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
