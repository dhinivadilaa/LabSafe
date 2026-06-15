import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/constants/app_constants.dart';


/// Sensor Service – Accelerometer & Gyroscope for shake detection
class SensorService {
  static StreamSubscription<AccelerometerEvent>? _accelSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  static double _lastX = 0, _lastY = 0, _lastZ = 0;
  static int _shakeCount = 0;
  static DateTime? _lastShakeTime;
  static bool _isListening = false;

  static double _gyroX = 0, _gyroY = 0, _gyroZ = 0;

  /// Start listening to shake gestures
  /// [onShakeDetected] is called when shake threshold is reached
  static void startListening({required VoidCallback onShakeDetected}) {
    if (_isListening) return;
    _isListening = true;
    _shakeCount = 0;

    // Listen to gyroscope for validation
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      _gyroX = event.x;
      _gyroY = event.y;
      _gyroZ = event.z;
    });

    // Listen to accelerometer for shake detection
    _accelSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      final double deltaX = event.x - _lastX;
      final double deltaY = event.y - _lastY;
      final double deltaZ = event.z - _lastZ;

      _lastX = event.x;
      _lastY = event.y;
      _lastZ = event.z;

      final double acceleration =
          sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ);

      // Check gyroscope is also moving (validation)
      final double gyroMagnitude =
          sqrt(_gyroX * _gyroX + _gyroY * _gyroY + _gyroZ * _gyroZ);

      if (acceleration > AppConstants.shakeThreshold &&
          gyroMagnitude > AppConstants.gyroThreshold) {
        final now = DateTime.now();
        if (_lastShakeTime == null ||
            now.difference(_lastShakeTime!).inMilliseconds >
                AppConstants.shakeCooldownMs) {
          _lastShakeTime = now;
          _shakeCount++;

          if (_shakeCount >= AppConstants.shakeCountRequired) {
            _shakeCount = 0;
            stopListening();
            onShakeDetected();
          }
        }
      }
    });
  }

  /// Stop listening to sensors
  static void stopListening() {
    _isListening = false;
    _shakeCount = 0;
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription = null;
  }

  /// Get current shake count
  static int get shakeCount => _shakeCount;

  /// Get required shake count
  static int get shakeRequired => AppConstants.shakeCountRequired;

  /// Simulate shake for testing on emulator
  static void simulateShake({required VoidCallback onShakeDetected}) {
    onShakeDetected();
  }
}
