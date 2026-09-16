import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../models/story_model.dart';

class HappyTailsScreen extends StatefulWidget {
  const HappyTailsScreen({super.key});

  @override
  State<HappyTailsScreen> createState() => _HappyTailsScreenState();
}

class _HappyTailsScreenState extends State<HappyTailsScreen> {
  final ApiService _api = ApiService();
  List<StoryModel> _stories = [];
  bool _isLoading = true;
  String? _errorMessage;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _api.get('/stories');
      if (!mounted) return;
      setState(() {
        _stories = (data as List<dynamic>)
            .map((e) => StoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike(StoryModel story) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final wasLiked = story.likedBy(userId);
    final index = _stories.indexWhere((s) => s.id == story.id);
    if (index == -1) return;

    setState(() => _stories[index] = story.toggleLike(userId));

    try {
      if (wasLiked) {
        await _api.delete('/stories/${story.id}/like');
      } else {
        await _api.post('/stories/${story.id}/like');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _stories[index] = story);
    }
  }

  Future<void> _openShareStoryDialog() async {
    final petNameController = TextEditingController();
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final photoUrlController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Compartir un Final Feliz'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: petNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la mascota',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título (mín. 5 caracteres)',
                  ),
                  validator: (v) => (v == null || v.trim().length < 5)
                      ? 'Mínimo 5 caracteres'
                      : null,
                ),
                TextFormField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Cuéntanos tu historia (mín. 20 caracteres)',
                  ),
                  validator: (v) => (v == null || v.trim().length < 20)
                      ? 'Mínimo 20 caracteres'
                      : null,
                ),
                TextFormField(
                  controller: photoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL de foto (opcional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );

    if (submitted != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.post('/stories', {
        'pet_name': petNameController.text.trim(),
        'title': titleController.text.trim(),
        'content': contentController.text.trim(),
        if (photoUrlController.text.trim().isNotEmpty)
          'photo_url': photoUrlController.text.trim(),
      });
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('¡Historia publicada!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      _loadStories();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo publicar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finales Felices ❤️'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStories,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openShareStoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Compartir Historia'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudieron cargar las historias: $_errorMessage',
                ),
              ),
            )
          : _stories.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no hay historias publicadas.\n¡Sé el primero en compartir un final feliz!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: RefreshIndicator(
                  onRefresh: _loadStories,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _stories.length,
                    itemBuilder: (context, index) {
                      final story = _stories[index];
                      final liked = story.likedBy(_currentUserId);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.15),
                                child: const Icon(
                                  Icons.family_restroom,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              title: Text(
                                story.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                story.petName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Adoptado 🎉',
                                  style: TextStyle(
                                    color: AppTheme.successGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (story.photoUrl != null)
                              ClipRRect(
                                child: Image.network(
                                  story.photoUrl!,
                                  height: 260,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    height: 260,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.pets,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    story.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    story.content,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          liked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: liked
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                        onPressed: () => _toggleLike(story),
                                      ),
                                      Text('${story.likeCount} Me alegra'),
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
            ),
    );
  }
}
