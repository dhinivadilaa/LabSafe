import 'package:geolocator/geolocator.dart';
import 'lab_location.dart';

/// Data Transfer Object yang membawa konteks lokasi lengkap
/// dari LocationService ke UI layer.
///
/// Prinsip separation of concerns: UI tidak perlu menghitung jarak
/// atau menentukan apakah user di dalam/luar lab — service yang
/// menyediakan informasi ini secara langsung.
class LocationResult {
  /// Posisi GPS asli dari perangkat pengguna
  final Position position;

  /// Lab terdekat berdasarkan perhitungan Haversine
  final LabLocation nearestLab;

  /// Jarak user ke lab terdekat dalam meter (akurat, Haversine)
  final double distanceMeters;

  /// Apakah user berada di dalam radius geofence lab terdekat
  final bool isInsideLab;

  /// Apakah user masih berada di area kampus (radius lebih besar)
  final bool isInsideCampus;

  const LocationResult({
    required this.position,
    required this.nearestLab,
    required this.distanceMeters,
    required this.isInsideLab,
    required this.isInsideCampus,
  });

  /// Pesan status kontekstual untuk ditampilkan di UI.
  ///
  /// Format:
  /// - "Di dalam Lab TTT (23 m)" → di dalam radius lab
  /// - "Di dekat Lab Kendali (120 m)" → di area kampus, tapi di luar lab
  /// - "Di luar area kampus (2.3 km)" → terlalu jauh dari semua lab
  String get statusMessage {
    if (isInsideLab) {
      return 'Di dalam ${nearestLab.name} (${_formatDistance(distanceMeters)})';
    } else if (isInsideCampus) {
      return 'Di dekat ${nearestLab.name} (${_formatDistance(distanceMeters)})';
    } else {
      return 'Di luar area kampus (${_formatDistance(distanceMeters)})';
    }
  }

  /// Format jarak agar mudah dibaca:
  /// - < 1000m → "123 m"
  /// - >= 1000m → "1.2 km"
  static String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
}
