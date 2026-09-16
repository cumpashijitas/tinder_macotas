import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AdoptionStory {
  final String id;
  final String petName;
  final String familyName;
  final String shelterName;
  final String story;
  final String photoUrl;
  final String timeAdopted;
  int likes;
  bool isLiked;

  AdoptionStory({
    required this.id,
    required this.petName,
    required this.familyName,
    required this.shelterName,
    required this.story,
    required this.photoUrl,
    required this.timeAdopted,
    required this.likes,
    this.isLiked = false,
  });
}

class HappyTailsScreen extends StatefulWidget {
  const HappyTailsScreen({super.key});

  @override
  State<HappyTailsScreen> createState() => _HappyTailsScreenState();
}

class _HappyTailsScreenState extends State<HappyTailsScreen> {
  late List<AdoptionStory> _stories;

  @override
  void initState() {
    super.initState();
    _stories = [
      AdoptionStory(
        id: '1',
        petName: 'Bruno (Antes "Rocky Jr")',
        familyName: 'Familia Valenzuela',
        shelterName: 'Refugio Patitas Felices',
        story:
            '¡Bruno ya cumplió 6 meses con nosotros! Pasó de estar asustado en una esquina a dormir en nuestras camas y correr por la plaza todos los días. Adoptar cambió nuestro hogar por completo.',
        photoUrl: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=800&q=80',
        timeAdopted: 'Adoptado hace 6 meses',
        likes: 128,
      ),
      AdoptionStory(
        id: '2',
        petName: 'Milo',
        familyName: 'Lucía y Tomás',
        shelterName: 'Camada Particular de los Hermanos Gómez',
        story:
            'Adoptamos a Milo cuando era un cachorro destetado de 2 meses. Hoy es el rey del departamento y el compañero más dulce que pudimos haber soñado.',
        photoUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=800&q=80',
        timeAdopted: 'Adoptado hace 3 meses',
        likes: 95,
      ),
      AdoptionStory(
        id: '3',
        petName: 'Nina',
        familyName: 'Esteban S.',
        shelterName: 'Rescate Independiente',
        story:
            'Nina tenía miedo a los ruidos y a quedarse sola. Con paciencia y amor, hoy pasea feliz con su collar y es una perrita llena de vida.',
        photoUrl: 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=800&q=80',
        timeAdopted: 'Adoptada hace 1 año',
        likes: 210,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finales Felices ❤️'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _stories.length,
            itemBuilder: (context, index) {
              final story = _stories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera con datos del adoptante
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                        child: const Icon(Icons.family_restroom, color: AppTheme.primaryColor),
                      ),
                      title: Text(story.familyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${story.petName} • ${story.timeAdopted}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Adoptado 🎉',
                            style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    // Fotografía
                    ClipRRect(
                      child: Image.network(
                        story.photoUrl,
                        height: 260,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Testimonio
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.story,
                            style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Facilitado por: ${story.shelterName}',
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                          ),
                          const Divider(height: 24),

                          // Botones de interacción
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      story.isLiked ? Icons.favorite : Icons.favorite_border,
                                      color: story.isLiked ? Colors.red : Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        story.isLiked = !story.isLiked;
                                        if (story.isLiked) {
                                          story.likes++;
                                        } else {
                                          story.likes--;
                                        }
                                      });
                                    },
                                  ),
                                  Text('${story.likes} Me alegra'),
                                ],
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.share_outlined, size: 18),
                                label: const Text('Compartir'),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Enlace de historia copiado para compartir.')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
