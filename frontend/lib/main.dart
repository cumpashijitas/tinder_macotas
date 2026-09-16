import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/swipe_controller.dart';
import 'controllers/pet_filter_controller.dart';
import 'views/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PetMatchApp());
}

class PetMatchApp extends StatelessWidget {
  const PetMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => SwipeController()),
        ChangeNotifierProvider(create: (_) => PetFilterController()),
      ],
      child: MaterialApp(
        title: 'PetMatch - Tinder de Adopción',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
