// =============================================================
// FIREBASE OPTIONS TEMPLATE
// =============================================================
// File ini akan di-REPLACE secara otomatis oleh FlutterFire CLI
// setelah kamu menjalankan: flutterfire configure
//
// ATAU isi manual setelah download google-services.json dari Firebase Console
// =============================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ============================================================
  // ⚠️  GANTI SEMUA NILAI DI BAWAH INI
  // Ambil dari: Firebase Console → Project Settings → General
  // → Scroll ke "Your apps" → Android → google-services.json
  // ============================================================

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBtBxY7v8bjlKKX-1zdZkPVd7De0k1cFQc',
    appId: '1:101475056084:android:157b35e81f316f64af7e41',
    messagingSenderId: '101475056084',
    projectId: 'labsafe-bb2e7',
    storageBucket: 'labsafe-bb2e7.firebasestorage.app',
  );
}
