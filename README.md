# LabSafe 🔒

**Aplikasi Pelaporan Aktivitas Mencurigakan di Laboratorium**

LabSafe adalah aplikasi mobile Flutter yang memungkinkan mahasiswa dan laboran melaporkan aktivitas mencurigakan secara cepat menggunakan sensor smartphone.

---

## 📱 Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 🔐 Login | Autentikasi dengan email/password kampus |
| 📊 Dashboard | Status sistem, statistik, dan laporan terbaru |
| 📳 Deteksi Shake | Guncangkan HP untuk trigger laporan darurat |
| 📍 GPS Lokasi | Deteksi lokasi otomatis |
| 📷 Kamera | Ambil foto bukti |
| 📤 Kirim Laporan | Laporan real-time ke petugas |
| 🔔 Notifikasi | Alert ke petugas keamanan |
| 📋 Riwayat | Histori semua laporan |

---

## 🛠️ Teknologi

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (siap integrasi)
- **Database**: Cloud Firestore (mock untuk development)
- **Storage**: Firebase Storage (mock)
- **Auth**: Firebase Authentication (mock)
- **Sensor**: `sensors_plus` (Accelerometer + Gyroscope)
- **GPS**: `geolocator`
- **Camera**: `image_picker`
- **State**: `provider`

---

## 🚀 Cara Menjalankan

### Prerequisites
- Flutter SDK 3.x
- Android Studio / VS Code
- Android Emulator atau device fisik

### Instalasi
```bash
# Clone atau buka folder project
cd "D:\SEMESTER 6\Mobile Computing\labsafe"

# Install dependencies
flutter pub get

# Jalankan di emulator/device
flutter run
```

### Login Demo
| Role | Email | Password |
|------|-------|----------|
| Mahasiswa | dhini@student.unila.ac.id | 12345678 |
| Laboran | laboran@unila.ac.id | laboran123 |
| Petugas | petugas@unila.ac.id | petugas123 |

---

## 📁 Struktur Project

```
lib/
├── core/
│   ├── theme/         # App theme & colors
│   ├── constants/     # App constants & lab data
│   └── utils/         # Date formatter
├── models/
│   ├── user_model.dart
│   └── report_model.dart
├── services/
│   ├── auth_service.dart      # Authentication
│   ├── report_service.dart    # Laporan CRUD
│   ├── location_service.dart  # GPS
│   └── sensor_service.dart    # Accelerometer + Gyroscope
├── providers/
│   ├── auth_provider.dart
│   └── report_provider.dart
├── screens/
│   ├── splash/         # Screen 1
│   ├── auth/           # Screen 2: Login
│   ├── dashboard/      # Screen 3: Dashboard
│   ├── shake/          # Screen 4-5: Shake detection
│   ├── report/         # Screen 6-8: Camera, Location, Confirm
│   ├── notification/   # Screen 9: Notifications
│   └── history/        # Screen 10: Report history
└── main.dart
```

---

## 🔧 Integrasi Firebase (Opsional)

Untuk mengaktifkan Firebase:
1. Buat project di [Firebase Console](https://console.firebase.google.com)
2. Download `google-services.json` dan letakkan di `android/app/`
3. Uncomment kode Firebase di `pubspec.yaml`
4. Replace mock services dengan implementasi Firebase yang nyata

---

## 📐 Sensor yang Digunakan

| Sensor | Fungsi | Package |
|--------|--------|---------|
| Accelerometer | Mendeteksi guncangan | `sensors_plus` |
| Gyroscope | Validasi arah gerakan | `sensors_plus` |
| GPS | Lokasi kejadian | `geolocator` |
| Camera | Bukti foto | `image_picker` |

---

## 👨‍💻 Dikembangkan oleh

Proyek Mobile Computing - Semester 6
Universitas Lampung
