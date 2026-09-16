import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/swipe_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/pet_model.dart';
import '../../models/adopter_form_model.dart';
import '../../services/compatibility_service.dart';
import 'widgets/pet_card_widget.dart';
import '../onboarding_form/adoption_wizard_screen.dart';
import '../matches/matches_screen.dart';
import '../pets/publish_pet_screen.dart';
import '../shelter/shelter_kanban_screen.dart';
import '../community/happy_tails_screen.dart';
import '../contract/adoption_contract_screen.dart';
import '../pets/widgets/health_booklet_modal.dart';

class PetSwipeScreen extends StatefulWidget {
  const PetSwipeScreen({super.key});

  @override
  State<PetSwipeScreen> createState() => _PetSwipeScreenState();
}

class _PetSwipeScreenState extends State<PetSwipeScreen> {
  String _selectedSpeciesFilter = 'all'; // 'all' | 'dog' | 'cat'
  String _selectedPublisherFilter = 'all'; // 'all' | 'shelter' | 'individual_rescuer'

  @override
  Widget build(BuildContext context) {
    final swipeController = Provider.of<SwipeController>(context);
    final authController = Provider.of<AuthController>(context);

    // Filtrado interactivo en memoria
    final filteredPets = swipeController.pets.where((pet) {
      if (_selectedSpeciesFilter != 'all' && pet.species != _selectedSpeciesFilter) {
        return false;
      }
      if (_selectedPublisherFilter != 'all' && pet.publisherType != _selectedPublisherFilter) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
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
          // Muro de Finales Felices (Comunidad)
          IconButton(
            tooltip: 'Finales Felices (Historias)',
            icon: const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HappyTailsScreen()),
              );
            },
          ),
          // Tablero Kanban de Refugios
          IconButton(
            tooltip: 'Tablero de Solicitudes (Kanban)',
            icon: const Icon(Icons.dashboard_customize_outlined, color: AppTheme.secondaryColor, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShelterKanbanScreen()),
              );
            },
          ),
          // Formulario de adoptante
          IconButton(
            tooltip: 'Formulario de Adoptante',
            icon: const Icon(Icons.assignment_outlined, color: AppTheme.textDark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdoptionWizardScreen()),
              );
            },
          ),
          // Matches y chats
          IconButton(
            tooltip: 'Mis Solicitudes y Matches',
            icon: const Icon(Icons.favorite_border, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MatchesScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // Barra de rol y botón de publicación
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: AppTheme.primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Sesión: ${authController.roleTitle}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Publicar Mascota', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PublishPetScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Barra superior de Filtros Rápidos
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', 'all', _selectedSpeciesFilter, (v) => setState(() => _selectedSpeciesFilter = v)),
                      _buildFilterChip('🐶 Perros', 'dog', _selectedSpeciesFilter, (v) => setState(() => _selectedSpeciesFilter = v)),
                      _buildFilterChip('🐱 Gatos', 'cat', _selectedSpeciesFilter, (v) => setState(() => _selectedSpeciesFilter = v)),
                      const VerticalDivider(width: 16),
                      _buildFilterChip('🏠 Refugios', 'shelter', _selectedPublisherFilter, (v) => setState(() => _selectedPublisherFilter = v == _selectedPublisherFilter ? 'all' : v)),
                      _buildFilterChip('🍼 Camadas', 'individual_rescuer', _selectedPublisherFilter, (v) => setState(() => _selectedPublisherFilter = v == _selectedPublisherFilter ? 'all' : v)),
                    ],
                  ),
                ),

                // Banner informativo de feedback de swipe
                if (swipeController.lastSwipeFeedback != null)
                  Container(
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
                            swipeController.lastSwipeFeedback!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Deck de Tarjetas Deslizables (Tinder Swiper)
                Expanded(
                  child: filteredPets.isEmpty
                      ? _buildEmptyState(context, swipeController)
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: CardSwiper(
                            controller: swipeController.cardSwiperController,
                            cardsCount: filteredPets.length,
                            onSwipe: (prev, curr, dir) => swipeController.handleSwipe(prev, curr, dir),
                            numberOfCardsDisplayed: filteredPets.length > 2 ? 3 : filteredPets.length,
                            backCardOffset: const Offset(0, 35),
                            padding: const EdgeInsets.all(4.0),
                            cardBuilder: (context, index, percentX, percentY) {
                              final pet = filteredPets[index];
                              return PetCardWidget(
                                pet: pet,
                                adopterProfile: AdopterFormModel(),
                                onInfoTap: () => _showPetDetailsModal(context, pet),
                              );
                            },
                          ),
                        ),
                ),

                // Barra de Controles Inferiores
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Botón Pasar (Dislike)
                      _buildActionButton(
                        icon: Icons.close,
                        color: AppTheme.rejectRed,
                        size: 52,
                        iconSize: 26,
                        onPressed: swipeController.swipeLeft,
                      ),

                      // Botón Super-Adopción (Superlike)
                      _buildActionButton(
                        icon: Icons.star,
                        color: Colors.amber[700]!,
                        size: 44,
                        iconSize: 22,
                        onPressed: swipeController.swipeTop,
                      ),

                      // Botón Me Interesa Adoptar (Like)
                      _buildActionButton(
                        icon: Icons.favorite,
                        color: AppTheme.primaryColor,
                        size: 58,
                        iconSize: 30,
                        onPressed: swipeController.swipeRight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue, ValueChanged<String> onSelected) {
    final isSelected = value == selectedValue;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        checkmarkColor: AppTheme.primaryColor,
        onSelected: (_) => onSelected(value),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: iconSize),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, SwipeController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 68, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text(
              'No hay mascotas con estos filtros',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Prueba seleccionando "Todos" o recarga la lista.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Restablecer Filtros'),
              onPressed: () {
                setState(() {
                  _selectedSpeciesFilter = 'all';
                  _selectedPublisherFilter = 'all';
                });
                controller.loadSamplePets();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPetDetailsModal(BuildContext context, PetModel pet) {
    final isIndividual = pet.publisherType == 'individual_rescuer';
    final matchResult = CompatibilityService.calculateMatch(
      adopter: AdopterFormModel(),
      pet: pet,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Cabecera: Nombre y Origen
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pet.name,
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                              Text(
                                '${pet.breed} • ${pet.ageFormatted}',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isIndividual
                                ? Colors.orange.withValues(alpha: 0.15)
                                : AppTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isIndividual ? Icons.volunteer_activism : Icons.verified,
                                size: 14,
                                color: isIndividual ? Colors.orange[800] : AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pet.publisherBadgeText,
                                style: TextStyle(
                                  color: isIndividual ? Colors.orange[800] : AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tarjeta de Compatibilidad (% Match)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: AppTheme.successGreen, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Índice de Compatibilidad',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Text(
                                '${matchResult.percentage}% Match',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[900], fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...matchResult.positiveMatches.map(
                            (pos) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check, size: 14, color: AppTheme.successGreen),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(pos, style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botones de acción clínica y legal
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.menu_book, size: 18),
                            label: const Text('Libreta Sanitaria', style: TextStyle(fontSize: 12)),
                            onPressed: () => HealthBookletModal.show(context, pet),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.description, size: 18),
                            label: const Text('Ver Contrato', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AdoptionContractScreen(pet: pet)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 28),

                    // Historia
                    const Text(
                      'Historia y Personalidad',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pet.story,
                      style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                    ),

                    const SizedBox(height: 20),

                    // Ficha Sanitaria
                    const Text(
                      'Ficha Clínica y Reproductiva',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 10),

                    _buildDetailRow(
                      pet.gender == 'female' ? Icons.female : Icons.male,
                      'Sexo',
                      pet.genderBadgeText,
                    ),
                    _buildDetailRow(
                      Icons.medical_information_outlined,
                      'Estado Reproductivo',
                      pet.reproductiveBadgeText,
                    ),
                    _buildDetailRow(
                      Icons.health_and_safety_outlined,
                      'Desparasitación Interna y Externa',
                      (pet.dewormedInternal && pet.dewormedExternal) ? 'Al día (Completa)' : 'Parcial',
                    ),
                    _buildDetailRow(
                      Icons.qr_code_2_outlined,
                      'Microchip Identificatorio',
                      pet.hasMicrochip ? 'Implantado y Registrado' : 'No colocado',
                    ),

                    const SizedBox(height: 20),

                    // Hábitos y Convivencia
                    const Text(
                      'Convivencia e Higiene',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailBoolean(
                      Icons.clean_hands_outlined,
                      pet.species == 'cat' ? 'Usa arenero' : 'Hace necesidades afuera en paseos',
                      pet.houseTrained,
                    ),
                    _buildDetailBoolean(Icons.pets, 'Sociable con perros', pet.goodWithDogs),
                    _buildDetailBoolean(Icons.pets, 'Sociable con gatos', pet.goodWithCats),
                    _buildDetailBoolean(Icons.child_care, 'Sociable con niños', pet.goodWithKids),
                    _buildDetailBoolean(Icons.home_outlined, 'Requiere patio obligatorio', pet.requiresYard),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDetailBoolean(IconData icon, String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? AppTheme.successGreen : Colors.grey[400],
            size: 18,
          ),
        ],
      ),
    );
  }
}
