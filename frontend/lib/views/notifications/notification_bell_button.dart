import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/notifications_controller.dart';
import 'notifications_screen.dart';

/// Botón de campana con badge de notificaciones no leídas. Carga el conteo
/// al montarse y lo refresca al volver de la pantalla de notificaciones.
class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({super.key});

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationsController>(context, listen: false).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NotificationsController>(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notificaciones',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
            if (!context.mounted) return;
            Provider.of<NotificationsController>(context, listen: false).load();
          },
        ),
        if (controller.unreadCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                controller.unreadCount > 9 ? '9+' : '${controller.unreadCount}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
