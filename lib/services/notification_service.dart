import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background message handler (harus top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background notification
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'labsafe_alerts',
    'LabSafe Alerts',
    description: 'Notifikasi laporan LabSafe',
    importance: Importance.high,
    playSound: true,
  );

  /// Inisialisasi semua notification services
  static Future<void> initialize() async {
    // Setup background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setup local notifications untuk Android
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Buat channel Android
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Simpan FCM token
    await _saveFcmToken();
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle tap on notification - navigate to notification screen
  }

  static Future<void> _saveFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }
    } catch (e) {
      // ignore
    }
  }

  static Future<String?> getFcmToken() async {
    return await _fcm.getToken();
  }

  /// Subscribe ke topik (untuk petugas keamanan)
  static Future<void> subscribeToOfficerAlerts() async {
    await _fcm.subscribeToTopic('officer_alerts');
  }

  /// Unsubscribe
  static Future<void> unsubscribeFromOfficerAlerts() async {
    await _fcm.unsubscribeFromTopic('officer_alerts');
  }
}
