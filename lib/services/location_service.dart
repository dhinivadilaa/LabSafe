import 'package:geolocator/geolocator.dart';

class LocationService {
  static Position? _lastPosition;

  /// Request location permission and get current position (real GPS)
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Layanan lokasi (GPS) dinonaktifkan. Silakan aktifkan GPS di perangkat HP Anda.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Izin akses lokasi ditolak oleh pengguna.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Izin lokasi ditolak permanen. Aktifkan izin lokasi LabSafe di pengaturan HP Anda.';
    }

    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
      return _lastPosition;
    } catch (e) {
      throw 'Gagal mendapatkan sinyal GPS. Pastikan Anda berada di area terbuka dan coba lagi.';
    }
  }

  /// Find nearest lab based on coordinates
  static String getNearestLabName(double lat, double lng) {
    const labs = [
      {'name': 'Lab Komputer A', 'lat': -5.3642, 'lng': 105.2421},
      {'name': 'Lab Kimia', 'lat': -5.3650, 'lng': 105.2430},
      {'name': 'Lab Fisika', 'lat': -5.3655, 'lng': 105.2440},
      {'name': 'Lab Biologi', 'lat': -5.3660, 'lng': 105.2445},
      {'name': 'Lab Jaringan', 'lat': -5.3648, 'lng': 105.2428},
    ];

    String nearest = 'Laboratorium Kampus';
    double minDist = double.infinity;

    for (final lab in labs) {
      final dLat = (lab['lat'] as double) - lat;
      final dLng = (lab['lng'] as double) - lng;
      final dist = dLat * dLat + dLng * dLng;
      if (dist < minDist) {
        minDist = dist;
        nearest = lab['name'] as String;
      }
    }
    return nearest;
  }

  static Position? get lastPosition => _lastPosition;
}
