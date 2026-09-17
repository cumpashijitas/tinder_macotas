import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/pet_model.dart';
import '../../services/compatibility_service.dart';
import '../../controllers/adopter_form_controller.dart';
import '../../controllers/pet_filter_controller.dart';
import '../../controllers/swipe_controller.dart';
import 'widgets/pet_detail_sheet.dart';

class PetGridFeedView extends StatelessWidget {
  final List<PetModel> pets;

  const PetGridFeedView({super.key, required this.pets});

  @override
  Widget build(BuildContext context) {
    final filter = Provider.of<PetFilterController>(context);
    final swipe = Provider.of<SwipeController>(context, listen: false);
    final adopterForm = Provider.of<AdopterFormController>(
      context,
      listen: false,
    ).form;

    if (pets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 72,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay mascotas con estos filtros',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prueba ampliando el radio de distancia o limpiando los filtros seleccionados.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Restablecer Filtros'),
                onPressed: filter.resetFilters,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount;
        final double childAspectRatio;

        if (constraints.maxWidth > 1100) {
          crossAxisCount = 4;
          childAspectRatio = 0.68;
        } else if (constraints.maxWidth > 700) {
          crossAxisCount = 3;
          childAspectRatio = 0.63;
        } else if (constraints.maxWidth > 400) {
          crossAxisCount = 2;
          childAspectRatio = 0.56;
        } else {
          // Teléfonos móviles compactos (<= 400px)
          crossAxisCount = 2;
          childAspectRatio = 0.52;
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: pets.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final pet = pets[index];
                final distanceKm = filter.getPetDistanceKm(pet);
                final matchResult = CompatibilityService.calculateMatch(
                  adopter: adopterForm,
                  pet: pet,
                );

                return _PetGridCard(
                  pet: pet,
                  distanceKm: distanceKm,
                  matchPercentage: matchResult.percentage,
                  onTap: () => PetDetailSheet.show(
                    context,
                    pet,
                    onApplyAdoption: () {
                      swipe.handleSwipe(
                        swipe.pets.indexOf(pet),
                        null,
                        // right swipe indicates interest
                        CardSwiperDirection.right,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '¡Postulación enviada por ${pet.name}!',
                          ),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _PetGridCard extends StatelessWidget {
  final PetModel pet;
  final double? distanceKm;
  final int matchPercentage;
  final VoidCallback onTap;

  const _PetGridCard({
    required this.pet,
    required this.distanceKm,
    required this.matchPercentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRelocated = pet.isRelocated;
    final isIndividual = pet.publisherType == 'individual_rescuer';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto con badges flotantes
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    pet.photos.isNotEmpty ? pet.photos.first : 'https://images.unsplash.com/photo-1548767797-d8c844163c4c?auto=format&fit=crop&w=800&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.pets,
                        size: 36,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  // Gradiente inferior para contraste de texto si fuera necesario
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.25),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Badge de Compatibilidad (% Match)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[800]!.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$matchPercentage%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Badge de Distancia (km) — sólo si tenemos ubicación real de ambos lados
                  if (distanceKm != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${distanceKm!.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Badge de Reubicación si aplica
                  if (isRelocated)
                    Positioned(
                      bottom: 6,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[700]!.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 9,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Mudanza',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (isIndividual)
                    Positioned(
                      bottom: 6,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[800]!.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volunteer_activism,
                              color: Colors.white,
                              size: 9,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Camada',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Información de la mascota
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Fila: Nombre y Sexo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            pet.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          pet.gender == 'female' ? Icons.female : Icons.male,
                          color: pet.gender == 'female'
                              ? Colors.pink
                              : Colors.blue,
                          size: 16,
                        ),
                      ],
                    ),

                    // Raza y Edad
                    Text(
                      '${pet.breed} • ${pet.ageFormatted}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Tags de salud y convivencia (máximo 2 para evitar desborde vertical)
                    Builder(
                      builder: (_) {
                        final tags = [
                          if (pet.isVaccinated)
                            _buildMiniTag('💉 Vacunas', Colors.blue),
                          if (pet.isNeutered)
                            _buildMiniTag('✂ Castrado/a', Colors.teal),
                          if (pet.goodWithKids)
                            _buildMiniTag('👶 Niños', Colors.purple),
                          if (pet.specialNeeds != null &&
                              pet.specialNeeds!.isNotEmpty)
                            _buildMiniTag('🩺 Cuidados', Colors.amber[800]!),
                        ];

                        return Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: tags.take(2).toList(),
                        );
                      },
                    ),

                    // Botón para ver perfil
                    SizedBox(
                      width: double.infinity,
                      height: 26,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: onTap,
                        child: const Text(
                          'Ver Perfil',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
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
