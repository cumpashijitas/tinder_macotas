import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/swipe_controller.dart';
import '../../controllers/pet_filter_controller.dart';
import '../../models/adopter_form_model.dart';
import '../feed/pet_grid_feed_view.dart';
import '../feed/widgets/advanced_filter_modal.dart';
import '../feed/widgets/pet_detail_sheet.dart';
import '../swipe/widgets/pet_card_widget.dart';
import '../matches/matches_screen.dart';
import '../chat/chat_screen.dart';
import '../onboarding_form/adoption_wizard_screen.dart';
import '../relocation/relocation_request_screen.dart';
import '../community/happy_tails_screen.dart';
import '../auth/login_screen.dart';

class AdopterMainScreen extends StatefulWidget {
  const AdopterMainScreen({super.key});

  @override
  State<AdopterMainScreen> createState() => _AdopterMainScreenState();
}

class _AdopterMainScreenState extends State<AdopterMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _ExploreTab(),
          MatchesScreen(),
          _MessagesTab(),
          _AdopterProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.18),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: AppTheme.primaryColor),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: AppTheme.primaryColor),
            label: 'Solicitudes',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: AppTheme.primaryColor),
            label: 'Mensajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
            label: 'Mi Perfil',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 0: EXPLORAR (GRID PINTEREST VS SWIPE TINDER)
