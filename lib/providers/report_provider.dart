import 'dart:io';
import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  List<ReportModel> _reports = [];
  List<ReportModel> _recentReports = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  int _todayCount = 0;
  int _totalCount = 0;

  List<ReportModel> get reports => _reports;
  List<ReportModel> get recentReports => _recentReports;
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  int get todayCount => _todayCount;
  int get totalCount => _totalCount;

  int get unreadNotifications =>
      _notifications.where((n) => n['read'] == false).length;

  Future<void> loadReports({String? userId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _reports = await ReportService.getReports(userId: userId);
      _totalCount = _reports.length;
    } catch (e) {
      _errorMessage = 'Gagal memuat laporan.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecentReports() async {
    try {
      // Gunakan stream untuk real-time update
      ReportService.getRecentReportsStream(limit: 3).listen((reports) {
        _recentReports = reports;
        notifyListeners();
      });
    } catch (e) {
      // silent fail
    }
  }

  Future<void> loadNotifications(String userId) async {
    try {
      ReportService.getNotificationsStream(userId).listen((notifs) {
        _notifications = notifs;
        notifyListeners();
      });
    } catch (e) {
      // silent fail
    }
  }

  Future<void> loadTodayCount() async {
    _todayCount = await ReportService.getTodayReportsCount();
    notifyListeners();
  }

  Future<ReportModel?> submitReport({
    required String reporterId,
    required String reporterName,
    required String reportType,
    required String description,
    required double latitude,
    required double longitude,
    required String locationName,
    File? photoFile,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final report = await ReportService.submitReport(
        reporterId: reporterId,
        reporterName: reporterName,
        reportType: reportType,
        description: description,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        photoFile: photoFile,
      );

      // Kirim notifikasi ke petugas
      await ReportService.sendNotificationToOfficers(
        reporterName: reporterName,
        locationName: locationName,
        reportId: report.id,
      );

      _reports.insert(0, report);
      _todayCount++;
      _totalCount++;
      _isSubmitting = false;
      notifyListeners();
      return report;
    } catch (e) {
      _errorMessage = 'Gagal mengirim laporan. Periksa koneksi internet.';
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> markNotificationRead(String id) async {
    await ReportService.markNotificationRead(id);
    final idx = _notifications.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      _notifications[idx] = {..._notifications[idx], 'read': true};
      notifyListeners();
    }
  }

  Future<bool> updateReportStatusAndNotify({
    required String reportId,
    required String reporterId,
    required String status,
    String? handledBy,
    String? notes,
  }) async {
    try {
      await ReportService.updateReportStatus(
        reportId: reportId,
        status: status,
        handledBy: handledBy,
        notes: notes,
      );

      // Kirim notifikasi ke reporter
      await ReportService.sendNotificationToReporter(
        reporterId: reporterId,
        reportId: reportId,
        title: 'Laporan Ditindaklanjuti',
        message: 'Terimakasih atas partisipasi anda melaporkan aktivitas mencurigakan, kami akan segera menindak lanjuti',
      );

      // Reload
      await loadReports();
      return true;
    } catch (e) {
      return false;
    }
  }
}
