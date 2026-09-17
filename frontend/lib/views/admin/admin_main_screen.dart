import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/swipe_controller.dart';
import '../../models/pet_model.dart';
import '../notifications/notification_bell_button.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SwipeController>(context, listen: false).loadPendingModeration();
    });
  }

  Future<void> _approve(PetModel pet, SwipeController controller) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await controller.moderatePet(pet.id, 'approved');
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? '${pet.name} fue aprobado/a y ya aparece en el feed.' : controller.errorMessage ?? 'Error'),
        backgroundColor: ok ? AppTheme.successGreen : AppTheme.rejectRed,
      ),
    );
  }

  Future<void> _reject(PetModel pet, SwipeController controller) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rechazar a ${pet.name}'),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo (se le muestra al publicador)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rechazar', style: TextStyle(color: AppTheme.rejectRed)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await controller.moderatePet(pet.id, 'rejected', notes: notesController.text.trim());
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? '${pet.name} fue rechazado/a.' : controller.errorMessage ?? 'Error'),
        backgroundColor: ok ? AppTheme.textDark : AppTheme.rejectRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final controller = Provider.of<SwipeController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          const NotificationBellButton(),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: controller.isLoading ? null : () => controller.loadPendingModeration(),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.pendingModeration.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No hay publicaciones pendientes de moderación. 🎉',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: RefreshIndicator(
                      onRefresh: () => controller.loadPendingModeration(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.pendingModeration.length,
                        itemBuilder: (context, index) {
                          final pet = controller.pendingModeration[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: 72,
                                          height: 72,
                                          child: pet.photos.isNotEmpty
                                              ? Image.network(
                                                  pet.photos.first,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.pets, color: Colors.grey),
                                                  ),
                                                )
                                              : Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.pets, color: Colors.grey),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pet.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                            ),
                                            Text(
                                              '${pet.breed} • ${pet.ageFormatted} • ${pet.publisherBadgeText}',
                                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (pet.relocationReason != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[50],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Motivo de reubicación: ${pet.relocationReason}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Text(pet.story, style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.rejectRed),
                                          icon: const Icon(Icons.close),
                                          label: const Text('Rechazar'),
                                          onPressed: () => _reject(pet, controller),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Aprobar'),
                                          onPressed: () => _approve(pet, controller),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
    );
  }
}
