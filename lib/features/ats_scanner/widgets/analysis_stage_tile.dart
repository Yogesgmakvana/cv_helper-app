import 'package:flutter/material.dart';

class AnalysisStageTile extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final bool isActive;

  const AnalysisStageTile({
    super.key,
    required this.title,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = isCompleted
        ? const Color(0xFF27AE60)
        : isActive
            ? const Color(0xFF6C5CE7)
            : Colors.grey[400]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFFE8F8F0)
                  : isActive
                      ? const Color(0xFFEFEBFF)
                      : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded, size: 14, color: Color(0xFF27AE60))
                  : isActive
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                          ),
                        )
                      : Icon(Icons.circle, size: 8, color: Colors.grey[300]),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
