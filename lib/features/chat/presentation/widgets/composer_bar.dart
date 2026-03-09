import 'package:flutter/material.dart';

class ComposerBar extends StatelessWidget {
  const ComposerBar({
    super.key,
    required this.controller,
    required this.isRecording,
    required this.isSending,
    required this.onSend,
    required this.onPickImage,
    required this.onPickAudio,
    required this.onToggleRecording,
  });

  final TextEditingController controller;
  final bool isRecording;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickAudio;
  final VoidCallback onToggleRecording;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.add_rounded,
            color: const Color(0xFF1B74E4),
            onTap: isSending ? null : onPickImage,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isSending ? null : onPickAudio,
                    icon: const Icon(
                      Icons.attach_file_rounded,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  IconButton(
                    onPressed: onToggleRecording,
                    icon: Icon(
                      isRecording ? Icons.stop_circle_outlined : Icons.mic_none,
                      color: isRecording
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CircleButton(
            icon: Icons.send_rounded,
            color: isSending
                ? const Color(0xFFBFDBFE)
                : const Color(0xFF1B74E4),
            iconColor: Colors.white,
            onTap: isSending ? null : onSend,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final Color color;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor == null ? Colors.transparent : color,
          shape: BoxShape.circle,
          border: iconColor == null ? Border.all(color: color) : null,
        ),
        child: Icon(icon, color: iconColor ?? color, size: 19),
      ),
    );
  }
}
