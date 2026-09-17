import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/swipe_controller.dart';

class PublishPetScreen extends StatefulWidget {
  const PublishPetScreen({super.key});

  @override
  State<PublishPetScreen> createState() => _PublishPetScreenState();
}

class _PublishPetScreenState extends State<PublishPetScreen> {
  int _currentStep = 0;
  XFile? _selectedImage;

  // Paso 1: Datos Básicos y Origen
  String _species = 'dog';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController(
    text: 'Mestizo',
  );
  String _gender = 'male'; // 'male' | 'female'
  double _ageYears = 1.0;
  String _size = 'medium';
  String _origin = 'street_rescue'; // 'home_litter' | 'street_rescue' | 'shelter_born' | 'relinquished'
  bool _isLitter = false;
  bool _weaningCompleted = true; // Mínimo 60 días éticos

  // Paso 2: Plan Sanitario
  bool _isVaccinated = true;
  final Set<String> _selectedVaccines = {'Antirrábica'};
  bool _dewormedInternal = true;
  bool _dewormedExternal = true;
  bool _hasMicrochip = false;
  String _reproductiveStatus = 'neutered'; // 'neutered' | 'spayed' | 'requires_spay_agreement' | 'intact'
  final TextEditingController _specialNeedsController = TextEditingController();

  // Paso 3: Comportamiento
  bool _houseTrained = true;
  bool _goodWithDogs = true;
  bool _goodWithCats = true;
  bool _goodWithKids = true;
  bool _requiresYard = false;
  int _energyLevel = 3;
  int _stormAnxiety = 1;

  // Paso 4: Requisitos e Historia
  final TextEditingController _storyController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();
  bool _requiresContract = true;
  bool _requiresHomeCheck = false;
  bool _requiresFollowupPhotos = true;
  String _deliveryType = 'to_be_agreed';

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _specialNeedsController.dispose();
    _storyController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar Mascota en Adopción')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              children: [
                // Indicador de pasos
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: List.generate(4, (index) {
                      final active = index <= _currentStep;
                      return Expanded(
                        child: Container(
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: active
                                ? AppTheme.primaryColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: Text(
                    _stepTitle(_currentStep),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    children: [
                      if (_currentStep == 0)
                        _buildStepBasicInfo(authController),
                      if (_currentStep == 1) _buildStepHealth(),
                      if (_currentStep == 2) _buildStepBehavior(),
                      if (_currentStep == 3)
                        _buildStepRequirements(authController),
                    ],
                  ),
                ),

                // Barra inferior de botones
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _currentStep--),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Atrás'),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleNextOrSubmit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _currentStep == 3
                                      ? 'Publicar Mascota'
                                      : 'Siguiente',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0:
        return '1. Identificación, Sexo y Origen';
      case 1:
        return '2. Plan Sanitario y Reproducción';
      case 2:
        return '3. Convivencia, Higiene y Rutina';
      case 3:
        return '4. Fotos, Requisitos e Historia';
      default:
        return '';
    }
  }

