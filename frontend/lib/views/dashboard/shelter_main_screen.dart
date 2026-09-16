import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/swipe_controller.dart';
import '../shelter/shelter_inventory_screen.dart';
import '../shelter/shelter_kanban_screen.dart';
import '../chat/chat_screen.dart';
import '../auth/login_screen.dart';

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
            selectedIcon: Icon(Icons.inventory_2, color: AppTheme.secondaryColor),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_customize_outlined),
            selectedIcon: Icon(Icons.dashboard_customize, color: AppTheme.secondaryColor),
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
class _ShelterMessagesTab extends StatelessWidget {
  const _ShelterMessagesTab();

  @override
  Widget build(BuildContext context) {
    final swipe = Provider.of<SwipeController>(context);
    final pets = swipe.pets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeja de Postulantes'),
      ),
      body: ListView(
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
                Icon(Icons.security, color: AppTheme.successGreen, size: 20),
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

          if (pets.isNotEmpty) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(pets[0].photos.first),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sofía Navarro (Por ${pets[0].name})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('14:32', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
              subtitle: const Text(
                'Sofía: "¿Te parece si agendamos una videollamada para conocer a Rocky?"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(10)),
                child: Text('94% Match', style: TextStyle(color: Colors.green[900], fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      pet: pets[0],
                      shelterName: 'Postulante: Sofía Navarro',
                    ),
                  ),
                );
              },
            ),
            const Divider(),
          ],

          if (pets.length > 1) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(pets[1].photos.first),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Familia Morales (Por ${pets[1].name})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Ayer', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
              subtitle: const Text(
                'Familia Morales: "Contamos con patio cerrado y quisiéramos coordinar visita."',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(10)),
                child: Text('90% Match', style: TextStyle(color: Colors.green[900], fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      pet: pets[1],
                      shelterName: 'Postulante: Familia Morales',
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 3: PERFIL DEL REFUGIO / INSTITUCIÓN
// -------------------------------------------------------------
class _ShelterProfileTab extends StatelessWidget {
  const _ShelterProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final swipe = Provider.of<SwipeController>(context);

    final totalPets = swipe.pets.length;
    final availablePets = swipe.pets.where((p) => p.status == 'available').length;
    final pausedPets = swipe.pets.where((p) => p.status == 'paused').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil Institucional'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Cabecera Refugio
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.15),
                  child: const Icon(Icons.shield, size: 50, color: AppTheme.secondaryColor),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Refugio Patitas Felices ONG',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.currentUserEmail ?? 'refugio@patitasfelices.org',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.blue, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Entidad Legal Verificada • Registro Nº 4819',
                        style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
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
              _metricCard('Total Registradas', '$totalPets', AppTheme.primaryColor),
            ],
          ),

          const SizedBox(height: 20),

          // Configuración Institucional
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  _itemRow(Icons.description_outlined, 'Contrato de Adopción Digital', 'Activo y Obligatorio'),
                  _itemRow(Icons.camera_alt_outlined, 'Seguimiento fotográfico', '1, 3 y 6 meses'),
                  _itemRow(Icons.handshake_outlined, 'Compromiso de Castración', 'Requerido para cachorros'),
                  _itemRow(Icons.location_on_outlined, 'Zona de cobertura', 'Radio de 45 km'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botón Cerrar Sesión
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.red[50],
            leading: const Icon(Icons.logout, color: AppTheme.rejectRed),
            title: const Text('Cerrar Sesión Institucional', style: TextStyle(color: AppTheme.rejectRed, fontWeight: FontWeight.bold)),
            onTap: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
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
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
