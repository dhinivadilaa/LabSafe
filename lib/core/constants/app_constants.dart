import '../../models/lab_location.dart';

class AppConstants {
  // App Info
  static const String appName = 'LabSafe';
  static const String appVersion = '1.0.0';
  static const String appTagline =
      'Aplikasi Pelaporan Aktivitas Mencurigakan di Laboratorium';

  // Shake Detection
  static const double shakeThreshold = 15.0;
  static const double gyroThreshold = 3.0;
  static const int shakeCountRequired = 3;
  static const int shakeCooldownMs = 1000;

  // ─── Geofencing Thresholds ───
  /// Radius default "di dalam lab" dalam meter.
  /// User yang jaraknya <= radius ini dari titik pusat lab
  /// dianggap berada di dalam lab tersebut.
  static const double labRadiusMeters = 50.0;

  /// Radius "di area kampus" dalam meter.
  /// User yang jaraknya <= radius ini dari lab terdekat
  /// masih dianggap berada di lingkungan kampus.
  static const double campusRadiusMeters = 500.0;

  // ─── Dynamic Safety Insight Thresholds ───
  /// Jumlah laporan untuk kategori "Risiko Tinggi" (High Risk)
  static const int highRiskThreshold = 5;

  /// Jumlah laporan untuk kategori "Risiko Sedang" (Medium Risk)
  static const int mediumRiskThreshold = 2;

  /// Jendela waktu (dalam hari) untuk menganalisis risiko lab
  static const int insightDays = 7;

  // ─── Lab Registry Teknik Elektro Unila (Single Source of Truth) ───
  //
  // Koordinat berdasarkan estimasi posisi gedung Teknik Elektro
  // di kampus Universitas Lampung, Bandar Lampung.
  // Pusat area: sekitar -5.3643, 105.2425 (Fakultas Teknik Unila)
  //
  // PENTING: Untuk akurasi maksimal, verifikasi koordinat dengan
  // berdiri di depan masing-masing lab lalu catat GPS dari Google Maps.
  static const List<LabLocation> laboratories = [
    // ── Lantai 1 ──
    LabLocation(
      id: 'lab-stl',
      name: 'Lab Sistem Tenaga Listrik',
      shortName: 'STL',
      building: 'Gedung Teknik Elektro',
      floor: 1,
      latitude: -5.36430,
      longitude: 105.24210,
      radiusMeters: 25.0,
    ),
    LabLocation(
      id: 'lab-ttt',
      name: 'Lab Teknik Tegangan Tinggi',
      shortName: 'TTT',
      building: 'Gedung Teknik Elektro',
      floor: 1,
      latitude: -5.36440,
      longitude: 105.24218,
      radiusMeters: 30.0,
    ),
    LabLocation(
      id: 'lab-kee',
      name: 'Lab Konversi Energi Elektrik',
      shortName: 'KEE',
      building: 'Gedung Teknik Elektro',
      floor: 1,
      latitude: -5.36450,
      longitude: 105.24225,
      radiusMeters: 25.0,
    ),
    LabLocation(
      id: 'lab-kendali',
      name: 'Lab Kendali',
      shortName: 'Kendali',
      building: 'Gedung Teknik Elektro',
      floor: 1,
      latitude: -5.36438,
      longitude: 105.24235,
      radiusMeters: 25.0,
    ),
    // ── Lantai 2 ──
    LabLocation(
      id: 'lab-elektronika',
      name: 'Lab Elektronika',
      shortName: 'Elektronika',
      building: 'Gedung Teknik Elektro',
      floor: 2,
      latitude: -5.36435,
      longitude: 105.24242,
      radiusMeters: 25.0,
    ),
    LabLocation(
      id: 'lab-pbl',
      name: 'Lab PBL',
      shortName: 'PBL',
      building: 'Gedung Teknik Elektro',
      floor: 2,
      latitude: -5.36442,
      longitude: 105.24250,
      radiusMeters: 25.0,
    ),
    LabLocation(
      id: 'lab-telti',
      name: 'Lab Telekomunikasi dan Informasi',
      shortName: 'TELTI',
      building: 'Gedung Teknik Elektro',
      floor: 2,
      latitude: -5.36448,
      longitude: 105.24258,
      radiusMeters: 25.0,
    ),
    // ── Lantai 3 ──
    LabLocation(
      id: 'lab-komputer',
      name: 'Lab Komputer',
      shortName: 'Komputer',
      building: 'Gedung Teknik Elektro',
      floor: 3,
      latitude: -5.36445,
      longitude: 105.24265,
      radiusMeters: 30.0,
    ),
    LabLocation(
      id: 'lab-digital',
      name: 'Lab Digital',
      shortName: 'Digital',
      building: 'Gedung Teknik Elektro',
      floor: 3,
      latitude: -5.36452,
      longitude: 105.24272,
      radiusMeters: 25.0,
    ),
  ];

  // Report Status
  static const String statusPending = 'Menunggu';
  static const String statusProcessing = 'Diproses';
  static const String statusDone = 'Selesai';
  static const String statusRejected = 'Ditolak';

  // Report Types
  static const List<String> reportTypes = [
    'Aktivitas Mencurigakan',
    'Pencurian Peralatan',
    'Akses Tidak Sah',
    'Kerusakan Fasilitas',
    'Bahaya Kebakaran',
    'Lainnya',
  ];
}
