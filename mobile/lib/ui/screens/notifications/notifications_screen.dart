import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/notifications_provider.dart';
import '../../widgets/empty_view.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationsProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          if (provider.notifications.isNotEmpty)
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: const Text("Mark all read", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return const EmptyView(
              title: "All Caught Up!",
              subtitle: "Follow-up reminders, task assignments and payments appear here.",
              icon: Icons.notifications_none_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notif = provider.notifications[index];

                return Card(
                  color: notif.isRead ? AppColors.surface : AppColors.surfaceCard,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notif.isRead ? AppColors.background : AppColors.accent.withOpacity(0.1),
                      child: Icon(
                        Icons.notifications,
                        color: notif.isRead ? AppColors.textMuted : AppColors.accent,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(notif.message, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatDateTime(notif.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    trailing: !notif.isRead
                        ? IconButton(
                            icon: const Icon(Icons.check, size: 18, color: AppColors.accent),
                            tooltip: "Mark read",
                            onPressed: () => provider.markAsRead(notif.id),
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
