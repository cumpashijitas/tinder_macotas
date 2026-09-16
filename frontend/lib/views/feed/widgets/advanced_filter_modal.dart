import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/pet_filter_controller.dart';
import '../../../controllers/swipe_controller.dart';

class AdvancedFilterModal extends StatelessWidget {
  const AdvancedFilterModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdvancedFilterModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = Provider.of<PetFilterController>(context);
    final swipe = Provider.of<SwipeController>(context, listen: false);
    final matchingCount = filter.applyFilters(swipe.pets).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtros de Búsqueda',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                TextButton(
                  onPressed: filter.resetFilters,
                  child: const Text('Limpiar todo'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // Radio de distancia
                _buildSectionHeader('Distancia Máxima', '${filter.maxDistanceKm.round()} km'),
                Slider(
                  value: filter.maxDistanceKm,
                  min: 5.0,
                  max: 100.0,
                  divisions: 19,
                  label: '${filter.maxDistanceKm.round()} km',
                  activeColor: AppTheme.primaryColor,
                  onChanged: (val) => filter.setMaxDistance(val),
                ),
                const SizedBox(height: 12),

                // Especie
                _buildSectionHeader('Especie', null),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: 'Todos',
                      selected: filter.selectedSpecies == 'all',
                      onSelected: () => filter.setSelectedSpecies('all'),
                    ),
                    _buildChoiceChip(
                      label: '🐶 Perros',
                      selected: filter.selectedSpecies == 'dog',
                      onSelected: () => filter.setSelectedSpecies('dog'),
                    ),
                    _buildChoiceChip(
                      label: '🐱 Gatos',
                      selected: filter.selectedSpecies == 'cat',
                      onSelected: () => filter.setSelectedSpecies('cat'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Tipo de Publicación
                _buildSectionHeader('Publicado por', null),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChoiceChip(
                      label: 'Todos',
                      selected: filter.selectedPublisherType == 'all',
                      onSelected: () => filter.setSelectedPublisherType('all'),
                    ),
                    _buildChoiceChip(
                      label: '🏠 Refugios / ONG',
                      selected: filter.selectedPublisherType == 'shelter',
                      onSelected: () => filter.setSelectedPublisherType('shelter'),
                    ),
                    _buildChoiceChip(
                      label: '🍼 Camadas Particulares',
                      selected: filter.selectedPublisherType == 'individual_rescuer',
                      onSelected: () => filter.setSelectedPublisherType('individual_rescuer'),
                    ),
                    _buildChoiceChip(
                      label: '⚠️ Reubicación / Mudanza',
                      selected: filter.selectedPublisherType == 'relinquished',
                      onSelected: () => filter.setSelectedPublisherType('relinquished'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Rango de Edad (Etapas)
                _buildSectionHeader('Etapa de Vida', null),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildMultiFilterChip(
                      label: 'Cachorro (<1 año)',
                      selected: filter.selectedAgeStages.contains('puppy'),
                      onSelected: () => filter.toggleAgeStage('puppy'),
                    ),
                    _buildMultiFilterChip(
                      label: 'Joven (1-3 años)',
                      selected: filter.selectedAgeStages.contains('young'),
                      onSelected: () => filter.toggleAgeStage('young'),
                    ),
                    _buildMultiFilterChip(
                      label: 'Adulto (3-7 años)',
                      selected: filter.selectedAgeStages.contains('adult'),
                      onSelected: () => filter.toggleAgeStage('adult'),
                    ),
                    _buildMultiFilterChip(
                      label: 'Senior (+8 años)',
                      selected: filter.selectedAgeStages.contains('senior'),
                      onSelected: () => filter.toggleAgeStage('senior'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Tamaño
                _buildSectionHeader('Tamaño', null),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildMultiFilterChip(
                      label: 'Pequeño',
                      selected: filter.selectedSizes.contains('small'),
                      onSelected: () => filter.toggleSize('small'),
                    ),
                    _buildMultiFilterChip(
                      label: 'Mediano',
                      selected: filter.selectedSizes.contains('medium'),
                      onSelected: () => filter.toggleSize('medium'),
                    ),
                    _buildMultiFilterChip(
                      label: 'Grande',
                      selected: filter.selectedSizes.contains('large'),
                      onSelected: () => filter.toggleSize('large'),
                    ),
                    _buildMultiFilterChip(
                      label: 'Gigante',
                      selected: filter.selectedSizes.contains('giant'),
                      onSelected: () => filter.toggleSize('giant'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Nivel de energía máximo
                _buildSectionHeader('Nivel de Energía Máximo', 'Hasta ${filter.maxEnergyLevel}/5'),
                Slider(
                  value: filter.maxEnergyLevel.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '${filter.maxEnergyLevel} de 5',
                  activeColor: Colors.amber[700],
                  onChanged: (val) => filter.setMaxEnergyLevel(val.round()),
                ),
                const SizedBox(height: 14),

                // Convivencia y Temperamento
                _buildSectionHeader('Convivencia y Entorno', null),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Apto para familias con niños', style: TextStyle(fontSize: 14)),
                  value: filter.onlyGoodWithKids,
                  onChanged: (val) => filter.setOnlyGoodWithKids(val),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sociable con otros perros', style: TextStyle(fontSize: 14)),
                  value: filter.onlyGoodWithDogs,
                  onChanged: (val) => filter.setOnlyGoodWithDogs(val),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sociable con gatos', style: TextStyle(fontSize: 14)),
                  value: filter.onlyGoodWithCats,
                  onChanged: (val) => filter.setOnlyGoodWithCats(val),
                ),

                const SizedBox(height: 14),

                // Plan Sanitario y Necesidades Especiales
                _buildSectionHeader('Plan Sanitario y Cuidados', null),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vacunación completa', style: TextStyle(fontSize: 14)),
                  value: filter.onlyVaccinated,
                  onChanged: (val) => filter.setOnlyVaccinated(val),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Esterilizado / Castrado', style: TextStyle(fontSize: 14)),
                  value: filter.onlyNeutered,
                  onChanged: (val) => filter.setOnlyNeutered(val),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Solo con Necesidades Especiales / Cuidados Médicos', style: TextStyle(fontSize: 14)),
                  value: filter.onlySpecialNeeds,
                  onChanged: (val) => filter.setOnlySpecialNeeds(val),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Ver $matchingCount ${matchingCount == 1 ? 'Mascota' : 'Mascotas'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? extra) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          if (extra != null)
            Text(
              extra,
              style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.18),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildMultiFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.18),
      checkmarkColor: AppTheme.primaryColor,
      onSelected: (_) => onSelected(),
    );
  }
}
