import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/swipe_controller.dart';

class RelocationRequestScreen extends StatefulWidget {
  const RelocationRequestScreen({super.key});

  @override
  State<RelocationRequestScreen> createState() =>
      _RelocationRequestScreenState();
}

class _RelocationRequestScreenState extends State<RelocationRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _breedController = TextEditingController(text: 'Mestizo');
  final _ageController = TextEditingController(text: '2');
  final _reasonController = TextEditingController();
  final _storyController = TextEditingController();
  final _photoUrlController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=800&q=80',
  );

  String _species = 'dog';
  String _gender = 'male';
  String _size = 'medium';
  int _energyLevel = 3;

  bool _isVaccinated = true;
  bool _isNeutered = true;
  bool _hasMicrochip = false;
  bool _houseTrained = true;
  bool _goodWithDogs = true;
  bool _goodWithCats = true;
  bool _goodWithKids = true;
  bool _swornStatement = false;
  bool _acceptsReview = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthController>(context, listen: false).ensureLocationCaptured();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _reasonController.dispose();
    _storyController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  void _submitRelocation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_swornStatement || !_acceptsReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes aceptar la declaración jurada y los términos de evaluación.',
          ),
          backgroundColor: AppTheme.rejectRed,
        ),
      );
      return;
    }

    final swipeController = Provider.of<SwipeController>(
      context,
      listen: false,
    );
    final authController = Provider.of<AuthController>(
      context,
      listen: false,
    );
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isSubmitting = true);

    final payload = {
      'name': _nameController.text.trim(),
      'species': _species,
      'breed': _breedController.text.trim(),
      'age_years': double.tryParse(_ageController.text.trim()) ?? 2.0,
      'gender': _gender,
      'size': _size,
      'energy_level': _energyLevel,
      'is_vaccinated': _isVaccinated,
      'is_neutered': _isNeutered,
      'has_microchip': _hasMicrochip,
      'house_trained': _houseTrained,
      'good_with_dogs': _goodWithDogs,
      'good_with_cats': _goodWithCats,
      'good_with_kids': _goodWithKids,
      'story': _storyController.text.trim().isNotEmpty
          ? _storyController.text.trim()
          : 'Mascota en búsqueda urgente de hogar responsable por fuerza mayor.',
      'photos': [_photoUrlController.text.trim()],
      'relocation_reason': _reasonController.text.trim(),
      if (authController.profile?.latitude != null)
        'latitude': authController.profile!.latitude,
      if (authController.profile?.longitude != null)
        'longitude': authController.profile!.longitude,
    };

    final relocatedPet = await swipeController.submitRelocation(payload);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (relocatedPet == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            swipeController.errorMessage ??
                'No se pudo enviar la solicitud de reubicación',
          ),
          backgroundColor: AppTheme.rejectRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppTheme.successGreen),
            SizedBox(width: 8),
            Text('Solicitud Registrada'),
          ],
        ),
        content: Text(
          'El perfil de ${_nameController.text} ha sido incorporado con el distintivo de "Reubicación por Causa de Fuerza Mayor". Los adoptantes podrán postularse tras ser revisada la causa.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reubicación por Fuerza Mayor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alerta de Advertencia de Política Anti-Descarte
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber[300]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: Colors.amber,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Módulo Excepcional y Auditado',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.brown,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PetMatch es una plataforma de adopción ética y tenencia responsable. No permitimos el descarte de animales ni la comercialización. Esta sección es estrictamente para reubicaciones por causas de fuerza mayor debidamente justificadas.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.brown[900],
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sección 1: Causa de Fuerza Mayor
                  const Text(
                    '1. Justificación de Causa de Fuerza Mayor',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Explica detalladamente el motivo de la imposibilidad de mantener a la mascota (ej: mudanza internacional de urgencia, pérdida de vivienda, fallecimiento o condición médica severa comprobable). Mínimo 20 caracteres.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe con claridad y honestidad la circunstancia de fuerza mayor...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 20) {
                        return 'Por favor explica la causa con al menos 20 caracteres.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Sección 2: Datos de la Mascota
                  const Text(
                    '2. Datos de la Mascota',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la Mascota',
                      prefixIcon: const Icon(Icons.pets),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ingresa el nombre'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _species,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Especie',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'dog',
                              child: Text(
                                '🐶 Perro',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'cat',
                              child: Text(
                                '🐱 Gato',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _species = val ?? 'dog'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _gender,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Sexo',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'male',
                              child: Text(
                                'Macho',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text(
                                'Hembra',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _gender = val ?? 'male'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _breedController,
                          decoration: InputDecoration(
                            labelText: 'Raza o Cruza',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa la raza'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Edad (años)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || double.tryParse(v) == null)
                              ? 'Edad inválida'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _size,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Tamaño',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'small',
                              child: Text(
                                'Pequeño',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'medium',
                              child: Text(
                                'Mediano',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'large',
                              child: Text(
                                'Grande',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'giant',
                              child: Text(
                                'Gigante',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _size = val ?? 'medium'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _energyLevel,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Energía (1 al 5)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: [1, 2, 3, 4, 5]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    '$e / 5',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _energyLevel = val ?? 3),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _photoUrlController,
                    decoration: InputDecoration(
                      labelText: 'URL de la Foto',
                      prefixIcon: const Icon(Icons.photo_camera_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ingresa una foto'
                        : null,
                  ),

                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _storyController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Historia, hábitos y carácter de la mascota',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sección 3: Plan Clínico y Sanitario
                  const Text(
                    '3. Plan Clínico y Vacunación',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),

                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vacunación al día'),
                    value: _isVaccinated,
                    onChanged: (val) => setState(() => _isVaccinated = val),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Esterilizado / Castrado'),
                    value: _isNeutered,
                    onChanged: (val) => setState(() => _isNeutered = val),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tiene Microchip implantado'),
                    value: _hasMicrochip,
                    onChanged: (val) => setState(() => _hasMicrochip = val),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Acostumbrado/a a hacer sus necesidades afuera/arenero',
                    ),
                    value: _houseTrained,
                    onChanged: (val) => setState(() => _houseTrained = val),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Convive bien con niños'),
                    value: _goodWithKids,
                    onChanged: (val) => setState(() => _goodWithKids = val),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Convive bien con perros'),
                    value: _goodWithDogs,
                    onChanged: (val) => setState(() => _goodWithDogs = val),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Convive bien con gatos'),
                    value: _goodWithCats,
                    onChanged: (val) => setState(() => _goodWithCats = val),
                  ),

                  const SizedBox(height: 20),

                  // Declaraciones y Compromisos
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Declaro bajo juramento que esta solicitud responde exclusivamente a una causa de fuerza mayor y no persigue ningún fin de lucro ni comercialización.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: _swornStatement,
                          onChanged: (val) =>
                              setState(() => _swornStatement = val ?? false),
                        ),
                        const Divider(),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Acepto que mi solicitud sea auditada y evaluada por el equipo de moderación o refugio zonal antes de su publicación.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: _acceptsReview,
                          onChanged: (val) =>
                              setState(() => _acceptsReview = val ?? false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Botón Enviar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRelocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Enviar Solicitud de Reubicación',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
