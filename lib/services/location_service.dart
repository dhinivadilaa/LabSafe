import 'package:geolocator/geolocator.dart';
import '../core/constants/app_constants.dart';
import '../models/lab_location.dart';
import '../models/location_result.dart';

/// Service untuk mengelola akses GPS dan deteksi laboratorium terdekat.
///
/// Level 2: Context-Aware Geofencing
/// - Menggunakan Geolocator.distanceBetween() (Haversine) untuk jarak akurat dalam meter
/// - Geofencing berbasis radius per lab
/// - Single source of truth dari AppConstants.laboratories
class LocationService {
  static Position? _lastPosition;
  static LocationResult? _lastLocationResult;

  /// Request location permission dan ambil posisi GPS terkini.
  ///
  /// Method ini tidak berubah dari versi sebelumnya — hanya mengurus
  /// permission handling dan pengambilan koordinat GPS.
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

  /// Cari lab terdekat dan tentukan konteks lokasi user.
  ///
  /// Menggunakan [Geolocator.distanceBetween] yang mengimplementasikan
  /// rumus Haversine — menghitung jarak geodesik (great-circle distance)
  /// di permukaan bumi, menghasilkan jarak dalam **meter**.
  ///
  /// Kenapa bukan dLat² + dLng² (versi lama)?
  /// → Karena 1° latitude ≠ 1° longitude dalam satuan meter.
  ///   Di khatulistiwa, 1° lat ≈ 111 km, tapi 1° lng ≈ 111 × cos(lat) km.
  ///   Haversine memperhitungkan kelengkungan bumi secara akurat.
  ///
  /// Returns [LocationResult] berisi:
  /// - Lab terdekat ([LabLocation])
  /// - Jarak aktual dalam meter
  /// - Status geofence (di dalam lab / di area kampus / di luar)
  static LocationResult findNearestLab(Position position) {
    const labs = AppConstants.laboratories;

    LabLocation nearestLab = labs.first;
    double minDistance = double.infinity;

    for (final lab in labs) {
      // Haversine distance — akurat untuk jarak pendek maupun jauh
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lab.latitude,
        lab.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestLab = lab;
      }
    }

    // Geofencing: tentukan apakah user di dalam lab atau di area kampus
    final isInsideLab = minDistance <= nearestLab.radiusMeters;
    final isInsideCampus = minDistance <= AppConstants.campusRadiusMeters;

    final result = LocationResult(
      position: position,
      nearestLab: nearestLab,
      distanceMeters: minDistance,
      isInsideLab: isInsideLab,
      isInsideCampus: isInsideCampus,
    );

    _lastLocationResult = result;
    return result;
  }

  /// Backward-compatible wrapper — mengembalikan nama lab terdekat saja.
  ///
  /// Dipertahankan agar kode lain yang masih memanggil method ini
  /// tidak langsung rusak. Secara internal sudah pakai Haversine.
  static String getNearestLabName(double lat, double lng) {
    // Buat Position sementara untuk kompatibilitas
    final result = findNearestLab(
      Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );
    return result.nearestLab.name;
  }

  static Position? get lastPosition => _lastPosition;
  static LocationResult? get lastLocationResult => _lastLocationResult;
}
