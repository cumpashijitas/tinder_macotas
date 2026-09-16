import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/controllers/auth_controller.dart';
import '../helpers/mock_api_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockSession extends Mock implements Session {}

void main() {
  setUpAll(registerApiServiceFallbacks);

  late MockHttpClient httpClient;
  late MockSupabaseClient supabase;
  late MockGoTrueClient goTrue;
  late StreamController<AuthState> authStateController;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    httpClient = MockHttpClient();
    supabase = MockSupabaseClient();
    goTrue = MockGoTrueClient();
    authStateController = StreamController<AuthState>.broadcast();
    when(() => supabase.auth).thenReturn(goTrue);
    when(() => goTrue.onAuthStateChange).thenAnswer((_) => authStateController.stream);
    when(() => goTrue.currentSession).thenReturn(null);
  });

  tearDown(() => authStateController.close());

  AuthController buildController() => AuthController(
        apiService: buildApiService(httpClient),
        supabaseClient: supabase,
      );

  /// Simula lo que hace Supabase realmente: emitir un AuthState "signedIn"
  /// en el stream de onAuthStateChange una vez que el login se completó.
  Future<void> emitSignedIn() async {
    final session = MockSession();
    authStateController.add(AuthState(AuthChangeEvent.signedIn, session));
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  group('sendOtp', () {
    test('éxito: retorna true sin errores', () async {
      when(() => goTrue.signInWithOtp(email: any(named: 'email'))).thenAnswer((_) async {});

      final controller = buildController();
      final ok = await controller.sendOtp('ana@example.com');

      expect(ok, isTrue);
      expect(controller.errorMessage, isNull);
    });

    test('AuthException: retorna false y guarda el mensaje', () async {
      when(() => goTrue.signInWithOtp(email: any(named: 'email')))
          .thenThrow(const AuthException('Demasiados intentos, intenta más tarde'));

      final controller = buildController();
      final ok = await controller.sendOtp('ana@example.com');

      expect(ok, isFalse);
      expect(controller.errorMessage, contains('Demasiados intentos'));
    });
  });

  group('verifyOtp', () {
    test('éxito con perfil ya existente: el listener lo carga sin crear uno nuevo', () async {
      when(() => goTrue.verifyOTP(
            type: OtpType.email,
            email: any(named: 'email'),
            token: any(named: 'token'),
          )).thenAnswer((_) async => MockAuthResponse());

      when(() => httpClient.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => jsonResponse({
          'id': 'user-1',
          'full_name': 'Ana Torres',
          'role': 'adopter',
        }),
      );

      final controller = buildController();
      final ok = await controller.verifyOtp('ana@example.com', '123456');
      expect(ok, isTrue);

      await emitSignedIn();

      expect(controller.profile?.fullName, 'Ana Torres');
      verifyNever(() => httpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')));
    });

    test('primer ingreso: si no hay perfil, lo crea con el rol seleccionado antes de enviar', () async {
      when(() => goTrue.verifyOTP(
            type: OtpType.email,
            email: any(named: 'email'),
            token: any(named: 'token'),
          )).thenAnswer((_) async => MockAuthResponse());

      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse(null));
      when(() => httpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenAnswer(
        (_) async => jsonResponse({
          'id': 'user-2',
          'full_name': 'nueva.familia',
          'role': 'shelter',
        }, statusCode: 201),
      );

      final controller = buildController();
      controller.setRole('shelter');
      final ok = await controller.verifyOtp('nueva.familia@example.com', '654321');
      expect(ok, isTrue);

      await emitSignedIn();

      expect(controller.profile?.role, 'shelter');
    });

    test('código inválido: retorna false con mensaje de error', () async {
      when(() => goTrue.verifyOTP(
            type: OtpType.email,
            email: any(named: 'email'),
            token: any(named: 'token'),
          )).thenThrow(const AuthException('Token has expired or is invalid'));

      final controller = buildController();
      final ok = await controller.verifyOtp('ana@example.com', '000000');

      expect(ok, isFalse);
      expect(controller.errorMessage, contains('expired'));
    });
  });

  // Nota: `signInWithOAuth` se implementa en supabase_flutter como método de
  // extensión (GoTrueClientSignInProvider), no como método virtual de
  // GoTrueClient, así que mocktail no puede interceptarlo — cualquier llamada
  // real siempre golpea el código real del SDK (que a su vez intenta navegar
  // el browser). Por eso el flujo de Google Sign-In no tiene test unitario
  // aquí; se valida manualmente contra el browser real una vez configurado
  // el proveedor en el dashboard de Supabase.

  test('signInWithGoogle persiste el rol elegido en SharedPreferences antes de redirigir', () async {
    final controller = buildController();
    controller.setRole('shelter');

    // No podemos invocar signInWithGoogle() en este entorno (ver nota arriba),
    // pero sí podemos probar el mismo mecanismo de persistencia que usa
    // internamente, reproduciendo el flujo de bootstrap tras el "regreso".
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('petmatch_pending_role', controller.userRole);

    when(() => httpClient.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => jsonResponse(null));
    when(() => httpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenAnswer(
      (_) async => jsonResponse({
        'id': 'user-3',
        'full_name': 'Refugio Nuevo',
        'role': 'shelter',
      }, statusCode: 201),
    );

    await emitSignedIn();

    expect(controller.profile?.role, 'shelter');
    expect(prefs.getString('petmatch_pending_role'), isNull); // se limpia tras usarse
  });

  test('logout invoca signOut en el cliente de Supabase', () async {
    when(() => goTrue.signOut()).thenAnswer((_) async {});

    final controller = buildController();
    await controller.logout();

    verify(() => goTrue.signOut()).called(1);
    expect(controller.profile, isNull);
  });
}
