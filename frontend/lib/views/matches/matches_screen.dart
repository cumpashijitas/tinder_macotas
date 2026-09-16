import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/match_model.dart';
import '../../models/pet_model.dart';
import '../chat/chat_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos demo para previsualizar la pantalla de matches
    final sampleMatches = [
      MatchModel(
        id: 'm1',
        petId: 'p1',
        adopterId: 'u1',
        shelterId: 's1',
        status: 'approved_for_chat',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        pet: PetModel(
          id: 'p1',
          shelterId: 's1',
          name: 'Rocky',
          species: 'dog',
          breed: 'Mestizo Labrador',
          ageYears: 2.0,
          gender: 'male',
          size: 'medium',
          energyLevel: 3,
          isVaccinated: true,
          isNeutered: true,
          goodWithDogs: true,
          goodWithCats: false,
          goodWithKids: true,
          requiresYard: false,
          story: 'Rocky está muy contento de conocerte.',
          photos: [
            'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=800&q=80',
          ],
          status: 'available',
        ),
      ),
      MatchModel(
        id: 'm2',
        petId: 'p2',
        adopterId: 'u1',
        shelterId: 's1',
        status: 'pending_review',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        pet: PetModel(
          id: 'p2',
          shelterId: 's1',
          name: 'Luna',
          species: 'cat',
          breed: 'Común Europeo',
          ageYears: 1.2,
          gender: 'female',
          size: 'small',
          energyLevel: 2,
          isVaccinated: true,
          isNeutered: true,
          goodWithDogs: false,
          goodWithCats: true,
          goodWithKids: true,
          requiresYard: false,
          story: 'En revisión por el equipo del refugio.',
          photos: [
            'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=800&q=80',
          ],
          status: 'available',
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Solicitudes y Matches'),
      ),
      body: sampleMatches.isEmpty
          ? const Center(
              child: Text(
                'Aún no tienes matches.\n¡Desliza a la derecha en las mascotas que quieras adoptar!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sampleMatches.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final match = sampleMatches[index];
                final pet = match.pet;

                final isApproved = match.status == 'approved_for_chat';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
                      pet?.photos.first ??
                          'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=800&q=80',
                    ),
                  ),
                  title: Text(
                    pet?.name ?? 'Mascota',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pet?.breed} • ${pet?.ageFormatted}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isApproved
                              ? AppTheme.successGreen.withValues(alpha: 0.15)
                              : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          match.statusBadgeText,
                          style: TextStyle(
                            color: isApproved ? AppTheme.successGreen : Colors.amber[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: isApproved
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (pet != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    pet: pet,
                                    shelterName: 'Refugio Patitas Felices',
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      : const Icon(Icons.hourglass_empty, color: Colors.grey, size: 20),
                );
              },
            ),
    );
  }
}
