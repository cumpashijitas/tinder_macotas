import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/main.dart';
import 'package:frontend/controllers/auth_controller.dart';
import 'helpers/mock_api_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  testWidgets('Sin sesión activa, la app muestra la pantalla de login (sin acceso demo)', (tester) async {
    final supabase = MockSupabaseClient();
    final goTrue = MockGoTrueClient();
    when(() => supabase.auth).thenReturn(goTrue);
    when(() => goTrue.onAuthStateChange).thenAnswer((_) => const Stream.empty());
    when(() => goTrue.currentSession).thenReturn(null);

    final authController = AuthController(
      apiService: buildApiService(MockHttpClient()),
      supabaseClient: supabase,
    );

    await tester.pumpWidget(PetMatchApp(authController: authController));

    expect(find.text('PetMatch'), findsWidgets);
    expect(find.text('Enviar Código de Verificación'), findsOneWidget);
    expect(find.textContaining('Demo'), findsNothing);
  });
}
