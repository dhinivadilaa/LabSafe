import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../models/lab_safety_insight.dart';
import '../../services/lab_safety_service.dart';
import '../../widgets/lab_monitoring_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;
  Map<String, int> _stats = {
    'todayReports': 2,
    'totalReports': 15,
    'onlineOfficers': 3,
    'totalLabs': 5,
  };
  List<LabSafetyInsight> _labInsights = [];
  bool _isLoadingInsights = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      final isStudent = user?.role == 'mahasiswa';
      context.read<ReportProvider>().loadRecentReports(userId: isStudent ? user?.id : null);
      if (user?.id != null) {
        context.read<ReportProvider>().loadNotifications(user!.id);
      }
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    if (user.role == 'mahasiswa') {
      await context.read<ReportProvider>().loadReports(userId: user.id);
      final reports = context.read<ReportProvider>().reports;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todayCount = reports
          .where((r) => r.createdAt.isAfter(startOfDay))
          .length;
      final totalCount = reports.length;

      if (mounted) {
        setState(() {
          _stats = {
            'todayReports': todayCount,
            'totalReports': totalCount,
          };
        });
      }
    } else {
      final stats = await AuthService.getDashboardStats();
      await context.read<ReportProvider>().loadReports();
      final pendingCount = context
          .read<ReportProvider>()
          .reports
          .where((r) => r.status == 'Terkirim')
          .length;
      stats['pendingReports'] = pendingCount;
      
      // Load dynamic safety insights
      final insights = await LabSafetyService.getAllLabInsights();
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _labInsights = insights;
          _isLoadingInsights = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 40,
      );

      if (pickedFile == null) return;

      final bytes = await File(pickedFile.path).readAsBytes();
      final base64Photo = base64Encode(bytes);

      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );

      final success = await context.read<AuthProvider>().updateProfilePhoto(base64Photo);

      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Foto profil berhasil diperbarui!' : 'Gagal memperbarui foto profil.'),
            backgroundColor: success ? AppTheme.successGreen : AppTheme.dangerRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat mengunggah foto.'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  Widget _buildAvatar(dynamic user) {
    if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      try {
        final bytes = base64Decode(user.photoUrl!);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => _defaultAvatar(user),
          ),
        );
      } catch (e) {
        return _defaultAvatar(user);
      }
    }
    return _defaultAvatar(user);
  }

  Widget _defaultAvatar(dynamic user) {
    return Center(
      child: Text(
        user?.name != null && user!.name.isNotEmpty
            ? user.name.substring(0, 1).toUpperCase()
            : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final List<Widget> tabs = [
      _buildHomeTab(user),
      const _HistoryTabPlaceholder(),
      const _NotificationTabPlaceholder(),
      _buildProfileTab(user),
    ];

    return Scaffold(
      backgroundColor: AppTheme.grey100,
      body: tabs[_selectedTab],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Consumer<ReportProvider>(
      builder: (context, report, _) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedTab,
            onTap: (i) {
              setState(() => _selectedTab = i);
              if (i == 1) Navigator.pushNamed(context, '/history');
              if (i == 2) Navigator.pushNamed(context, '/notifications');
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryBlue,
            unselectedItemColor: AppTheme.grey400,
            selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Beranda',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_rounded),
                    if (report.unreadNotifications > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppTheme.dangerRed,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${report.unreadNotifications}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 9),
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Notifikasi',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeTab(UserModel? user) {
    final userName = user?.name ?? 'Pengguna';
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryDark, AppTheme.primaryMid],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                              Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            userName.split(' ').first,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.roleLabel ??
                                'Mahasiswa',
                            style: TextStyle(
                              color: AppTheme.accentCyan.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/notifications'),
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.white),
                          ),
                          PopupMenuButton<String>(
                            color: AppTheme.primaryBlue,
                            icon: const Icon(Icons.menu_rounded,
                                color: Colors.white),
                            onSelected: (value) async {
                              if (value == 'profile') {
                                setState(() => _selectedTab = 3);
                              } else if (value == 'history') {
                                Navigator.pushNamed(context, '/history');
                              } else if (value == 'logout') {
                                await context.read<AuthProvider>().signOut();
                                if (mounted) {
                                  Navigator.pushReplacementNamed(context, '/login');
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_outline,
                                        color: AppTheme.grey800),
                                    SizedBox(width: 10),
                                    Text('Profil'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'history',
                                child: Row(
                                  children: [
                                    Icon(Icons.history_outlined,
                                        color: AppTheme.grey800),
                                    SizedBox(width: 10),
                                    Text('Riwayat'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout,
                                        color: AppTheme.grey800),
                                    SizedBox(width: 10),
                                    Text('Keluar'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status System Card
                _buildStatusCard(),
                const SizedBox(height: 16),
                 // Stats Grid
                 _buildStatsGrid(user?.role),
                 if (user?.role == 'mahasiswa') ...[
                   const SizedBox(height: 20),
                   // Emergency Button
                   _buildEmergencyButton(),
                 ] else ...[
                   const SizedBox(height: 20),
                   // Safety Insights (Asisten)
                   _buildSafetyInsights(),
                 ],
                 const SizedBox(height: 20),
                 // Recent Reports
                 _buildRecentReports(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_rounded,
                color: AppTheme.successGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Sistem',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.grey600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Aktif',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.successGreen, size: 36),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(String? role) {
    final isMahasiswa = role == 'mahasiswa';

    if (isMahasiswa) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _statCard(
            'Laporan Saya (Hari Ini)',
            '${_stats['todayReports']}',
            Icons.report_rounded,
            AppTheme.dangerRedLight,
          ),
          _statCard(
            'Total Laporan Saya',
            '${_stats['totalReports']}',
            Icons.folder_rounded,
            AppTheme.primaryBlue,
          ),
        ],
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statCard(
          'Laporan Hari Ini',
          '${_stats['todayReports']}',
          Icons.report_rounded,
          AppTheme.dangerRedLight,
        ),
        _statCard(
          'Semua Laporan',
          '${_stats['totalReports']}',
          Icons.folder_rounded,
          AppTheme.primaryBlue,
        ),
        _statCard(
          'Asisten Online',
          '${_stats['onlineOfficers'] ?? 0}',
          Icons.people_alt_rounded,
          AppTheme.successGreen,
        ),
        _statCard(
          'Laporan Diterima',
          '${_stats['pendingReports'] ?? 0}',
          Icons.pending_actions_rounded,
          AppTheme.primaryBlue,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.grey600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monitoring Laboratorium',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.grey800,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingInsights)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryBlue),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat data laporan...',
                    style: TextStyle(color: AppTheme.grey500, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else if (_labInsights.every((insight) => insight.recentReportCount == 0))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.grey200),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppTheme.successGreen, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Seluruh Area Lab Aman',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.grey800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tidak ada insiden tercatat dalam 7 hari terakhir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.grey500, fontSize: 13),
                  ),
                ],
              ),
            )
        else
          ..._labInsights.where((insight) => insight.recentReportCount > 0).take(4).map((insight) {
            return LabMonitoringCard(insight: insight);
          }).toList(),
      ],
    );
  }

  Widget _buildEmergencyButton() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/shake'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.dangerRed, Color(0xFFB71C1C)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.dangerRed.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.warning_rounded, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAPORKAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Aktivitas Mencurigakan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Terbaru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey800,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/history'),
              child: const Text('Lihat Semua',
                  style: TextStyle(color: AppTheme.primaryBlue, fontSize: 13)),
            ),
          ],
        ),
        Consumer<ReportProvider>(
          builder: (context, report, _) {
            if (report.recentReports.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: const Center(
                  child: Text('Belum ada laporan',
                      style: TextStyle(color: AppTheme.grey600)),
                ),
              );
            }
            final isStaff = context.read<AuthProvider>().user?.role == 'asisten';
            return Column(
              children: report.recentReports
                  .map((r) => _buildReportItem(r, isStaff))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReportItem(ReportModel report, bool isStaff) {
    final statusColor = _getStatusColor(report.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.science_rounded,
                color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.locationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.grey800,
                  ),
                ),
                Text(
                  DateFormatter.formatShort(report.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.grey600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              report.displayStatus(isStaff),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(dynamic user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: _buildAvatar(user),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? '-',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.grey800,
                  ),
                ),
                Text(
                  user?.roleLabel ?? '-',
                  style: const TextStyle(color: AppTheme.grey600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _profileInfoCard(Icons.email_outlined, 'Email', user?.email ?? '-'),
          _profileInfoCard(Icons.badge_outlined, 'NPM/ID', user?.npm ?? '-'),
          _profileInfoCard(
              Icons.verified_user_outlined, 'Role', user?.roleLabel ?? '-'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileInfoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.grey600)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Ditindaklanjuti':
        return AppTheme.successGreen;
      default:
        return AppTheme.primaryBlue;
    }
  }
}

// Placeholder widgets that redirect to named routes
class _HistoryTabPlaceholder extends StatelessWidget {
  const _HistoryTabPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _NotificationTabPlaceholder extends StatelessWidget {
  const _NotificationTabPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox();
}
