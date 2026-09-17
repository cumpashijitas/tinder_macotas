import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../admin/admin_main_screen.dart';
import '../dashboard/adopter_main_screen.dart';
import '../dashboard/shelter_main_screen.dart';
import 'login_screen.dart';

/// Decide qué pantalla mostrar según el estado real de la sesión de Supabase Auth.
/// Reemplaza cualquier acceso "demo": sin sesión válida no hay forma de entrar.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        if (auth.profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        switch (auth.profile!.role) {
          case 'admin':
            return const AdminMainScreen();
          case 'adopter':
            return const AdopterMainScreen();
          default:
            return const ShelterMainScreen();
        }
      },
    );
  }
}
