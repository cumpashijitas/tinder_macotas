import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/pet_model.dart';
import '../../../models/adopter_form_model.dart';
import '../../../services/compatibility_service.dart';

class PetCardWidget extends StatelessWidget {
  final PetModel pet;
  final AdopterFormModel? adopterProfile;
  final VoidCallback? onInfoTap;

  const PetCardWidget({
    super.key,
    required this.pet,
    this.adopterProfile,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = pet.photos.isNotEmpty
        ? pet.photos.first
        : 'https://images.unsplash.com/photo-1548767797-d8c844163c4c?auto=format&fit=crop&w=800&q=80';

    final isIndividual = pet.publisherType == 'individual_rescuer';

    // Cálculo del % de Compatibilidad con el adoptante actual
    final matchResult = CompatibilityService.calculateMatch(
      adopter: adopterProfile ?? AdopterFormModel(),
      pet: pet,
    );

    // Distancia simulada basada en el ID para demostración realista
    final distanceKm = ((pet.id.hashCode.abs() % 15) + 1.2).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Imagen de fondo
            Image.network(
              photoUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.pets, size: 64, color: Colors.grey),
              ),
            ),

            // 2. Gradiente oscuro inferior para contraste de texto
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  stops: const [0.45, 0.65, 1.0],
                ),
              ),
            ),

            // 3. Insignia superior izquierda: Tipo de Publicador (Refugio vs Camada)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isIndividual
                      ? Colors.orange[800]!.withValues(alpha: 0.88)
                      : Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isIndividual ? Icons.volunteer_activism : Icons.verified,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      pet.publisherBadgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Insignia superior derecha: % Match de Compatibilidad
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: matchResult.percentage >= 85
                      ? AppTheme.successGreen.withValues(alpha: 0.9)
                      : Colors.amber[800]!.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      matchResult.matchBadgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Información principal de la Mascota
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                pet.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              pet.ageFormatted,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onInfoTap,
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Distancia estimada
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'A $distanceKm km de tu ubicación',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Insignias de Sexo, Raza y Reproducción
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildBadge(
                        pet.gender == 'female' ? Icons.female : Icons.male,
                        '${pet.genderBadgeText} • ${pet.breed}',
                        highlight: true,
                      ),
                      _buildBadge(
                        pet.isNeutered
                            ? Icons.check_circle_outline
                            : Icons.schedule,
                        pet.reproductiveBadgeText,
                      ),
                      if (pet.vaccinesApplied.isNotEmpty)
                        _buildBadge(
                          Icons.medical_services_outlined,
                          '${pet.vaccinesApplied.length} vacunas',
                        ),
                      if (pet.goodWithKids)
                        _buildBadge(Icons.child_care, 'Apto niños'),
                      if (pet.houseTrained)
                        _buildBadge(
                          Icons.clean_hands_outlined,
                          pet.species == 'cat'
                              ? 'Usa arenero'
                              : 'Paseos limpios',
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Historia / Descripción
                  Text(
                    pet.story,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.primaryColor.withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
