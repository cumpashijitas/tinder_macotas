import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';

/// Diálogo de edición de perfil, reutilizado por adoptantes y refugios.
/// Actualiza el perfil real vía AuthController.updateProfile (respaldado por
/// el backend), no hay campos de sólo lectura simulados.
class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(context: context, builder: (_) => const EditProfileDialog());
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _organizationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AuthController>(context, listen: false).profile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');
    _organizationController = TextEditingController(text: profile?.organizationName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_nameController.text.trim().length < 2) {
      messenger.showSnackBar(const SnackBar(content: Text('Ingresá un nombre válido')));
      return;
    }

    setState(() => _isSaving = true);

    final ok = await auth.updateProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      organizationName:
          _organizationController.text.trim().isEmpty ? null : _organizationController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente'), backgroundColor: AppTheme.successGreen),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'No se pudo actualizar el perfil')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context, listen: false);
    final isOrganization = auth.userRole == 'shelter' || auth.userRole == 'individual_rescuer';

    return AlertDialog(
      title: const Text('Editar Perfil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            const SizedBox(height: 12),
            if (isOrganization) ...[
              TextField(
                controller: _organizationController,
                decoration: const InputDecoration(labelText: 'Nombre de la organización'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
