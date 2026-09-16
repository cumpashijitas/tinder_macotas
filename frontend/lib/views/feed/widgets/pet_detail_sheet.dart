import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/pet_model.dart';
import '../../../controllers/adopter_form_controller.dart';
import '../../../controllers/swipe_controller.dart';
import '../../../services/compatibility_service.dart';
import '../../pets/widgets/health_booklet_modal.dart';

class PetDetailSheet extends StatelessWidget {
  final PetModel pet;
  final VoidCallback? onApplyAdoption;

  const PetDetailSheet({super.key, required this.pet, this.onApplyAdoption});

  static Future<void> show(
    BuildContext context,
    PetModel pet, {
    VoidCallback? onApplyAdoption,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          PetDetailSheet(pet: pet, onApplyAdoption: onApplyAdoption),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIndividual = pet.publisherType == 'individual_rescuer';
    final isRelocated = pet.isRelocated;
    final adopterForm = Provider.of<AdopterFormController>(context).form;
    final matchResult = CompatibilityService.calculateMatch(
      adopter: adopterForm,
      pet: pet,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                // Imagen principal
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      pet.photos.isNotEmpty ? pet.photos.first : 'https://images.unsplash.com/photo-1548767797-d8c844163c4c?auto=format&fit=crop&w=800&q=80',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.pets,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cabecera: Nombre y Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  pet.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                pet.gender == 'female'
                                    ? Icons.female
                                    : Icons.male,
                                color: pet.gender == 'female'
                                    ? Colors.pink
                                    : Colors.blue,
                                size: 22,
                              ),
                            ],
                          ),
                          Text(
                            '${pet.breed} • ${pet.ageFormatted} (${pet.ageStageLabel})',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isRelocated
                            ? Colors.red.withValues(alpha: 0.12)
                            : (isIndividual
                                  ? Colors.orange.withValues(alpha: 0.15)
                                  : AppTheme.primaryColor.withValues(
                                      alpha: 0.15,
                                    )),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRelocated
                                ? Icons.warning_amber_rounded
                                : (isIndividual
                                      ? Icons.volunteer_activism
                                      : Icons.verified),
                            size: 14,
                            color: isRelocated
                                ? Colors.red[800]
                                : (isIndividual
                                      ? Colors.orange[800]
                                      : AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pet.publisherBadgeText,
                            style: TextStyle(
                              color: isRelocated
                                  ? Colors.red[800]
                                  : (isIndividual
                                        ? Colors.orange[800]
                                        : AppTheme.primaryColor),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Alerta de Reubicación si aplica
                if (isRelocated && pet.relocationReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[300]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Motivo de Reubicación Excepcional:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.brown,
                                ),
                              ),
                              Text(
                                pet.relocationReason!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Tarjeta de Compatibilidad (% Match)
                Container(
                  padding: const EdgeInsets.all(14),
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
                              Icon(
                                Icons.auto_awesome,
                                color: AppTheme.successGreen,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Índice de Compatibilidad',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${matchResult.percentage}% Match',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...matchResult.positiveMatches.map(
                        (pos) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check,
                                size: 14,
                                color: AppTheme.successGreen,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  pos,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Libreta Sanitaria (el contrato de adopción se genera recién tras el match)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: const Text(
                      'Libreta Sanitaria',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => HealthBookletModal.show(context, pet),
                  ),
                ),

                const Divider(height: 28),

                // Historia y Personalidad
                const Text(
                  'Historia y Personalidad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pet.story,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 16),

                // Ficha Clínica y Reproductiva
                const Text(
                  'Ficha Clínica y Reproductiva',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),

                _buildDetailRow(
                  Icons.medical_information_outlined,
                  'Estado Reproductivo',
                  pet.reproductiveBadgeText,
                ),
                _buildDetailRow(
                  Icons.health_and_safety_outlined,
                  'Desparasitación',
                  (pet.dewormedInternal && pet.dewormedExternal)
                      ? 'Al día (Interna y Externa)'
                      : 'Parcial',
                ),
                _buildDetailRow(
                  Icons.qr_code_2_outlined,
                  'Microchip Identificatorio',
                  pet.hasMicrochip ? 'Implantado y Registrado' : 'No colocado',
                ),
                if (pet.specialNeeds != null && pet.specialNeeds!.isNotEmpty)
                  _buildDetailRow(
                    Icons.healing,
                    'Necesidades Especiales',
                    pet.specialNeeds!,
                  ),

                const SizedBox(height: 16),

                // Hábitos y Convivencia
                const Text(
                  'Convivencia e Higiene',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailBoolean(
                  Icons.clean_hands_outlined,
                  pet.species == 'cat'
                      ? 'Usa arenero'
                      : 'Hace necesidades afuera en paseos',
                  pet.houseTrained,
                ),
                _buildDetailBoolean(
                  Icons.pets,
                  'Sociable con otros perros',
                  pet.goodWithDogs,
                ),
                _buildDetailBoolean(
                  Icons.pets,
                  'Sociable con gatos',
                  pet.goodWithCats,
                ),
                _buildDetailBoolean(
                  Icons.child_care,
                  'Sociable con niños',
                  pet.goodWithKids,
                ),
                _buildDetailBoolean(
                  Icons.home_outlined,
                  'Requiere patio obligatorio',
                  pet.requiresYard,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Botón de Postulación
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, -2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        icon: const Icon(Icons.favorite, color: Colors.white),
                        label: Text(
                          'Postularme para Adoptar a ${pet.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          if (onApplyAdoption != null) {
                            Navigator.pop(context);
                            onApplyAdoption!();
                            return;
                          }
                          final swipeController = Provider.of<SwipeController>(
                            context,
                            listen: false,
                          );
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          final matched = await swipeController.applyToAdopt(
                            pet,
                          );
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                matched
                                    ? '¡Postulación enviada por ${pet.name}! El publicador revisará tu formulario.'
                                    : 'No se pudo enviar la postulación. Intenta nuevamente.',
                              ),
                              backgroundColor: matched
                                  ? AppTheme.successGreen
                                  : AppTheme.rejectRed,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBoolean(IconData icon, String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? AppTheme.successGreen : Colors.grey[400],
            size: 16,
          ),
        ],
      ),
    );
  }
}
