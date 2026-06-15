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

  // Labs
  static const List<Map<String, dynamic>> laboratories = [
    {
      'name': 'Lab Komputer A',
      'building': 'Gedung F',
      'lat': -5.3642,
      'lng': 105.2421,
    },
    {
      'name': 'Lab Komputer B',
      'building': 'Gedung F',
      'lat': -5.3643,
      'lng': 105.2422,
    },
    {
      'name': 'Lab Kimia',
      'building': 'Gedung G',
      'lat': -5.3650,
      'lng': 105.2430,
    },
    {
      'name': 'Lab Fisika',
      'building': 'Gedung H',
      'lat': -5.3655,
      'lng': 105.2440,
    },
    {
      'name': 'Lab Biologi',
      'building': 'Gedung I',
      'lat': -5.3660,
      'lng': 105.2445,
    },
    {
      'name': 'Lab Jaringan',
      'building': 'Gedung F',
      'lat': -5.3648,
      'lng': 105.2428,
    },
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
