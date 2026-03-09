import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.inline = false});

  final String message;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: inline ? 8 : 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB91C1C),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
