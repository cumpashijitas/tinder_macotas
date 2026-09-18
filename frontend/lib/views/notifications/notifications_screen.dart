import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../controllers/notifications_controller.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationsController>(context, listen: false).load();
    });
  }

  IconData _iconFor(IconIdentifier icon) {
    switch (icon) {
      case IconIdentifier.match:
        return Icons.favorite;
      case IconIdentifier.status:
        return Icons.fact_check_outlined;
      case IconIdentifier.message:
        return Icons.chat_bubble_outline;
      case IconIdentifier.visit:
        return Icons.event_available_outlined;
      case IconIdentifier.contract:
        return Icons.description_outlined;
      case IconIdentifier.generic:
        return Icons.notifications_outlined;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NotificationsController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (controller.unreadCount > 0)
            TextButton(
              onPressed: () => controller.markAllRead(),
              child: const Text('Marcar todas', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.notifications.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No tenés notificaciones todavía.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => controller.load(),
                  child: ListView.separated(
                    itemCount:
                        controller.notifications.length + (controller.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index >= controller.notifications.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: controller.isLoadingMore
                                ? const CircularProgressIndicator()
                                : OutlinedButton(
                                    onPressed: () => controller.loadMore(),
                                    child: const Text('Cargar más'),
                                  ),
                          ),
                        );
                      }

                      final n = controller.notifications[index];
                      return ListTile(
                        tileColor: n.isRead ? null : AppTheme.primaryColor.withValues(alpha: 0.06),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                          child: Icon(_iconFor(n.iconType), color: AppTheme.primaryColor, size: 20),
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold),
                        ),
                        subtitle: n.body != null ? Text(n.body!) : null,
                        trailing: Text(
                          _timeAgo(n.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                        onTap: () => controller.markRead(n.id),
                      );
                    },
                  ),
                ),
    );
  }
}
