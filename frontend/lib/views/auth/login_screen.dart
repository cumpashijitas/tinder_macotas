import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo e isotipo
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 56,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'PetMatch',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Adopción responsable estilo Tinder.\nConectando adoptantes, refugios y camadas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 28),

                // Selector de Tipo de Cuenta / Rol
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selecciona tu perfil en la plataforma:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildRoleCard(
                      label: 'Adoptante',
                      subtitle: 'Busco mascota',
                      icon: Icons.favorite,
                      role: 'adopter',
                      selectedRole: authController.userRole,
                      onTap: () => authController.setRole('adopter'),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleCard(
                      label: 'Refugio / ONG',
                      subtitle: 'Albergue oficial',
                      icon: Icons.shield,
                      role: 'shelter',
                      selectedRole: authController.userRole,
                      onTap: () => authController.setRole('shelter'),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleCard(
                      label: 'Camada / Crías',
                      subtitle: 'Particular',
                      icon: Icons.volunteer_activism,
                      role: 'individual_rescuer',
                      selectedRole: authController.userRole,
                      onTap: () => authController.setRole('individual_rescuer'),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                if (!_codeSent) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: authController.isLoading
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await authController
                                  .signInWithGoogle();
                              if (!ok && mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      authController.errorMessage ??
                                          'No se pudo iniciar sesión con Google.',
                                    ),
                                  ),
                                );
                              }
                              // En éxito, la página redirige a Google y vuelve;
                              // AuthGate se encarga de mostrar el dashboard al volver.
                            },
                      icon: const Icon(Icons.g_mobiledata, size: 28, color: AppTheme.primaryColor),
                      label: const Text('Continuar con Google'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'o con tu correo',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Paso 1: Ingreso de correo
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      hintText: 'ejemplo@correo.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authController.isLoading
                          ? null
                          : () async {
                              final email = _emailController.text.trim();
                              final messenger = ScaffoldMessenger.of(context);
                              if (email.isEmpty || !email.contains('@')) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ingresa un correo electrónico válido',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final ok = await authController.sendOtp(email);
                              if (!mounted) return;
                              if (ok) {
                                setState(() => _codeSent = true);
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      authController.errorMessage ??
                                          'No se pudo enviar el código. Intenta nuevamente.',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: authController.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Enviar Código de Verificación'),
                    ),
                  ),
                ] else ...[
                  // Paso 2: Verificación de código OTP
                  Text(
                    'Ingresa el código de 6 dígitos enviado a ${_emailController.text}:',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8),
                    decoration: InputDecoration(
                      hintText: '000000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authController.isLoading
                          ? null
                          : () async {
                              final code = _otpController.text.trim();
                              final messenger = ScaffoldMessenger.of(context);
                              if (code.length != 6) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'El código debe tener 6 dígitos',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final email = _emailController.text.trim();
                              final ok = await authController.verifyOtp(
                                email,
                                code,
                              );
                              if (!mounted) return;
                              if (!ok) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      authController.errorMessage ??
                                          'Código inválido o expirado',
                                    ),
                                  ),
                                );
                              }
                              // Si fue exitoso, AuthGate redirige automáticamente al dashboard correspondiente.
                            },
                      child: authController.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Verificar e Ingresar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _codeSent = false),
                    child: const Text('Cambiar correo electrónico'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required String role,
    required String selectedRole,
    required VoidCallback onTap,
  }) {
    final isSelected = role == selectedRole;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textDark,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
