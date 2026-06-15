import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';

class ReportService {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();
  static const _uuid = Uuid();

  /// Helper untuk mengkonversi Map dynamic/Object dari Realtime Database ke Map<String, dynamic>
  static Map<String, dynamic> _castMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _castMap(value));
      }
      return MapEntry(key.toString(), value);
    });
  }

  /// Ambil semua laporan (untuk admin/petugas/asisten) atau per user
  static Future<List<ReportModel>> getReports({String? userId}) async {
    try {
      final snapshot = await _db.child('reports').get();
      if (!snapshot.exists || snapshot.value == null) return [];

      final rawData = snapshot.value as Map;
      final data = _castMap(rawData);

      final reports = data.entries.map((entry) {
        final map = Map<String, dynamic>.from(entry.value as Map);
        return ReportModel.fromMap({'id': entry.key, ...map});
      }).toList();

      // Urutkan berdasarkan tanggal dibuat (terbaru dahulu)
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (userId != null) {
        return reports.where((r) => r.reporterId == userId).toList();
      }

      return reports;
    } catch (e) {
      return [];
    }
  }

  /// Laporan terbaru untuk dashboard (real-time)
  static Stream<List<ReportModel>> getRecentReportsStream({int limit = 3}) {
    return _db.child('reports').onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];

      final rawData = snapshot.value as Map;
      final data = _castMap(rawData);

      final reports = data.entries.map((entry) {
        final map = Map<String, dynamic>.from(entry.value as Map);
        return ReportModel.fromMap({'id': entry.key, ...map});
      }).toList();

      // Urutkan terbaru dahulu
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return reports.take(limit).toList();
    });
  }

  /// Jumlah laporan hari ini
  static Future<int> getTodayReportsCount() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final snapshot = await _db.child('reports').get();
      if (!snapshot.exists || snapshot.value == null) return 0;

      final rawData = snapshot.value as Map;
      final data = _castMap(rawData);

      int count = 0;
      for (final reportVal in data.values) {
        final createdAtStr = reportVal['createdAt'] as String?;
        if (createdAtStr != null) {
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt != null && createdAt.isAfter(startOfDay)) {
            count++;
          }
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Konversi foto ke Base64 lalu kirim laporan ke Realtime Database
  static Future<ReportModel> submitReport({
    required String reporterId,
    required String reporterName,
    required String reportType,
    required String description,
    required double latitude,
    required double longitude,
    required String locationName,
    File? photoFile,
  }) async {
    String? photoUrl;

    // 1. Konversi foto ke Base64 jika ada
    if (photoFile != null) {
      photoUrl = await _encodePhotoToBase64(photoFile);
    }

    // 2. Buat dokumen laporan di Realtime Database
    final reportId = _uuid.v4();
    final now = DateTime.now();

    final reportData = {
      'id': reportId,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportType': reportType,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'photoUrl': photoUrl,
      'status': 'Menunggu',
      'createdAt': now.toIso8601String(),
      'updatedAt': null,
      'handledBy': null,
      'notes': null,
    };

    await _db.child('reports/$reportId').set(reportData);

    return ReportModel.fromMap(reportData);
  }

  /// Konversi berkas foto menjadi string Base64
  static Future<String?> _encodePhotoToBase64(File photo) async {
    try {
      final bytes = await photo.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  /// Update status laporan
  static Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? handledBy,
    String? notes,
  }) async {
    final updates = {
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
      if (handledBy != null) 'handledBy': handledBy,
      if (notes != null) 'notes': notes,
    };
    await _db.child('reports/$reportId').update(updates);
  }

  /// Hapus laporan
  static Future<void> deleteReport(String reportId) async {
    await _db.child('reports/$reportId').remove();
  }

  /// Notifikasi dari Realtime Database (real-time)
  static Stream<List<Map<String, dynamic>>> getNotificationsStream(
      String userId) {
    return _db.child('notifications').onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];

      final rawData = snapshot.value as Map;
      final data = _castMap(rawData);

      final list = data.entries.map((entry) {
        final map = Map<String, dynamic>.from(entry.value as Map);
        return {
          'id': entry.key,
          'type': map['type'] ?? 'info',
          'title': map['title'] ?? 'Notifikasi',
          'message': map['message'] ?? '',
          'time': map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
          'read': map['read'] ?? false,
          'reportId': map['reportId'],
          'targetUserId': map['targetUserId'],
        };
      }).where((n) => n['targetUserId'] == userId).toList();

      // Urutkan dari yang terbaru
      list.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

      return list;
    });
  }

  /// Tandai notifikasi sebagai dibaca
  static Future<void> markNotificationRead(String notifId) async {
    await _db.child('notifications/$notifId').update({'read': true});
  }

  /// Kirim notifikasi ke petugas/asisten (dipanggil setelah submit laporan)
  static Future<void> sendNotificationToOfficers({
    required String reporterName,
    required String locationName,
    required String reportId,
  }) async {
    // Ambil semua user yang ber-role 'asisten', 'petugas', 'laboran', atau 'admin'
    final usersSnapshot = await _db.child('users').get();
    if (!usersSnapshot.exists || usersSnapshot.value == null) return;

    final rawData = usersSnapshot.value as Map;
    final users = _castMap(rawData);

    final now = DateTime.now().toIso8601String();

    for (final entry in users.entries) {
      final userId = entry.key;
      final userData = entry.value as Map;
      final role = userData['role'] as String?;

      if (role == 'asisten' || role == 'petugas' || role == 'laboran' || role == 'admin') {
        final notifId = _uuid.v4();
        await _db.child('notifications/$notifId').set({
          'targetUserId': userId,
          'type': 'new',
          'title': 'Laporan Baru!',
          'message':
              'Aktivitas mencurigakan dilaporkan oleh $reporterName di $locationName',
          'reportId': reportId,
          'read': false,
          'createdAt': now,
        });
      }
    }
  }

  /// Kirim notifikasi ke reporter (mahasiswa) saat laporan ditindaklanjuti
  static Future<void> sendNotificationToReporter({
    required String reporterId,
    required String reportId,
    required String title,
    required String message,
  }) async {
    final now = DateTime.now().toIso8601String();
    final notifId = _uuid.v4();
    await _db.child('notifications/$notifId').set({
      'targetUserId': reporterId,
      'type': 'processing',
      'title': title,
      'message': message,
      'reportId': reportId,
      'read': false,
      'createdAt': now,
    });
  }
}
