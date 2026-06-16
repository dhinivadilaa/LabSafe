import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../core/theme/app_theme.dart';
import '../models/report_model.dart';

class IncidentTimelineItem extends StatelessWidget {
  final ReportModel report;
  final bool isLast;

  const IncidentTimelineItem({
    super.key,
    required this.report,
    this.isLast = false,
  });

  IconData _getIconForReportType(String type) {
    if (type.toLowerCase().contains('listrik')) return Icons.electrical_services_rounded;
    if (type.toLowerCase().contains('kimia')) return Icons.science_rounded;
    if (type.toLowerCase().contains('kebakaran')) return Icons.local_fire_department_rounded;
    if (type.toLowerCase().contains('kerusakan')) return Icons.build_rounded;
    return Icons.warning_rounded;
  }

  Color _getColorForReportType(String type) {
    if (type.toLowerCase().contains('listrik') || type.toLowerCase().contains('kebakaran')) {
      return AppTheme.dangerRed;
    }
    if (type.toLowerCase().contains('kimia')) {
      return AppTheme.accentBlue;
    }
    return AppTheme.warningOrange;
  }

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('id', timeago.IdMessages());
    final dateStr = timeago.format(report.createdAt, locale: 'id');
    final iconColor = _getColorForReportType(report.reportType);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForReportType(report.reportType),
                    size: 14,
                    color: iconColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppTheme.grey200,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  )
                else
                  const SizedBox(height: 16), // Bottom padding for last item
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          report.reportType,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.grey800,
                          ),
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.grey400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.grey600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
