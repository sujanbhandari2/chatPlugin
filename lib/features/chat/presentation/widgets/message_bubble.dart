import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.senderLabel,
    required this.canDelete,
    required this.toAbsoluteMediaUrl,
    required this.onReact,
    required this.onDelete,
    required this.onMarkRead,
  });

  final ChatMessage message;
  final bool isMine;
  final String senderLabel;
  final bool canDelete;
  final String Function(String value) toAbsoluteMediaUrl;
  final ValueChanged<String> onReact;
  final VoidCallback onDelete;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final deliveryStatus = _resolveDeliveryStatus();
    final bubbleColor = isMine
        ? const Color(0xFF54A7F8)
        : const Color(0xFFE8EAEE);
    final textColor = isMine ? Colors.white : const Color(0xFF111827);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFFD1D5DB),
              child: Text(
                senderLabel.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showActions(context),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: _MessageContent(
                      message: message,
                      textColor: textColor,
                      toAbsoluteMediaUrl: toAbsoluteMediaUrl,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(message.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        _DeliveryTick(status: deliveryStatus),
                      ],
                    ],
                  ),
                  if (message.reactions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: message.reactions
                          .map(
                            (reaction) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Text(
                                reaction.reactionType,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Text('👍', style: TextStyle(fontSize: 18)),
              title: const Text('React with thumbs up'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onReact('👍');
              },
            ),
            ListTile(
              leading: const Text('❤️', style: TextStyle(fontSize: 18)),
              title: const Text('React with heart'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onReact('❤️');
              },
            ),
            if (!isMine)
              ListTile(
                leading: const Icon(Icons.done_all_rounded),
                title: const Text('Mark as seen'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onMarkRead();
                },
              ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete message'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onDelete();
                },
              ),
          ],
        ),
      ),
    );
  }

  _DeliveryStatus _resolveDeliveryStatus() {
    if (!isMine || message.isDeleted) {
      return _DeliveryStatus.none;
    }

    final hasSeen = message.readReceipts.any(
      (item) => item.userId != message.senderId,
    );
    if (hasSeen) {
      return _DeliveryStatus.seen;
    }

    final hasDelivered = message.deliveredReceipts.any(
      (item) => item.userId != message.senderId,
    );
    if (hasDelivered) {
      return _DeliveryStatus.delivered;
    }

    return _DeliveryStatus.sent;
  }
}

enum _DeliveryStatus { none, sent, delivered, seen }

class _DeliveryTick extends StatelessWidget {
  const _DeliveryTick({required this.status});

  final _DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == _DeliveryStatus.none) {
      return const SizedBox.shrink();
    }

    final icon = status == _DeliveryStatus.sent ? Icons.done : Icons.done_all;
    final color = status == _DeliveryStatus.seen
        ? const Color(0xFF2563EB)
        : const Color(0xFF9CA3AF);

    return Icon(icon, size: 14, color: color);
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.message,
    required this.textColor,
    required this.toAbsoluteMediaUrl,
  });

  final ChatMessage message;
  final Color textColor;
  final String Function(String value) toAbsoluteMediaUrl;

  @override
  Widget build(BuildContext context) {
    if (message.deletedAt != null) {
      return Text(
        'Message deleted',
        style: TextStyle(
          fontSize: 14,
          color: textColor.withValues(alpha: 0.85),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (message.type == MessageType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          toAbsoluteMediaUrl(message.content),
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(
            width: 220,
            height: 100,
            child: Center(child: Text('Unable to load image')),
          ),
        ),
      );
    }

    if (message.type == MessageType.voice) {
      return VoicePlayer(url: toAbsoluteMediaUrl(message.content));
    }

    return Text(
      message.content,
      style: TextStyle(fontSize: 14.5, color: textColor, height: 1.28),
    );
  }
}

class VoicePlayer extends StatefulWidget {
  const VoicePlayer({super.key, required this.url});

  final String url;

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  late final AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() => _playerState = state);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.tonal(
          onPressed: () async {
            if (isPlaying) {
              await _player.pause();
            } else {
              await _player.play(UrlSource(widget.url));
            }
          },
          child: Text(isPlaying ? 'Pause' : 'Play'),
        ),
        const SizedBox(width: 8),
        const Text('Voice message'),
      ],
    );
  }
}
