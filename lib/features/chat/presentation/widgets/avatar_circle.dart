import 'package:flutter/material.dart';

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.label,
    this.size = 42,
    this.compact = false,
  });

  final String label;
  final double size;
  final bool compact;

  static const List<Color> _palette = [
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
    Color(0xFF0EA5E9),
    Color(0xFF059669),
    Color(0xFFEA580C),
    Color(0xFFDB2777),
    Color(0xFF4F46E5),
  ];

  @override
  Widget build(BuildContext context) {
    final base = _pickColor(label);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: compact
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [base.withValues(alpha: 0.9), base],
              ),
        color: compact ? base.withValues(alpha: 0.85) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 12.5 : 14,
        ),
      ),
    );
  }

  Color _pickColor(String value) {
    final sum = value.codeUnits.fold<int>(0, (prev, unit) => prev + unit);
    return _palette[sum % _palette.length];
  }
}