// -------------------------------------------------------------
class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    final filter = Provider.of<PetFilterController>(context);
    final swipe = Provider.of<SwipeController>(context);
    final filteredPets = filter.applyFilters(swipe.pets);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.pets, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ).createShader(bounds),
              child: const Text(
                'PetMatch',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Conmutador Cuadrícula (Pinterest) vs Swipe (Tinder)
          Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Vista Cuadrícula (Pinterest)',
                  icon: Icon(
                    Icons.grid_view_rounded,
                    color: filter.isGridView ? AppTheme.primaryColor : Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () => filter.setViewMode(true),
                ),
                IconButton(
                  tooltip: 'Vista Deslizable (Swipe)',
                  icon: Icon(
                    Icons.view_carousel_rounded,
                    color: !filter.isGridView ? AppTheme.primaryColor : Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () => filter.setViewMode(false),
                ),
              ],
            ),
          ),

          // Botón de Filtros con Badge de activos
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Filtros Dinámicos',
                icon: const Icon(Icons.tune_rounded, color: AppTheme.textDark),
                onPressed: () => AdvancedFilterModal.show(context),
              ),
              if (filter.activeFilterCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${filter.activeFilterCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          // Historias de éxito
          IconButton(
            tooltip: 'Finales Felices',
            icon: const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HappyTailsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              // Barra de Búsqueda rápida
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, raza o historia...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (val) => filter.setSearchQuery(val),
                      ),
                    ),
                  ),
                ),
              ),

              // Barra deslizable horizontal de Filtros Rápidos (nunca desborda en móvil ni se estira sin límite en desktop)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        _quickFilterChip(
                          label: 'Todos',
                          selected: filter.selectedSpecies == 'all' && filter.selectedPublisherType == 'all',
                          onTap: () {
                            filter.setSelectedSpecies('all');
                            filter.setSelectedPublisherType('all');
                          },
                        ),
                        const SizedBox(width: 6),
                        _quickFilterChip(
                          label: '🐶 Perros',
                          selected: filter.selectedSpecies == 'dog',
                          onTap: () => filter.setSelectedSpecies(filter.selectedSpecies == 'dog' ? 'all' : 'dog'),
                        ),
                        const SizedBox(width: 6),
                        _quickFilterChip(
                          label: '🐱 Gatos',
                          selected: filter.selectedSpecies == 'cat',
                          onTap: () => filter.setSelectedSpecies(filter.selectedSpecies == 'cat' ? 'all' : 'cat'),
                        ),
                        const SizedBox(width: 6),
                        _quickFilterChip(
                          label: '🏠 Refugios',
                          selected: filter.selectedPublisherType == 'shelter',
                          onTap: () => filter.setSelectedPublisherType(filter.selectedPublisherType == 'shelter' ? 'all' : 'shelter'),
                        ),
                        const SizedBox(width: 6),
                        _quickFilterChip(
                          label: '🍼 Camadas',
                          selected: filter.selectedPublisherType == 'individual_rescuer',
                          onTap: () => filter.setSelectedPublisherType(filter.selectedPublisherType == 'individual_rescuer' ? 'all' : 'individual_rescuer'),
                        ),
                        const SizedBox(width: 6),
                        _quickFilterChip(
                          label: '⚠️ Reubicación',
                          selected: filter.selectedPublisherType == 'relinquished',
                          onTap: () => filter.setSelectedPublisherType(filter.selectedPublisherType == 'relinquished' ? 'all' : 'relinquished'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Feedback de swipe si hay
              if (swipe.lastSwipeFeedback != null && !filter.isGridView)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              swipe.lastSwipeFeedback!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Contenido: Cuadrícula o Swipe
              Expanded(
                child: filter.isGridView
                    ? PetGridFeedView(pets: filteredPets)
                    : _buildSwipeView(context, swipe, filteredPets),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickFilterChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withValues(alpha: 0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppTheme.primaryColor : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? AppTheme.primaryColor : AppTheme.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeView(BuildContext context, SwipeController swipe, List<dynamic> filteredPets) {
    if (filteredPets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text('No hay mascotas con estos filtros'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Provider.of<PetFilterController>(context, listen: false).resetFilters(),
              child: const Text('Restablecer Filtros'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: CardSwiper(
                  controller: swipe.cardSwiperController,
                  cardsCount: filteredPets.length,
                  onSwipe: (prev, curr, dir) => swipe.handleSwipe(prev, curr, dir),
                  numberOfCardsDisplayed: filteredPets.length > 2 ? 3 : filteredPets.length,
                  backCardOffset: const Offset(0, 35),
                  padding: const EdgeInsets.all(4.0),
                  cardBuilder: (context, index, percentX, percentY) {
                    final pet = filteredPets[index];
                    return PetCardWidget(
                      pet: pet,
                      adopterProfile: AdopterFormModel(),
                      onInfoTap: () => PetDetailSheet.show(context, pet),
                    );
                  },
                ),
              ),
            ),

            // Controles de swipe inferiores
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRoundAction(Icons.close, AppTheme.rejectRed, 50, 24, swipe.swipeLeft),
                  _buildRoundAction(Icons.star, Colors.amber[700]!, 42, 20, swipe.swipeTop),
                  _buildRoundAction(Icons.favorite, AppTheme.primaryColor, 56, 28, swipe.swipeRight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundAction(IconData icon, Color color, double size, double iconSize, VoidCallback onTap) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: iconSize),
        onPressed: onTap,
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 2: MENSAJES (CHAT LIST)
// -------------------------------------------------------------
class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    final swipe = Provider.of<SwipeController>(context);
    final pets = swipe.pets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes y Entrevistas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner de seguridad
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chat seguro interno. No necesitas compartir tu número telefónico ni datos personales sensibles.',
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
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(pets[0].photos.first),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Refugio Patitas Felices (${pets[0].name})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('14:32', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
              subtitle: const Text(
                '¿Te parece si agendamos una videollamada para que conozcas a Rocky?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      pet: pets[0],
                      shelterName: 'Refugio Patitas Felices',
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
                      'Familia Dante (${pets[1].name})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Ayer', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
              subtitle: const Text(
                '¡Muchas gracias por postularte! Estamos revisando el patio...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      pet: pets[1],
                      shelterName: 'Familia Dante (Camada)',
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
// TAB 3: MI PERFIL Y ESTILO DE VIDA (CON REUBICACIÓN)
// -------------------------------------------------------------
class _AdopterProfileTab extends StatelessWidget {
  const _AdopterProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil de Adoptante'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Cabecera de usuario
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                      child: const Icon(Icons.person, size: 48, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      auth.currentUserEmail ?? 'adoptante@petmatch.com',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: AppTheme.successGreen, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Perfil Verificado y Cuestionario Completo',
                            style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Resumen de Estilo de Vida
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cuestionario de Estilo de Vida',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text('Editar', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdoptionWizardScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      _profileItem(Icons.home_outlined, 'Tipo de Vivienda', 'Casa con patio cerrado'),
                      _profileItem(Icons.key_outlined, 'Condición de Ocupación', 'Propietario/a (Permite mascotas)'),
                      _profileItem(Icons.timer_outlined, 'Horas que pasará solo', '4 horas al día aprox.'),
                      _profileItem(Icons.pets, 'Mascotas actuales', '1 perro mestizo esterilizado'),
                      _profileItem(Icons.attach_money, 'Presupuesto mensual est.', 'Alimento premium y veterinario'),
                      _profileItem(Icons.shield_outlined, 'Compromiso de Castración', 'Firmado y Aceptado'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // MÓDULO EXCEPCIONAL DE REUBICACIÓN POR FUERZA MAYOR
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.amber[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.home_work_outlined, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reubicación por Mudanza o Fuerza Mayor',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.brown[900]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Si enfrentas una mudanza urgente, desalojo o imposibilidad comprobable de mantener a tu animalito, puedes solicitar su reubicación responsable bajo nuestro protocolo estricto.',
                      style: TextStyle(fontSize: 12, color: Colors.brown[800], height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[800],
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.app_registration_rounded, size: 16),
                        label: const Text('Iniciar Solicitud de Reubicación', style: TextStyle(fontSize: 13)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RelocationRequestScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botón Cerrar Sesión
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: Colors.red[50],
                leading: const Icon(Icons.logout, color: AppTheme.rejectRed),
                title: const Text('Cerrar Sesión', style: TextStyle(color: AppTheme.rejectRed, fontWeight: FontWeight.bold)),
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
        ),
      ),
    );
  }

  Widget _profileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
