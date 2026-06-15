import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ShakeDetectedScreen extends StatefulWidget {
  const ShakeDetectedScreen({super.key});

  @override
  State<ShakeDetectedScreen> createState() => _ShakeDetectedScreenState();
}

class _ShakeDetectedScreenState extends State<ShakeDetectedScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _pulseController;
  late Animation<double> _checkScale;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _checkScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );

    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkController.forward();

    // Auto navigate to camera after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/camera');
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteksi Shake'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {},
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
                const Text(
                  'Shake Terdeteksi!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mengambil data laporan...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 60),
                // Animated check mark
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnim.value,
                      child: child,
                    );
                  },
                  child: ScaleTransition(
                    scale: _checkScale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.successGreen.withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),
                ),
                // Ripple effect
                const SizedBox(height: 30),
                ...List.generate(
                  3,
                  (i) => AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        width: 140 + (i * 40.0) * _pulseController.value,
                        height: 140 + (i * 40.0) * _pulseController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.successGreen.withOpacity(
                              (0.5 - i * 0.15) *
                                  (1 - _pulseController.value * 0.5),
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ).reversed.toList(),
                const SizedBox(height: 40),
                // Status Cards
                _buildStatusCard(
                  icon: Icons.sensors_rounded,
                  color: AppTheme.successGreen,
                  title: 'Shake Terdeteksi!',
                  subtitle: 'Sistem berhasil mendeteksi guncangan',
                  isSuccess: true,
                ),
                const SizedBox(height: 12),
                _buildStatusCard(
                  icon: Icons.pending_rounded,
                  color: AppTheme.warningOrange,
                  title: 'Laporan sedang dibuat',
                  subtitle: 'Mohon tunggu sebentar...',
                  isLoading: true,
                ),
                const Spacer(),
                const LinearProgressIndicator(
                  backgroundColor: AppTheme.grey200,
                  color: AppTheme.successGreen,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mengarahkan ke kamera...',
                  style: TextStyle(color: AppTheme.grey600, fontSize: 12),
                ),
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
    bool isSuccess = false,
    bool isLoading = false,
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
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: color,
                      strokeWidth: 2.5,
                    ),
                  )
                : Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: color)),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
