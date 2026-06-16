import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

import '../../models/location_result.dart';
import '../../models/lab_safety_insight.dart';
import '../../models/report_model.dart';
import '../../services/location_service.dart';
import '../../services/lab_safety_service.dart';
import '../../widgets/incident_timeline_item.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Position? _position;
  LocationResult? _locationResult;
  String _locationName = 'Mendeteksi lokasi...';
  bool _isLoading = true;
  String? _photoPath;
  LabSafetyInsight? _insight;
  List<ReportModel> _recentReports = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      _photoPath = args?['photoPath'];
      _fetchLocation();
    });
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null && mounted) {
        // Gunakan findNearestLab() yang sudah pakai Haversine + geofencing
        final result = LocationService.findNearestLab(position);
        
        // Fetch dynamic safety insight dari Firebase
        final insight = await LabSafetyService.getLabInsight(result.nearestLab.name);
        
        // Fetch recent reports untuk timeline
        final recentReports = await LabSafetyService.getRecentReportsForLab(result.nearestLab.name);
        
        if (mounted) {
          setState(() {
            _position = position;
            _locationResult = result;
            _locationName = result.nearestLab.name;
            _insight = insight;
            _recentReports = recentReports;
            _isLoading = false;
          });
        }
      } else {
        throw 'Lokasi tidak didapatkan.';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Akses GPS Gagal'),
            content: Text(e.toString()),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal', style: TextStyle(color: AppTheme.grey600)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  _fetchLocation();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _useLocation() {
    if (_position == null) return;
    
    // Strict Location Validation: Jika di luar lab, minta konfirmasi
    if (_locationResult != null && !_locationResult!.isInsideLab) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Konfirmasi Lokasi'),
          content: const Text(
            'Anda terdeteksi berada di luar area lab ini. Apakah Anda yakin ingin melaporkan insiden untuk lab ini?',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal', style: TextStyle(color: AppTheme.grey600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _proceedToConfirmReport();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningOrange),
              child: const Text('Ya, Lanjut Lapor'),
            ),
          ],
        ),
      );
    } else {
      _proceedToConfirmReport();
    }
  }

  void _proceedToConfirmReport() {
    Navigator.pushNamed(
      context,
      '/confirm-report',
      arguments: {
        'photoPath': _photoPath,
        'latitude': _position!.latitude,
        'longitude': _position!.longitude,
        'locationName': _locationName,
        // Kirim building name dari data lab (bukan hardcoded)
        'building': _locationResult != null
            ? '${_locationResult!.nearestLab.building}, Lt. ${_locationResult!.nearestLab.floor}'
            : 'Gedung Teknik Elektro',
      },
    );
  }

  void _showLabPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Laboratorium',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...AppConstants.laboratories.map((lab) => ListTile(
                  leading: const Icon(
                    Icons.science_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                  title: Text('${lab.name} (${lab.shortName})'),
                  subtitle: Text('${lab.building} • Lantai ${lab.floor}'),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onTap: () async {
                    setState(() => _isLoading = true);
                    final insight = await LabSafetyService.getLabInsight(lab.name);
                    final recentReports = await LabSafetyService.getRecentReportsForLab(lab.name);
                    
                    if (!context.mounted) return;
                    setState(() {
                      _locationName = lab.name;
                      _insight = insight;
                      _recentReports = recentReports;
                      // Update locationResult agar building ikut berubah
                      if (_position != null) {
                        _locationResult = LocationResult(
                          position: _position!,
                          nearestLab: lab,
                          distanceMeters: Geolocator.distanceBetween(
                            _position!.latitude,
                            _position!.longitude,
                            lab.latitude,
                            lab.longitude,
                          ),
                          isInsideLab: false,
                          isInsideCampus: true,
                        );
                      }
                      _isLoading = false;
                    });
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  /// Widget badge status geofence: hijau (di dalam), kuning (dekat), merah (luar)
  Widget _buildStatusBadge() {
    if (_locationResult == null) return const SizedBox.shrink();

    final result = _locationResult!;
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    if (result.isInsideLab) {
      badgeColor = AppTheme.successGreen;
      badgeIcon = Icons.check_circle_rounded;
      badgeText = 'Di Dalam Lab';
    } else if (result.isInsideCampus) {
      badgeColor = AppTheme.warningOrange;
      badgeIcon = Icons.info_rounded;
      badgeText = 'Di Area Kampus';
    } else {
      badgeColor = AppTheme.dangerRed;
      badgeIcon = Icons.warning_rounded;
      badgeText = 'Di Luar Area';
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 16),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentTimeline() {
    if (_recentReports.isEmpty) return const SizedBox.shrink();

    final displayReports = _recentReports;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline Insiden (7 Hari Terakhir)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.grey800,
            ),
          ),
          const SizedBox(height: 16),
          ...displayReports.asMap().entries.map((entry) {
            final index = entry.key;
            final report = entry.value;
            final isLast = index == displayReports.length - 1;
            
            return IncidentTimelineItem(
              report: report,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  /// Widget peringatan bahaya dinamis berdasarkan data laporan Firebase.
  Widget _buildDynamicInsight() {
    if (_insight == null) return const SizedBox.shrink();

    final color = _insight!.riskColor;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _insight!.riskIcon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TINGKAT RISIKO: ${_insight!.riskLabel.toUpperCase()}',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _insight!.insightMessage,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Peringatan tambahan jika user mencoba melapor dari luar lab
  Widget _buildOutsideWarning() {
    if (_locationResult == null || _locationResult!.isInsideLab) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_rounded, color: AppTheme.warningOrange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Anda berada di luar area lab. Pastikan Anda memilih lab yang benar sebelum mengirim laporan.',
              style: TextStyle(
                color: AppTheme.warningOrange.withOpacity(0.9),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Kejadian'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Map placeholder (styled to look like a map)
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE8F5E9), Color(0xFFE3F2FD)],
                    ),
                  ),
                  child: CustomPaint(
                    painter: _MapPatternPainter(),
                    size: Size.infinite,
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryBlue),
                    ),
                  ),
                // Location marker
                if (!_isLoading)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            _locationName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.location_pin,
                            color: AppTheme.dangerRed, size: 48),
                      ],
                    ),
                  ),
                // Compass button
                Positioned(
                  right: 16,
                  top: 16,
                  child: FloatingActionButton.small(
                    onPressed: _fetchLocation,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location_rounded,
                        color: AppTheme.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
          // Location info panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: AppTheme.dangerRed),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi Terdeteksi',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.grey600),
                          ),
                          Text(
                            _isLoading ? 'Memuat...' : _locationName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.grey800,
                            ),
                          ),
                          Text(
                            _isLoading
                                ? ''
                                // Tampilkan building + lantai dari data lab
                                : '${_locationResult?.nearestLab.building ?? "Gedung Teknik Elektro"}, Lt. ${_locationResult?.nearestLab.floor ?? 1}\nUniversitas Lampung\n${_position?.latitude.toStringAsFixed(6) ?? ''}, ${_position?.longitude.toStringAsFixed(6) ?? ''}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.grey600),
                          ),
                          // Tampilkan jarak aktual jika tersedia
                          if (!_isLoading && _locationResult != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _locationResult!.statusMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _locationResult!.isInsideLab
                                      ? AppTheme.successGreen
                                      : _locationResult!.isInsideCampus
                                          ? AppTheme.warningOrange
                                          : AppTheme.dangerRed,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Status badge geofence
                if (!_isLoading) _buildStatusBadge(),
                // Peringatan bahaya kontekstual berbasis data (Dynamic Insight)
                if (!_isLoading) _buildDynamicInsight(),
                // Incident Timeline
                if (!_isLoading) _buildIncidentTimeline(),
                // Peringatan jika user di luar lab
                if (!_isLoading) _buildOutsideWarning(),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: (_isLoading || _position == null) ? null : _useLocation,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('GUNAKAN LOKASI INI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                ),
                // Sembunyikan tombol "Pilih Lokasi Lain" jika user di dalam lab (Auto Lab Detection Locked)
                if (_locationResult == null || !_locationResult!.isInsideLab) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _showLabPicker,
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Pilih Lokasi Lain'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw grid lines to simulate a map
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some roads
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
        Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.3),
        roadPaint);
    canvas.drawLine(
        Offset(size.width * 0.4, 0),
        Offset(size.width * 0.4, size.height),
        roadPaint);
    canvas.drawLine(
        Offset(0, size.height * 0.65),
        Offset(size.width * 0.7, size.height * 0.65),
        roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
