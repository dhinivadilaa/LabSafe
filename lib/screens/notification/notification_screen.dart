import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<ReportProvider>().loadNotifications(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riotifikasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Belum Dibaca'),
            Tab(text: 'Dibaca'),
          ],
        ),
      ),
      body: Consumer<ReportProvider>(
        builder: (context, report, _) {
          final all = report.notifications;
          final unread =
              all.where((n) => n['read'] == false).toList();
          final read = all.where((n) => n['read'] == true).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotifList(all, report),
              _buildNotifList(unread, report),
              _buildNotifList(read, report),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotifList(
      List<Map<String, dynamic>> notifs, ReportProvider report) {
    if (notifs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 64, color: AppTheme.grey400),
            SizedBox(height: 12),
            Text('Tidak ada notifikasi',
                style: TextStyle(color: AppTheme.grey600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifs.length,
      itemBuilder: (context, i) => _buildNotifCard(notifs[i], report),
    );
  }

  Widget _buildNotifCard(
      Map<String, dynamic> notif, ReportProvider report) {
    final type = notif['type'] as String;
    final isRead = notif['read'] as bool;
    final time = notif['time'] as DateTime;

    Color cardColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case 'new':
        cardColor = AppTheme.dangerRed;
        iconColor = AppTheme.dangerRed;
        icon = Icons.warning_rounded;
        break;
      case 'processing':
        cardColor = AppTheme.warningOrange;
        iconColor = AppTheme.warningOrange;
        icon = Icons.pending_rounded;
        break;
      case 'done':
        cardColor = AppTheme.successGreen;
        iconColor = AppTheme.successGreen;
        icon = Icons.check_circle_rounded;
        break;
      default:
        cardColor = AppTheme.primaryBlue;
        iconColor = AppTheme.primaryBlue;
        icon = Icons.info_rounded;
    }

    return GestureDetector(
      onTap: () => report.markNotificationRead(notif['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: cardColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: isRead
                  ? Colors.black.withOpacity(0.04)
                  : cardColor.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notif['title'],
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 14,
                            color: cardColor,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cardColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif['message'],
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.grey600, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormatter.timeAgo(time),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.grey400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
