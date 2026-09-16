import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../controllers/matches_controller.dart';
import '../chat/chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MatchesController>(context, listen: false).loadMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MatchesController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Solicitudes y Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.isLoading
                ? null
                : () => controller.loadMatches(),
          ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.matches.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aún no tienes matches.\n¡Desliza a la derecha en las mascotas que quieras adoptar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => controller.loadMatches(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.matches.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final match = controller.matches[index];
                  final pet = match.pet;
                  final isChatEnabled = match.isChatEnabled;
                  final isRejected = match.status == 'rejected';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                        (pet != null && pet.photos.isNotEmpty)
                            ? pet.photos.first
                            : 'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=800&q=80',
                      ),
                    ),
                    title: Text(
                      pet?.name ?? 'Mascota',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pet?.breed ?? ''} • ${pet?.ageFormatted ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isRejected
                                ? AppTheme.rejectRed.withValues(alpha: 0.12)
                                : isChatEnabled
                                ? AppTheme.successGreen.withValues(alpha: 0.15)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            match.statusBadgeText,
                            style: TextStyle(
                              color: isRejected
                                  ? AppTheme.rejectRed
                                  : isChatEnabled
                                  ? AppTheme.successGreen
                                  : Colors.amber[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: isChatEnabled
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(match: match),
                                ),
                              );
                            },
                            child: const Text(
                              'Chat',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Icon(
                            isRejected ? Icons.close : Icons.hourglass_empty,
                            color: isRejected
                                ? AppTheme.rejectRed
                                : Colors.grey,
                            size: 20,
                          ),
                  );
                },
              ),
            ),
    );
  }
}
