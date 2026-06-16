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
  double _latitude = -5.36430;
  double _longitude = 105.24210;
  String _locationName = 'Lab Sistem Tenaga Listrik';
  String _building = 'Gedung Teknik Elektro';
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
          _latitude = args['latitude'] ?? -5.36430;
          _longitude = args['longitude'] ?? 105.24210;
          _locationName = args['locationName'] ?? 'Lab Sistem Tenaga Listrik';
          _building = args['building'] ?? 'Gedung Teknik Elektro';
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.successGreen, size: 56),
              ),
              const SizedBox(height: 24),
              const Text(
                'Laporan Terkirim!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.grey800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Terima kasih, kontribusi Anda sangat berarti untuk membantu kami menjaga keselamatan laboratorium bersama.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.grey600, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/dashboard', (route) => false);
                  },
                  child: const Text('Kembali ke Dashboard'),
                ),
              ),
            ],
          ),
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
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Informasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey800,
              ),
            ),
            const SizedBox(height: 16),
            // Report type
            _detailRow(
              icon: Icons.warning_rounded,
              color: AppTheme.warningOrange,
              label: 'Kategori Insiden',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _reportType,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.grey600),
                  items: AppConstants.reportTypes
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.grey800)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _reportType = v!),
                ),
              ),
            ),
            _detailRow(
              icon: Icons.location_on_rounded,
              color: AppTheme.primaryBlue,
              label: 'Lokasi Terdeteksi',
              value: '$_locationName\n$_building',
            ),
            _detailRow(
              icon: Icons.access_time_rounded,
              color: AppTheme.successGreen,
              label: 'Waktu Kejadian',
              value: DateFormatter.formatShort(DateTime.now()),
            ),
            const SizedBox(height: 8),
            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.grey200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.notes_rounded,
                            color: AppTheme.grey600, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Deskripsi Tambahan',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.grey800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Jelaskan secara singkat apa yang terjadi...',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Photo preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.grey200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: AppTheme.grey600, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Bukti Lampiran',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.grey800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_photoPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.file(
                            File(_photoPath!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryDark.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Terlampir',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.grey50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.grey200,
                            style: BorderStyle.solid),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported_rounded, color: AppTheme.grey400, size: 32),
                            SizedBox(height: 8),
                            Text(
                              'Tidak ada foto terlampir',
                              style: TextStyle(color: AppTheme.grey600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Consumer<ReportProvider>(
              builder: (context, report, _) {
                return ElevatedButton(
                  onPressed: report.isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerRed, // Action ini tetap merah karena urgensi
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (report.isSubmitting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.send_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(report.isSubmitting ? 'Mengirim...' : 'Kirim Laporan Segera'),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.grey600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                if (value != null)
                  Text(
                    value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.grey800),
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
