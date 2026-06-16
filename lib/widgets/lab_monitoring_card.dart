import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/lab_safety_insight.dart';
import 'status_badge.dart';

class LabMonitoringCard extends StatelessWidget {
  final LabSafetyInsight insight;
  final VoidCallback? onTap;

  const LabMonitoringCard({
    super.key,
    required this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: InkWell(
        onTap: onTap ?? () {}, // Ensure ripple works even without a route
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      insight.labName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.grey800,
                      ),
                    ),
                  ),
                  StatusBadge(
                    riskLevel: insight.riskLevel,
                    label: insight.riskLabel,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem(
                    icon: Icons.assignment_late_rounded,
                    value: '${insight.recentReportCount}',
                    label: 'Laporan (7 Hari)',
                    color: AppTheme.grey600,
                  ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    icon: Icons.history_rounded,
                    value: '${insight.totalReportCount}',
                    label: 'Total Insiden',
                    color: AppTheme.grey600,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.grey400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
