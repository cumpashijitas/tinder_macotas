import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/swipe_controller.dart';
import 'controllers/pet_filter_controller.dart';
import 'controllers/adopter_form_controller.dart';
import 'controllers/matches_controller.dart';
import 'controllers/notifications_controller.dart';
import 'controllers/history_controller.dart';
import 'views/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );
  runApp(const PetMatchApp());
}

final supabase = Supabase.instance.client;

/// [PetMatchApp] acepta controllers ya construidos para poder inyectar fakes
/// en tests (evita depender de Supabase.instance en flutter_test).
class PetMatchApp extends StatelessWidget {
  final AuthController? authController;
  final SwipeController? swipeController;
  final PetFilterController? petFilterController;
  final AdopterFormController? adopterFormController;
  final MatchesController? matchesController;
  final NotificationsController? notificationsController;
  final HistoryController? historyController;

  const PetMatchApp({
    super.key,
    this.authController,
    this.swipeController,
    this.petFilterController,
    this.adopterFormController,
    this.matchesController,
    this.notificationsController,
    this.historyController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authController ?? AuthController()),
        ChangeNotifierProvider(create: (_) => swipeController ?? SwipeController()),
        ChangeNotifierProvider(create: (_) => petFilterController ?? PetFilterController()),
        ChangeNotifierProvider(create: (_) => adopterFormController ?? AdopterFormController()),
        ChangeNotifierProvider(create: (_) => matchesController ?? MatchesController()),
        ChangeNotifierProvider(
          create: (_) => notificationsController ?? NotificationsController(),
        ),
        ChangeNotifierProvider(create: (_) => historyController ?? HistoryController()),
      ],
      child: MaterialApp(
        title: 'PetMatch - Tinder de Adopción',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}
