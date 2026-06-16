import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

/// Tingkat risiko keselamatan berdasarkan data laporan.
enum RiskLevel {
  high,   // Banyak laporan (>= threshold)
  medium, // Ada beberapa laporan (1-2)
  low,    // Tidak ada laporan (0)
}

/// Model yang merepresentasikan data analitik keselamatan suatu lab.
/// Dihitung secara dinamis berdasarkan data riwayat laporan di Firebase.
class LabSafetyInsight {
  final String labId;
  final String labName;
  
  /// Jumlah laporan dalam periode insight (misal: 7 hari terakhir)
  final int recentReportCount;
  
  /// Total laporan sepanjang waktu untuk lab ini
  final int totalReportCount;

  const LabSafetyInsight({
    required this.labId,
    required this.labName,
    required this.recentReportCount,
    required this.totalReportCount,
  });

  /// Kalkulasi tingkat risiko berdasarkan jumlah laporan terbaru.
  RiskLevel get riskLevel {
    if (recentReportCount >= AppConstants.highRiskThreshold) {
      return RiskLevel.high;
    } else if (recentReportCount >= AppConstants.mediumRiskThreshold) {
      return RiskLevel.medium;
    } else {
      return RiskLevel.low;
    }
  }

  /// Warna representatif untuk UI.
  Color get riskColor {
    switch (riskLevel) {
      case RiskLevel.high:
        return AppTheme.dangerRed;
      case RiskLevel.medium:
        return AppTheme.warningOrange;
      case RiskLevel.low:
        return AppTheme.successGreen;
    }
  }

  /// Label teks untuk tingkat risiko.
  String get riskLabel {
    switch (riskLevel) {
      case RiskLevel.high:
        return 'Risiko Tinggi';
      case RiskLevel.medium:
        return 'Perlu Perhatian';
      case RiskLevel.low:
        return 'Aman';
    }
  }

  /// Ikon representatif untuk UI.
  IconData get riskIcon {
    switch (riskLevel) {
      case RiskLevel.high:
        return Icons.dangerous_rounded;
      case RiskLevel.medium:
        return Icons.warning_amber_rounded;
      case RiskLevel.low:
        return Icons.verified_user_rounded;
    }
  }

  /// Pesan insight yang ramah pengguna.
  String get insightMessage {
    if (riskLevel == RiskLevel.high) {
      return 'PERINGATAN: Terdapat $recentReportCount laporan insiden dalam ${AppConstants.insightDays} hari terakhir. Tingkatkan kewaspadaan Anda di area ini.';
    } else if (riskLevel == RiskLevel.medium) {
      return 'Terdapat $recentReportCount laporan insiden dalam ${AppConstants.insightDays} hari terakhir. Mohon berhati-hati.';
    } else {
      if (recentReportCount == 1) {
        return 'Hanya ada 1 laporan dalam ${AppConstants.insightDays} hari terakhir. Kondisi relatif aman.';
      }
      return 'Kondisi aman. Tidak ada laporan insiden dalam ${AppConstants.insightDays} hari terakhir.';
    }
  }
}
