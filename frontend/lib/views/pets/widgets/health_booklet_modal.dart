import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/pet_model.dart';

class HealthBookletModal extends StatelessWidget {
  final PetModel pet;

  const HealthBookletModal({super.key, required this.pet});

  static void show(BuildContext context, PetModel pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HealthBookletModal(pet: pet),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book, color: Colors.blue, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Libreta Sanitaria Digital',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Historial clínico oficial de ${pet.name}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 32),

                const Text('Vacunación Aplicada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (pet.vaccinesApplied.isEmpty)
                  const Text('No registra vacunas aplicadas aún.', style: TextStyle(color: AppTheme.textMuted))
                else
                  ...pet.vaccinesApplied.map((vac) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle, color: AppTheme.successGreen),
                      title: Text(vac, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Dosis certificada por veterinario matriculado', style: TextStyle(fontSize: 12)),
                      trailing: Text(
                        'Al día',
                        style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                const Text('Desparasitación y Prevención', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildHealthItem(
                  'Desparasitación Interna',
                  pet.dewormedInternal ? 'Completada (Pastilla antiparasitaria)' : 'Pendiente',
                  pet.dewormedInternal,
                ),
                _buildHealthItem(
                  'Control de Pulgas y Garrapatas',
                  pet.dewormedExternal ? 'Al día (Pipeta protectora aplicada)' : 'Pendiente',
                  pet.dewormedExternal,
                ),
                _buildHealthItem(
                  'Microchip de Identificación',
                  pet.hasMicrochip ? 'Implantado bajo piel con código ISO' : 'No implantado',
                  pet.hasMicrochip,
                ),

                const SizedBox(height: 24),

                // Recordatorios y Próximos Vencimientos
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.alarm, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Próximos Controles y Revacunación',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '• Próxima pipeta antipulgas: dentro de 30 días.',
                        style: TextStyle(fontSize: 13, color: Colors.blue[950]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Refuerzo anual de Antirrábica: recomendada anualmente.',
                        style: TextStyle(fontSize: 13, color: Colors.blue[950]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String title, String subtitle, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_outline : Icons.error_outline,
            color: isDone ? AppTheme.successGreen : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