  Widget _buildStepBasicInfo(AuthController auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tipo de Publicador detectado
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                auth.userRole == 'shelter'
                    ? Icons.pets
                    : Icons.home_work_outlined,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Publicando como: ${auth.roleTitle}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Especie:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('🐶 Perro'),
                selected: _species == 'dog',
                onSelected: (val) {
                  if (val) setState(() => _species = 'dog');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Text('🐱 Gato'),
                selected: _species == 'cat',
                onSelected: (val) {
                  if (val) setState(() => _species = 'cat');
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nombre de la mascota *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 16),
        TextFormField(
          controller: _breedController,
          decoration: InputDecoration(
            labelText: 'Raza aproximada (o Mestizo)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 16),
        const Text('Sexo:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Macho ♂'),
                selected: _gender == 'male',
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _gender = 'male';
                      if (_reproductiveStatus == 'spayed') {
                        _reproductiveStatus = 'neutered';
                      }
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Text('Hembra ♀'),
                selected: _gender == 'female',
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _gender = 'female';
                      if (_reproductiveStatus == 'neutered') {
                        _reproductiveStatus = 'spayed';
                      }
                    });
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Text(
          'Edad aproximada: ${_ageYears < 1 ? '${(_ageYears * 12).round()} meses' : '${_ageYears.toStringAsFixed(1)} años'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: _ageYears,
          min: 0.1,
          max: 15.0,
          divisions: 30,
          onChanged: (val) => setState(() => _ageYears = val),
        ),

        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _size,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: 'small',
              child: Text(
                'Tamaño Chico (< 10 kg)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'medium',
              child: Text(
                'Tamaño Mediano (10 - 25 kg)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'large',
              child: Text(
                'Tamaño Grande (25 - 40 kg)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'giant',
              child: Text(
                'Tamaño Gigante (> 40 kg)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: (val) => setState(() => _size = val!),
          decoration: InputDecoration(
            labelText: 'Porte / Tamaño',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _origin,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: 'home_litter',
              child: Text(
                'Nacimiento en casa (Camada propia)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'street_rescue',
              child: Text(
                'Rescatado de la calle',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'shelter_born',
              child: Text(
                'Nacido en el refugio',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'relinquished',
              child: Text(
                'Cesión por mudanza o fuerza mayor',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: (val) {
            setState(() {
              _origin = val!;
              if (_origin == 'home_litter') _isLitter = true;
            });
          },
          decoration: InputDecoration(
            labelText: 'Origen de la mascota',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        if (_isLitter || _origin == 'home_litter' || _ageYears < 0.5) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Compromiso Ético de Camada (Destete)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.brown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Por bienestar y salud inmunológica, los cachorros deben permanecer con la madre un mínimo de 60 días (8 semanas) antes de ser separados.',
                  style: TextStyle(fontSize: 12),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '¿Completó al menos 60 días de lactancia/destete?',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: _weaningCompleted,
                  onChanged: (val) => setState(() => _weaningCompleted = val),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepHealth() {
    final vaccinesList = _species == 'dog'
        ? [
            'Antirrábica',
            'Séxtuple / Óctuple',
            'Pupivac (Cachorros)',
            'Tos de las perreras',
            'Giardia',
          ]
        : ['Antirrábica', 'Triple Felina', 'Leucemia Felina (FeLV)'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado Reproductivo y Castración:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _reproductiveStatus,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: _gender == 'female' ? 'spayed' : 'neutered',
              child: Text(
                _gender == 'female'
                    ? 'Esterilizada (Cirugía realizada)'
                    : 'Castrado (Cirugía realizada)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const DropdownMenuItem(
              value: 'requires_spay_agreement',
              child: Text(
                'Cachorro: Requiere compromiso de castración a los 6 meses',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const DropdownMenuItem(
              value: 'intact',
              child: Text('Sin castrar', overflow: TextOverflow.ellipsis),
            ),
          ],
          onChanged: (val) => setState(() => _reproductiveStatus = val!),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          'Vacunas Aplicadas:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: vaccinesList.map((vac) {
            final isSelected = _selectedVaccines.contains(vac);
            return FilterChip(
              label: Text(vac),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedVaccines.add(vac);
                    _isVaccinated = true;
                  } else {
                    _selectedVaccines.remove(vac);
                    if (_selectedVaccines.isEmpty) _isVaccinated = false;
                  }
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Desparasitación interna al día'),
          subtitle: const Text('Pastilla desparasitante administrada.'),
          value: _dewormedInternal,
          onChanged: (val) => setState(() => _dewormedInternal = val),
        ),
        SwitchListTile(
          title: const Text('Desparasitación externa al día'),
          subtitle: const Text('Pipeta o pastilla contra pulgas y garrapatas.'),
          value: _dewormedExternal,
          onChanged: (val) => setState(() => _dewormedExternal = val),
        ),
        SwitchListTile(
          title: const Text('Cuenta con microchip identificatorio'),
          value: _hasMicrochip,
          onChanged: (val) => setState(() => _hasMicrochip = val),
        ),

        const SizedBox(height: 12),
        TextFormField(
          controller: _specialNeedsController,
          decoration: InputDecoration(
            labelText: 'Cuidados especiales, medicación o enfermedades crónicas (Opcional)',
            hintText: 'Ej: Alergia al pollo, requiere gotas en los ojos...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepBehavior() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(
            _species == 'cat'
                ? 'Acostumbrado a usar arenero'
                : 'Acostumbrado a hacer sus necesidades afuera',
          ),
          value: _houseTrained,
          onChanged: (val) => setState(() => _houseTrained = val),
        ),
        SwitchListTile(
          title: const Text('Sociable con otros perros'),
          value: _goodWithDogs,
          onChanged: (val) => setState(() => _goodWithDogs = val),
        ),
        SwitchListTile(
          title: const Text('Sociable con gatos'),
          value: _goodWithCats,
          onChanged: (val) => setState(() => _goodWithCats = val),
        ),
        SwitchListTile(
          title: const Text('Sociable con niños'),
          value: _goodWithKids,
          onChanged: (val) => setState(() => _goodWithKids = val),
        ),
        SwitchListTile(
          title: const Text('Requiere patio / espacio cerrado obligatorio'),
          subtitle: const Text('Marca esto si no es apto para departamento.'),
          value: _requiresYard,
          onChanged: (val) => setState(() => _requiresYard = val),
        ),

        const SizedBox(height: 16),
        Text(
          'Nivel de energía: $_energyLevel / 5',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: _energyLevel.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$_energyLevel',
          onChanged: (val) => setState(() => _energyLevel = val.round()),
        ),

        const SizedBox(height: 12),
        Text(
          'Miedo o ansiedad ante tormentas / pirotecnia: $_stormAnxiety / 5',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: _stormAnxiety.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$_stormAnxiety',
          onChanged: (val) => setState(() => _stormAnxiety = val.round()),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _selectedImage = picked;
        _photoUrlController.text = picked.path;
      });
    }
  }

  Widget _buildStepRequirements(AuthController auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _storyController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Historia de la mascota y personalidad *',
            hintText: 'Cuéntanos cómo fue rescatada o cómo nació, qué le gusta hacer...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          'Fotografía de la Mascota:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Cámara'),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Galería'),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),

        if (_selectedImage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.successGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Foto seleccionada: ${_selectedImage!.name}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 10),
        TextFormField(
          controller: _photoUrlController,
          decoration: InputDecoration(
            labelText: 'O ingresa enlace / URL directo',
            hintText: 'https://images.unsplash.com/...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          'Requisitos para el Adoptante:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Firma de contrato de adopción responsable'),
          value: _requiresContract,
          onChanged: (val) => setState(() => _requiresContract = val),
        ),
        SwitchListTile(
          title: const Text('Visita previa al domicilio del adoptante'),
          value: _requiresHomeCheck,
          onChanged: (val) => setState(() => _requiresHomeCheck = val),
        ),
        SwitchListTile(
          title: const Text('Compromiso de envío de fotos de seguimiento'),
          value: _requiresFollowupPhotos,
          onChanged: (val) => setState(() => _requiresFollowupPhotos = val),
        ),

        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _deliveryType,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: 'to_be_agreed',
              child: Text(
                'Punto de encuentro a coordinar',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'home_delivery',
              child: Text(
                'Se entrega a domicilio del adoptante',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'pickup_at_shelter',
              child: Text(
                'Se retira en el refugio / hogar de tránsito',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: (val) => setState(() => _deliveryType = val!),
          decoration: InputDecoration(
            labelText: 'Modalidad de entrega',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  void _handleNextOrSubmit() async {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor ingresa el nombre de la mascota'),
          ),
        );
        return;
      }
      if (_isLitter && !_weaningCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La camada debe cumplir al menos 60 días antes de ser entregada.',
            ),
          ),
        );
        return;
      }
      setState(() => _currentStep++);
      return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      return;
    }

    // Paso 3 (Final): Publicar
    if (_storyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa la historia de la mascota'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final swipeController = Provider.of<SwipeController>(
      context,
      listen: false,
    );
    final authController = Provider.of<AuthController>(
      context,
      listen: false,
    );
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    String? photoUrl = _photoUrlController.text.trim().isNotEmpty
        ? _photoUrlController.text.trim()
        : null;

    if (_selectedImage != null) {
      try {
        photoUrl = await _uploadSelectedImage();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('No se pudo subir la foto: $e'),
            backgroundColor: AppTheme.rejectRed,
          ),
        );
        return;
      }
    }

    photoUrl ??= _species == 'cat'
        ? 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=800&q=80'
        : 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=800&q=80';

    final payload = {
      'name': _nameController.text.trim(),
      'species': _species,
      'breed': _breedController.text.trim(),
      'age_years': _ageYears,
      'gender': _gender,
      'size': _size,
      'energy_level': _energyLevel,
      'origin': _origin,
      'is_litter': _isLitter,
      'weaning_completed': _weaningCompleted,
      'is_vaccinated': _isVaccinated,
      'vaccines_applied': _selectedVaccines.toList(),
      'dewormed_internal': _dewormedInternal,
      'dewormed_external': _dewormedExternal,
      'has_microchip': _hasMicrochip,
      'is_neutered':
          _reproductiveStatus == 'spayed' || _reproductiveStatus == 'neutered',
      'reproductive_status': _reproductiveStatus,
      'house_trained': _houseTrained,
      'good_with_dogs': _goodWithDogs,
      'good_with_cats': _goodWithCats,
      'good_with_kids': _goodWithKids,
      'requires_yard': _requiresYard,
      'storm_anxiety': _stormAnxiety,
      'special_needs': _specialNeedsController.text.trim().isEmpty
          ? null
          : _specialNeedsController.text.trim(),
      'story': _storyController.text.trim(),
      'requires_adoption_contract': _requiresContract,
      'requires_home_check': _requiresHomeCheck,
      'requires_followup_photos': _requiresFollowupPhotos,
      'delivery_type': _deliveryType,
      'photos': [photoUrl],
      if (authController.profile?.latitude != null)
        'latitude': authController.profile!.latitude,
      if (authController.profile?.longitude != null)
        'longitude': authController.profile!.longitude,
    };

    final newPet = await swipeController.publishPet(payload);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (newPet == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            swipeController.errorMessage ?? 'No se pudo publicar la mascota',
          ),
          backgroundColor: AppTheme.rejectRed,
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '¡${newPet.name} ha sido publicado/a exitosamente en PetMatch!',
        ),
        backgroundColor: AppTheme.successGreen,
      ),
    );

    navigator.pop();
  }

  Future<String> _uploadSelectedImage() async {
    final image = _selectedImage!;
    final bytes = await image.readAsBytes();
    final extension = image.name.contains('.')
        ? image.name.split('.').last
        : 'jpg';
    final path =
        '${DateTime.now().millisecondsSinceEpoch}_${image.name.hashCode}.$extension';

    final storage = Supabase.instance.client.storage.from('pet-photos');
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    return storage.getPublicUrl(path);
  }
}
