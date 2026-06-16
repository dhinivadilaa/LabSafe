import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/lab_safety_insight.dart';

class StatusBadge extends StatelessWidget {
  final RiskLevel riskLevel;
  final String label;

  const StatusBadge({
    super.key,
    required this.riskLevel,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (riskLevel) {
      case RiskLevel.high:
        bgColor = AppTheme.dangerRed.withOpacity(0.1);
        textColor = AppTheme.dangerRed;
        icon = Icons.error_outline_rounded;
        break;
      case RiskLevel.medium:
        bgColor = AppTheme.warningOrange.withOpacity(0.1);
        textColor = AppTheme.warningOrange;
        icon = Icons.warning_amber_rounded;
        break;
      case RiskLevel.low:
        bgColor = AppTheme.successGreen.withOpacity(0.1);
        textColor = AppTheme.successGreen;
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
