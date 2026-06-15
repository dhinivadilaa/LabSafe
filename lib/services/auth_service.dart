import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static UserModel? _currentUser;
  static UserModel? get currentUser => _currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Helper untuk mengkonversi Map dynamic/Object dari Realtime Database ke Map<String, dynamic>
  static Map<String, dynamic> _castMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _castMap(value));
      }
      return MapEntry(key.toString(), value);
    });
  }

  /// Login dengan email dan password
  static Future<UserModel?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user == null) return null;

      // Ambil data user dari Realtime Database
      final snapshot = await _db.child('users/${credential.user!.uid}').get();

      if (snapshot.exists && snapshot.value != null) {
        final rawData = snapshot.value as Map;
        final data = _castMap(rawData);
        _currentUser = UserModel.fromMap({
          'id': credential.user!.uid,
          ...data,
        });
      } else {
        // Jika user belum ada di Database, buat data default
        // asistenlab@gmail.com akan otomatis memiliki role 'asisten'
        final isAsisten = email.trim() == 'asistenlab@gmail.com';
        _currentUser = UserModel(
          id: credential.user!.uid,
          name: credential.user!.displayName ?? 'Pengguna',
          email: credential.user!.email ?? email,
          npm: '',
          role: isAsisten ? 'asisten' : 'mahasiswa',
          createdAt: DateTime.now(),
        );
        // Simpan ke Database
        await _db.child('users/${credential.user!.uid}').set(_currentUser!.toMap());
      }

      return _currentUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Register user baru
  static Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    required String npm,
    String role = 'mahasiswa',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await credential.user?.updateDisplayName(name);

      final isAsisten = email.trim() == 'asistenlab@gmail.com';
      final finalRole = isAsisten ? 'asisten' : role;

      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        npm: npm,
        role: finalRole,
        createdAt: DateTime.now(),
      );

      // Simpan ke Realtime Database
      await _db.child('users/${user.id}').set(user.toMap());

      _currentUser = user;
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Logout
  static Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
  }

  /// Reset password via email
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Cek status login saat app dibuka kembali
  static Future<UserModel?> checkAuthState() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final snapshot = await _db.child('users/${firebaseUser.uid}').get();
      if (snapshot.exists && snapshot.value != null) {
        final rawData = snapshot.value as Map;
        final data = _castMap(rawData);
        _currentUser = UserModel.fromMap({'id': firebaseUser.uid, ...data});
        return _currentUser;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Update foto profil (Base64)
  static Future<void> updateProfilePhoto(String base64Photo) async {
    final user = _currentUser;
    if (user == null) return;

    await _db.child('users/${user.id}/photoUrl').set(base64Photo);
    _currentUser = UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      npm: user.npm,
      role: user.role,
      photoUrl: base64Photo,
      createdAt: user.createdAt,
    );
  }

  /// Dashboard stats dari Realtime Database
  static Future<Map<String, int>> getDashboardStats() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Ambil seluruh laporan untuk menghitung statistik
      final reportsSnapshot = await _db.child('reports').get();
      int todayReportsCount = 0;
      int totalReportsCount = 0;

      if (reportsSnapshot.exists && reportsSnapshot.value != null) {
        final rawReports = reportsSnapshot.value as Map;
        final reports = _castMap(rawReports);
        totalReportsCount = reports.length;

        for (final reportData in reports.values) {
          final createdAtStr = reportData['createdAt'] as String?;
          if (createdAtStr != null) {
            final createdAt = DateTime.tryParse(createdAtStr);
            if (createdAt != null && createdAt.isAfter(startOfDay)) {
              todayReportsCount++;
            }
          }
        }
      }

      // Ambil user untuk menghitung jumlah petugas online
      final usersSnapshot = await _db.child('users').get();
      int officersCount = 0;
      if (usersSnapshot.exists && usersSnapshot.value != null) {
        final rawUsers = usersSnapshot.value as Map;
        final users = _castMap(rawUsers);
        for (final userData in users.values) {
          if (userData['role'] == 'petugas') {
            officersCount++;
          }
        }
      }

      return {
        'todayReports': todayReportsCount,
        'totalReports': totalReportsCount,
        'onlineOfficers': officersCount,
        'totalLabs': 5,
      };
    } catch (e) {
      return {
        'todayReports': 0,
        'totalReports': 0,
        'onlineOfficers': 0,
        'totalLabs': 5,
      };
    }
  }

  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar. Periksa kembali email Anda.';
      case 'wrong-password':
        return 'Password salah. Coba lagi.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'email-already-in-use':
        return 'Email sudah digunakan akun lain.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }
}
