/// Model typed untuk data laboratorium Teknik Elektro Universitas Lampung.
///
/// Menggantikan Map<String, dynamic> agar type-safe —
/// typo pada field name langsung terdeteksi saat compile time.
class LabLocation {
  /// Identifier unik lab (e.g., 'lab-ttt')
  final String id;

  /// Nama tampilan (e.g., 'Lab Teknik Tegangan Tinggi')
  final String name;

  /// Nama singkatan resmi lab (e.g., 'TTT')
  final String shortName;

  /// Nama gedung tempat lab berada (e.g., 'Gedung Teknik Elektro')
  final String building;

  /// Lantai tempat lab berada (e.g., 1, 2, 3)
  final int floor;

  /// Koordinat GPS lab (latitude)
  final double latitude;

  /// Koordinat GPS lab (longitude)
  final double longitude;

  /// Radius geofence dalam meter.
  /// User yang berada dalam radius ini dianggap "di dalam lab".
  /// Default: 30 meter (ukuran realistis ruang lab universitas).
  final double radiusMeters;

  const LabLocation({
    required this.id,
    required this.name,
    required this.shortName,
    required this.building,
    this.floor = 1,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 30.0,
  });

  @override
  String toString() => 'LabLocation($shortName: $name, $building Lt.$floor)';
}
