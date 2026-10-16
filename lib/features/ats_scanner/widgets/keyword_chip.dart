import 'package:flutter/material.dart';

class KeywordChip extends StatelessWidget {
  final String label;
  final bool isMatched;

  const KeywordChip({
    super.key,
    required this.label,
    required this.isMatched,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isMatched ? const Color(0xFFE8F8F0) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMatched ? const Color(0xFF27AE60).withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMatched ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: isMatched ? const Color(0xFF27AE60) : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isMatched ? const Color(0xFF27AE60) : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}
