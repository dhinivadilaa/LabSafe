import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/report_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/shake/shake_ready_screen.dart';
import 'screens/shake/shake_detected_screen.dart';
import 'screens/report/camera_screen.dart';
import 'screens/report/location_screen.dart';
import 'screens/report/confirm_report_screen.dart';
import 'screens/notification/notification_screen.dart';
import 'screens/history/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize push notifications
  await NotificationService.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const LabSafeApp());
}

class LabSafeApp extends StatelessWidget {
  const LabSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: 'LabSafe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return _route(const SplashScreen(), settings);
            case '/login':
              return _route(const LoginScreen(), settings);
            case '/dashboard':
              return _route(const DashboardScreen(), settings);
            case '/shake':
              return _route(const ShakeReadyScreen(), settings);
            case '/shake-detected':
              return _route(const ShakeDetectedScreen(), settings);
            case '/camera':
              return _route(const CameraScreen(), settings);
            case '/location':
              return _route(const LocationScreen(), settings);
            case '/confirm-report':
              return _route(const ConfirmReportScreen(), settings);
            case '/notifications':
              return _route(const NotificationScreen(), settings);
            case '/history':
              return _route(const HistoryScreen(), settings);
            default:
              return _route(const SplashScreen(), settings);
          }
        },
      ),
    );
  }

  PageRoute _route(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
            position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
