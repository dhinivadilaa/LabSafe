import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/location_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Position? _position;
  String _locationName = 'Mendeteksi lokasi...';
  bool _isLoading = true;
  String? _photoPath;

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
        final labName = LocationService.getNearestLabName(
            position.latitude, position.longitude);
        setState(() {
          _position = position;
          _locationName = labName;
          _isLoading = false;
        });
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
    Navigator.pushNamed(
      context,
      '/confirm-report',
      arguments: {
        'photoPath': _photoPath,
        'latitude': _position!.latitude,
        'longitude': _position!.longitude,
        'locationName': _locationName,
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
                  leading: const Icon(Icons.science_rounded,
                      color: AppTheme.primaryBlue),
                  title: Text(lab['name']),
                  subtitle: Text(lab['building']),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    setState(() {
                      _locationName = lab['name'];
                    });
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
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
                    Column(
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
                              : 'Gedung F, Universitas Lampung\n${_position?.latitude.toStringAsFixed(4) ?? ''}, ${_position?.longitude.toStringAsFixed(4) ?? ''}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: (_isLoading || _position == null) ? null : _useLocation,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('GUNAKAN LOKASI INI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                ),
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
