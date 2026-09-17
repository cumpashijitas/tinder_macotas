import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/matches_controller.dart';
import '../../controllers/swipe_controller.dart';
import '../shelter/shelter_inventory_screen.dart';
import '../shelter/shelter_kanban_screen.dart';
import '../chat/chat_screen.dart';
import '../history/history_screen.dart';
import '../profile/edit_profile_dialog.dart';

class ShelterMainScreen extends StatefulWidget {
  const ShelterMainScreen({super.key});

  @override
  State<ShelterMainScreen> createState() => _ShelterMainScreenState();
}

class _ShelterMainScreenState extends State<ShelterMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ShelterInventoryScreen(),
          ShelterKanbanScreen(),
          _ShelterMessagesTab(),
          _ShelterProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        indicatorColor: AppTheme.secondaryColor.withValues(alpha: 0.18),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(
              Icons.inventory_2,
              color: AppTheme.secondaryColor,
            ),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_customize_outlined),
            selectedIcon: Icon(
              Icons.dashboard_customize,
              color: AppTheme.secondaryColor,
            ),
            label: 'Solicitudes',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat, color: AppTheme.secondaryColor),
            label: 'Mensajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business, color: AppTheme.secondaryColor),
            label: 'Refugio',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 2: MENSAJERÍA DEL REFUGIO (CON POSTULANTES)
// -------------------------------------------------------------
class _ShelterMessagesTab extends StatefulWidget {
  const _ShelterMessagesTab();

  @override
  State<_ShelterMessagesTab> createState() => _ShelterMessagesTabState();
}

class _ShelterMessagesTabState extends State<_ShelterMessagesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MatchesController>(context, listen: false).loadMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MatchesController>(context);
    final chats = controller.matches.where((m) => m.isChatEnabled).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeja de Postulantes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.isLoading
                ? null
                : () => controller.loadMatches(),
          ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: AppTheme.successGreen,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Canal institucional verificado. Toda conversación queda registrada para el seguimiento del contrato de adopción.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (chats.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Todavía no hay postulantes con chat habilitado.\nAprueba solicitudes desde el Tablero de Adopciones.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  )
                else
                  ...chats.map((match) {
                    final pet = match.pet;
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundImage: NetworkImage(
                              (pet != null && pet.photos.isNotEmpty)
                                  ? pet.photos.first
                                  : 'https://images.unsplash.com/photo-1548767797-d8c844163c4c?auto=format&fit=crop&w=800&q=80',
                            ),
                          ),
                          title: Text(
                            '${match.adopterName ?? 'Postulante'} (Por ${pet?.name ?? '-'})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            match.statusBadgeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(match: match),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                      ],
                    );
                  }),
              ],
            ),
    );
  }
}

// -------------------------------------------------------------
// TAB 3: PERFIL DEL REFUGIO / INSTITUCIÓN
// -------------------------------------------------------------
class _ShelterProfileTab extends StatefulWidget {
  const _ShelterProfileTab();

  @override
  State<_ShelterProfileTab> createState() => _ShelterProfileTabState();
}

class _ShelterProfileTabState extends State<_ShelterProfileTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SwipeController>(context, listen: false).loadInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final swipe = Provider.of<SwipeController>(context);

    final totalPets = swipe.inventory.length;
    final availablePets = swipe.inventory
        .where((p) => p.status == 'available')
        .length;
    final pausedPets = swipe.inventory
        .where((p) => p.status == 'paused')
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil Institucional')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Cabecera Refugio
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppTheme.secondaryColor.withValues(
                    alpha: 0.15,
                  ),
                  child: const Icon(
                    Icons.shield,
                    size: 50,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  auth.profile?.organizationName?.isNotEmpty == true
                      ? auth.profile!.organizationName!
                      : (auth.profile?.fullName ?? 'Mi Refugio'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  auth.currentUserEmail ?? '',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Editar Perfil', style: TextStyle(fontSize: 12)),
                  onPressed: () => EditProfileDialog.show(context),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (auth.profile?.isVerified == true
                                ? Colors.blue
                                : Colors.grey)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        auth.profile?.isVerified == true
                            ? Icons.verified
                            : Icons.pending_outlined,
                        color: auth.profile?.isVerified == true
                            ? Colors.blue
                            : Colors.grey[700],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        auth.profile?.isVerified == true
                            ? 'Entidad Verificada'
                            : 'Verificación Pendiente',
                        style: TextStyle(
                          color: auth.profile?.isVerified == true
                              ? Colors.blue
                              : Colors.grey[700],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Métricas rápidas
          Row(
            children: [
              _metricCard('Disponibles', '$availablePets', Colors.green),
              const SizedBox(width: 10),
              _metricCard('Pausadas', '$pausedPets', Colors.amber[800]!),
              const SizedBox(width: 10),
              _metricCard(
                'Total Registradas',
                '$totalPets',
                AppTheme.primaryColor,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Configuración Institucional
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parámetros y Requisitos de Adopción',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),
                  _itemRow(
                    Icons.description_outlined,
                    'Contrato de Adopción Digital',
                    'Activo y Obligatorio',
                  ),
                  _itemRow(
                    Icons.handshake_outlined,
                    'Compromiso de Castración',
                    'Requerido para cachorros',
                  ),
                  _itemRow(
                    Icons.phone_outlined,
                    'Teléfono de contacto',
                    auth.profile?.phone ?? 'No especificado',
                  ),
                  _itemRow(
                    Icons.location_on_outlined,
                    'Dirección',
                    auth.profile?.address ?? 'No especificada',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            leading: const Icon(Icons.history, color: AppTheme.secondaryColor),
            title: const Text('Contratos y Visitas', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
          ),

          const SizedBox(height: 24),

          // Botón Cerrar Sesión
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tileColor: Colors.red[50],
            leading: const Icon(Icons.logout, color: AppTheme.rejectRed),
            title: const Text(
              'Cerrar Sesión Institucional',
              style: TextStyle(
                color: AppTheme.rejectRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => auth.logout(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
