import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';

class ConfirmReportScreen extends StatefulWidget {
  const ConfirmReportScreen({super.key});

  @override
  State<ConfirmReportScreen> createState() => _ConfirmReportScreenState();
}

class _ConfirmReportScreenState extends State<ConfirmReportScreen> {
  String? _photoPath;
  double _latitude = -5.3642;
  double _longitude = 105.2421;
  String _locationName = 'Lab Komputer A';
  String _reportType = AppConstants.reportTypes.first;
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) {
        setState(() {
          _photoPath = args['photoPath'];
          _latitude = args['latitude'] ?? -5.3642;
          _longitude = args['longitude'] ?? 105.2421;
          _locationName = args['locationName'] ?? 'Lab Komputer A';
        });
      }
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final auth = context.read<AuthProvider>();
    final reportProv = context.read<ReportProvider>();
    final user = auth.user;

    if (user == null) return;

    final report = await reportProv.submitReport(
      reporterId: user.id,
      reporterName: user.name,
      reportType: _reportType,
      description: _descController.text.isNotEmpty
          ? _descController.text
          : 'Aktivitas mencurigakan terdeteksi di $_locationName.',
      latitude: _latitude,
      longitude: _longitude,
      locationName: _locationName,
      photoFile: _photoPath != null ? File(_photoPath!) : null,
    );

    if (report != null && mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.successGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 50),
            ),
            const SizedBox(height: 20),
            const Text(
              'Laporan Terkirim!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.successGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Laporan Anda telah berhasil dikirim. Asisten praktikum akan segera menindaklanjuti.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.grey600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/dashboard', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Laporan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Laporan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey800,
              ),
            ),
            const SizedBox(height: 16),
            // Report type
            _detailRow(
              icon: Icons.warning_rounded,
              color: AppTheme.dangerRed,
              label: 'Jenis Laporan',
              child: DropdownButton<String>(
                value: _reportType,
                underline: const SizedBox(),
                isExpanded: true,
                items: AppConstants.reportTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (v) => setState(() => _reportType = v!),
              ),
            ),
            _detailRow(
              icon: Icons.location_on_rounded,
              color: AppTheme.primaryBlue,
              label: 'Lokasi',
              value: _locationName,
            ),
            _detailRow(
              icon: Icons.access_time_rounded,
              color: AppTheme.successGreen,
              label: 'Waktu',
              value: DateFormatter.formatShort(DateTime.now()),
            ),
            // Description
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 8),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warningOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.description_rounded,
                            color: AppTheme.warningOrange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Deskripsi (opsional)',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.grey800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Jelaskan aktivitas mencurigakan yang Anda lihat...',
                      hintStyle: TextStyle(
                          color: AppTheme.grey400, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppTheme.grey200),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Photo preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 8),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.photo_camera_rounded,
                            color: AppTheme.accentCyan, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Bukti Foto',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.grey800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_photoPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Image.file(
                            File(_photoPath!),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Lihat Foto',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.grey100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.grey200,
                            style: BorderStyle.solid),
                      ),
                      child: const Center(
                        child: Text(
                          'Tidak ada foto',
                          style: TextStyle(color: AppTheme.grey600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Consumer<ReportProvider>(
              builder: (context, report, _) {
                return ElevatedButton.icon(
                  onPressed: report.isSubmitting ? null : _submitReport,
                  icon: report.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                      report.isSubmitting ? 'Mengirim...' : 'KIRIM LAPORAN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerRed,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required Color color,
    required String label,
    String? value,
    Widget? child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.grey600)),
                if (value != null)
                  Text(
                    value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                if (child != null) child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
