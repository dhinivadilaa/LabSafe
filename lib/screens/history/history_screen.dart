import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _tabs;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    final bool isStaff = user?.role == 'asisten';
    _tabs = isStaff
        ? ['Semua', 'Diterima', 'Ditindak Lanjut']
        : ['Semua', 'Terkirim', 'Ditindaklanjuti'];
    _tabController = TabController(length: _tabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReports(userId: isStaff ? null : user?.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ReportModel> _filterReports(List<ReportModel> all, String tab) {
    if (tab == 'Semua') return all;
    if (tab == 'Diterima' || tab == 'Terkirim') {
      return all.where((r) => r.status == 'Terkirim').toList();
    }
    return all.where((r) => r.status == 'Ditindaklanjuti').toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final bool isStaff = user?.role == 'asisten';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Laporan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Consumer<ReportProvider>(
        builder: (context, report, _) {
          if (report.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) {
              final filtered = _filterReports(report.reports, tab);
              return _buildReportList(filtered, isStaff);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildReportList(List<ReportModel> reports, bool isStaff) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded,
                size: 64, color: AppTheme.grey400),
            const SizedBox(height: 12),
            const Text('Belum ada laporan',
                style: TextStyle(color: AppTheme.grey600, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final user = context.read<AuthProvider>().user;
        final bool isStaff = user?.role == 'asisten';
        await context.read<ReportProvider>().loadReports(userId: isStaff ? null : user?.id);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, i) => _buildReportCard(reports[i], isStaff),
      ),
    );
  }

  Widget _buildReportImage(String? photoUrl, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Container(
        color: AppTheme.primaryBlue.withOpacity(0.12),
        child: const Icon(Icons.science_rounded,
            color: AppTheme.primaryBlue, size: 36),
      );
    }

    if (photoUrl.startsWith('local:')) {
      final localPath = photoUrl.replaceFirst('local:', '');
      return Image.file(
        File(localPath),
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (c, e, s) => _placeholderIcon(),
      );
    }

    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return Image.network(
        photoUrl,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (c, e, s) => _placeholderIcon(),
      );
    }

    // Otherwise, assume it's a Base64 string
    try {
      final bytes = base64Decode(photoUrl.trim());
      return Image.memory(
        bytes,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (c, e, s) => _placeholderIcon(),
      );
    } catch (e) {
      return _placeholderIcon();
    }
  }

  Widget _placeholderIcon() {
    return Container(
      color: AppTheme.primaryBlue.withOpacity(0.12),
      child: const Icon(Icons.science_rounded,
          color: AppTheme.primaryBlue, size: 36),
    );
  }

  Widget _buildReportCard(ReportModel report, bool isStaff) {
    final statusColor = _getStatusColor(report.status);

    return GestureDetector(
      onTap: () => _showReportDetail(report),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Photo or placeholder
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 80,
                height: 90,
                child: _buildReportImage(report.photoUrl, fit: BoxFit.cover),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            report.locationName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.grey800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            report.displayStatus(isStaff),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.formatShort(report.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.grey600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.reportType,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.grey600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDetail(ReportModel report) {
    final statusColor = _getStatusColor(report.status);
    final user = context.read<AuthProvider>().user;
    final bool isStaff = user?.role == 'asisten';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Detail Laporan',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.24)),
                  ),
                  child: Text(report.displayStatus(isStaff),
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailItem(Icons.warning_rounded, 'Jenis', report.reportType,
                AppTheme.dangerRed),
            _detailItem(Icons.location_on_rounded, 'Lokasi',
                report.locationName, AppTheme.primaryBlue),
            _detailItem(Icons.access_time_rounded, 'Waktu',
                DateFormatter.formatShort(report.createdAt),
                AppTheme.successGreen),
            _detailItem(Icons.person_rounded, 'Pelapor',
                report.reporterName, AppTheme.warningOrange),
            if (report.description.isNotEmpty)
              _detailItem(Icons.description_rounded, 'Deskripsi',
                  report.description, AppTheme.grey600),
            if (report.photoUrl != null && report.photoUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Bukti Foto',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.grey800)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: _buildReportImage(report.photoUrl, fit: BoxFit.cover),
                ),
              ),
            ],
            if (isStaff && report.status == 'Terkirim') ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _handleReportAction(context, report),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Tindak Lanjuti Laporan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerRed,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleReportAction(BuildContext context, ReportModel report) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Tindak Lanjuti Laporan'),
        content: const Text('Apakah Anda yakin ingin menindaklanjuti laporan ini?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.grey600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
              _updateStatus(report, 'Ditindaklanjuti');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
            child: const Text('Tindak Lanjuti'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(ReportModel report, String status) async {
    final user = context.read<AuthProvider>().user;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await context.read<ReportProvider>().updateReportStatusAndNotify(
      reportId: report.id,
      reporterId: report.reporterId,
      status: status,
      handledBy: user?.name,
    );

    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Laporan berhasil ditindaklanjuti'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui status laporan'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  Widget _detailItem(
      IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.grey600)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Ditindaklanjuti':
        return AppTheme.successGreen;
      default:
        return AppTheme.primaryBlue;
    }
  }
}
