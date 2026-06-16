import 'package:firebase_database/firebase_database.dart';
import '../core/constants/app_constants.dart';
import '../models/lab_safety_insight.dart';
import '../models/report_model.dart';

/// Service untuk menghitung dan menganalisis tingkat keselamatan lab
/// secara dinamis berdasarkan data laporan aktual dari Firebase.
class LabSafetyService {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Mengambil insight keselamatan untuk satu lab spesifik berdasarkan nama lab.
  static Future<LabSafetyInsight> getLabInsight(String labName) async {
    final recentCount = await getReportCountForLab(
      labName,
      days: AppConstants.insightDays,
    );
    final totalCount = await getReportCountForLab(labName, days: 3650); // ~10 tahun (all time)

    // Cari ID lab dari konstanta untuk direferensikan
    final labData = AppConstants.laboratories.firstWhere(
      (lab) => lab.name == labName,
      orElse: () => AppConstants.laboratories.first,
    );

    return LabSafetyInsight(
      labId: labData.id,
      labName: labName,
      recentReportCount: recentCount,
      totalReportCount: totalCount,
    );
  }

  /// Mengambil insight keselamatan untuk semua laboratorium sekaligus.
  /// (Digunakan untuk Dashboard monitoring).
  static Future<List<LabSafetyInsight>> getAllLabInsights() async {
    final List<LabSafetyInsight> insights = [];
    
    // Ambil data semua laporan dalam 7 hari terakhir sekaligus untuk optimasi query
    final reportsMap = await _getRecentReportsRawData(AppConstants.insightDays);
    
    for (final lab in AppConstants.laboratories) {
      // Hitung laporan untuk lab ini
      int recentCount = 0;
      for (final report in reportsMap.values) {
        if (report['locationName'] == lab.name) {
          recentCount++;
        }
      }

      // Untuk total, idealnya query terpisah per lab atau simpan counter di Firebase,
      // Tapi untuk simplicity prototype, kita pakai fallback ke method getReportCountForLab
      // agar tidak mendownload SELURUH database.
      final totalCount = await getReportCountForLab(lab.name, days: 3650);

      insights.add(LabSafetyInsight(
        labId: lab.id,
        labName: lab.name,
        recentReportCount: recentCount,
        totalReportCount: totalCount,
      ));
    }

    // Urutkan dari risiko paling tinggi ke rendah
    insights.sort((a, b) => b.recentReportCount.compareTo(a.recentReportCount));

    return insights;
  }

  /// Menghitung jumlah laporan di lokasi tertentu dalam N hari terakhir.
  static Future<int> getReportCountForLab(String labName, {int days = 7}) async {
    try {
      final now = DateTime.now();
      final thresholdDate = now.subtract(Duration(days: days));

      final snapshot = await _db.child('reports').get();
      if (!snapshot.exists || snapshot.value == null) return 0;

      final rawData = snapshot.value as Map;
      int count = 0;

      for (final value in rawData.values) {
        if (value is Map) {
          final reportLocation = value['locationName'] as String?;
          final createdAtStr = value['createdAt'] as String?;

          if (reportLocation == labName && createdAtStr != null) {
            final createdAt = DateTime.tryParse(createdAtStr);
            if (createdAt != null && createdAt.isAfter(thresholdDate)) {
              count++;
            }
          }
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Mengambil daftar laporan terbaru untuk suatu lab dalam N hari terakhir.
  static Future<List<ReportModel>> getRecentReportsForLab(String labName, {int days = 7}) async {
    try {
      final now = DateTime.now();
      final thresholdDate = now.subtract(Duration(days: days));

      final snapshot = await _db.child('reports').get();
      if (!snapshot.exists || snapshot.value == null) return [];

      final rawData = snapshot.value as Map;
      final List<ReportModel> recentReports = [];

      rawData.forEach((key, value) {
        if (value is Map) {
          final reportLocation = value['locationName'] as String?;
          final createdAtStr = value['createdAt'] as String?;

          if (reportLocation == labName && createdAtStr != null) {
            final createdAt = DateTime.tryParse(createdAtStr);
            if (createdAt != null && createdAt.isAfter(thresholdDate)) {
              // Convert to ReportModel. We assume value has the necessary fields.
              // Note: Make sure fromJson expects Map<String, dynamic>.
              try {
                final mappedValue = Map<String, dynamic>.from(value);
                mappedValue['id'] = key;
                recentReports.add(ReportModel.fromMap(mappedValue));
              } catch (e) {
                // Ignore malformed report
              }
            }
          }
        }
      });

      // Urutkan dari yang terbaru
      recentReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return recentReports;
    } catch (e) {
      return [];
    }
  }

  /// Helper untuk mendapatkan raw data laporan N hari terakhir.
  static Future<Map<String, dynamic>> _getRecentReportsRawData(int days) async {
    try {
      final now = DateTime.now();
      final thresholdDate = now.subtract(Duration(days: days));

      final snapshot = await _db.child('reports').get();
      if (!snapshot.exists || snapshot.value == null) return {};

      final rawData = snapshot.value as Map;
      final filteredData = <String, dynamic>{};

      rawData.forEach((key, value) {
        if (value is Map) {
          final createdAtStr = value['createdAt'] as String?;
          if (createdAtStr != null) {
            final createdAt = DateTime.tryParse(createdAtStr);
            if (createdAt != null && createdAt.isAfter(thresholdDate)) {
              filteredData[key.toString()] = value;
            }
          }
        }
      });

      return filteredData;
    } catch (e) {
      return {};
    }
  }
}
