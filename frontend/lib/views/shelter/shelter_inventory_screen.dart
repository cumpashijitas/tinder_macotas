import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/pet_model.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/swipe_controller.dart';
import '../pets/publish_pet_screen.dart';
import 'shelter_kanban_screen.dart';

class ShelterInventoryScreen extends StatefulWidget {
  const ShelterInventoryScreen({super.key});

  @override
  State<ShelterInventoryScreen> createState() => _ShelterInventoryScreenState();
}

class _ShelterInventoryScreenState extends State<ShelterInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SwipeController>(context, listen: false).loadInventory();
      Provider.of<AuthController>(context, listen: false).ensureLocationCaptured();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changePetStatus(
    PetModel pet,
    String newStatus,
    SwipeController controller,
  ) {
    controller.updatePetStatus(pet, newStatus);

    String statusLabel = '';
    switch (newStatus) {
      case 'available':
        statusLabel = 'activada y disponible';
        break;
      case 'paused':
        statusLabel = 'pausada (no recibirá nuevas solicitudes)';
        break;
      case 'adopted':
        statusLabel = 'marcada como ¡Adoptada con éxito! 🎉';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${pet.name} ha sido $statusLabel.'),
        backgroundColor: newStatus == 'adopted'
            ? AppTheme.successGreen
            : AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final swipeController = Provider.of<SwipeController>(context);
    final allPets = swipeController.inventory;

    final availablePets = allPets
        .where((p) => p.status == 'available')
        .toList();
    final pausedPets = allPets.where((p) => p.status == 'paused').toList();
    final adoptedPets = allPets.where((p) => p.status == 'adopted').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario del Refugio'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Disponibles'),
                  const SizedBox(width: 6),
                  _buildCountBadge(availablePets.length, Colors.green),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pausadas'),
                  const SizedBox(width: 6),
                  _buildCountBadge(pausedPets.length, Colors.amber[800]!),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Adoptadas 🎉'),
                  const SizedBox(width: 6),
                  _buildCountBadge(adoptedPets.length, Colors.purple),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // Barra de búsqueda rápida
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o raza...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.trim().toLowerCase()),
                ),
              ),

              // Tab views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPetList(availablePets, swipeController, 'available'),
                    _buildPetList(pausedPets, swipeController, 'paused'),
                    _buildPetList(adoptedPets, swipeController, 'adopted'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Mascota',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PublishPetScreen()),
          );
        },
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPetList(
    List<PetModel> pets,
    SwipeController controller,
    String listType,
  ) {
    final filtered = _searchQuery.isEmpty
        ? pets
        : pets
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_searchQuery) ||
                    p.breed.toLowerCase().contains(_searchQuery),
              )
              .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                listType == 'available'
                    ? Icons.pets
                    : (listType == 'paused'
                          ? Icons.pause_circle_outline
                          : Icons.celebration),
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 14),
              Text(
                listType == 'available'
                    ? 'No hay mascotas disponibles actualmente'
                    : (listType == 'paused'
                          ? 'No hay mascotas pausadas'
                          : 'Aún no hay adopciones concluidas'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                listType == 'available'
                    ? 'Presiona el botón "Nueva Mascota" para publicar un rescate o camada.'
                    : 'Pausa mascotas cuando recibas demasiadas postulaciones simultáneas.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final pet = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Miniatura
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.network(
                      pet.photos.isNotEmpty ? pet.photos.first : 'https://images.unsplash.com/photo-1548767797-d8c844163c4c?auto=format&fit=crop&w=800&q=80',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.pets, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Datos y acciones
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              pet.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusPill(pet.status),
                        ],
                      ),
                      Text(
                        '${pet.breed} • ${pet.ageFormatted}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (pet.isVaccinated)
                            _miniBadge('Vacunado/a', Colors.blue),
                          if (pet.isNeutered)
                            _miniBadge('Castrado/a', Colors.teal),
                          if (pet.isRelocated)
                            _miniBadge('Reubicación', Colors.red),
                          if (pet.moderationStatus == 'pending')
                            _miniBadge(
                              'Pendiente de Moderación',
                              Colors.orange,
                            ),
                          if (pet.moderationStatus == 'rejected')
                            _miniBadge('Rechazada por Moderación', Colors.red),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Botones de acción del refugio
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(
                              Icons.assignment_outlined,
                              size: 14,
                            ),
                            label: const Text(
                              'Solicitudes',
                              style: TextStyle(fontSize: 11),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ShelterKanbanScreen(),
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            tooltip: 'Cambiar Estado',
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (newStatus) {
                              _changePetStatus(pet, newStatus, controller);
                            },
                            itemBuilder: (ctx) => [
                              if (pet.status != 'available')
                                const PopupMenuItem(
                                  value: 'available',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.play_circle_outline,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Activar (Disponible)'),
                                    ],
                                  ),
                                ),
                              if (pet.status != 'paused')
                                const PopupMenuItem(
                                  value: 'paused',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.pause_circle_outline,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Pausar Publicación'),
                                    ],
                                  ),
                                ),
                              if (pet.status != 'adopted')
                                const PopupMenuItem(
                                  value: 'adopted',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.celebration,
                                        color: Colors.purple,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Marcar como Adoptada 🎉'),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(String status) {
    Color color = Colors.green;
    String label = 'Disponible';

    if (status == 'paused') {
      color = Colors.amber[800]!;
      label = 'Pausada';
    } else if (status == 'adopted') {
      color = Colors.purple;
      label = 'Adoptada 🎉';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
