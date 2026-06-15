import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/sensor_service.dart';

class ShakeReadyScreen extends StatefulWidget {
  const ShakeReadyScreen({super.key});

  @override
  State<ShakeReadyScreen> createState() => _ShakeReadyScreenState();
}

class _ShakeReadyScreenState extends State<ShakeReadyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeAnimController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _shakeAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _shakeAnimController, curve: Curves.easeInOut),
    );

    _startListening();
  }

  void _startListening() {
    SensorService.startListening(
      onShakeDetected: _onShakeDetected,
    );
  }

  void _onShakeDetected() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/shake-detected');
  }

  @override
  void dispose() {
    SensorService.stopListening();
    _shakeAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteksi Shake'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            SensorService.stopListening();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            onPressed: () => _showInfoDialog(),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryMid, AppTheme.grey50],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Guncangkan HP Anda\n2-3 kali untuk melaporkan\naktivitas mencurigakan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                // Animated Phone
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnim.value, 0),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.accentCyan.withOpacity(0.5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentBlue.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.security_rounded,
                            color: Colors.white, size: 40),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.accentCyan,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Wave effect
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => AnimatedBuilder(
                      animation: _shakeAnimController,
                      builder: (context, _) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 12 + (i * 8),
                          height: 12 + (i * 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accentCyan.withOpacity(
                                0.8 - (_shakeAnimController.value * 0.5),
                              ),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Status indicators
                _buildStatusCard(
                  icon: Icons.sensors_rounded,
                  color: AppTheme.successGreen,
                  title: 'Sistem Siap',
                  subtitle: 'Silakan guncangkan HP Anda',
                ),
                const SizedBox(height: 12),
                _buildStatusCard(
                  icon: Icons.location_on_rounded,
                  color: AppTheme.warningOrange,
                  title: 'Tips',
                  subtitle:
                      'Guncangkan HP secara kuat\ndan berulang dalam waktu singkat.',
                ),
                const Spacer(),
                // Manual button
                OutlinedButton.icon(
                  onPressed: () => _onShakeDetected(),
                  icon: const Icon(Icons.touch_app_rounded),
                  label: const Text('Simulasi Shake (Test)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: color)),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.grey600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cara Penggunaan'),
        content: const Text(
          'Guncangkan HP Anda 2-3 kali dengan cepat untuk memicu laporan darurat.\n\nSensor Accelerometer dan Gyroscope akan mendeteksi gerakan guncangan Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}
