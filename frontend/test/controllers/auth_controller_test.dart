import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/controllers/auth_controller.dart';
import '../helpers/mock_api_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  setUpAll(registerApiServiceFallbacks);

  late MockHttpClient httpClient;
  late MockSupabaseClient supabase;
  late MockGoTrueClient goTrue;

  setUp(() {
    httpClient = MockHttpClient();
    supabase = MockSupabaseClient();
    goTrue = MockGoTrueClient();
    when(() => supabase.auth).thenReturn(goTrue);
    when(() => goTrue.onAuthStateChange).thenAnswer((_) => const Stream.empty());
    when(() => goTrue.currentSession).thenReturn(null);
  });

  AuthController buildController() => AuthController(
        apiService: buildApiService(httpClient),
        supabaseClient: supabase,
      );

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
    test('éxito con perfil ya existente: lo carga y no crea uno nuevo', () async {
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
      expect(controller.profile?.fullName, 'Ana Torres');
      verifyNever(() => httpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')));
    });

    test('primer ingreso: si no hay perfil, lo crea con el rol seleccionado', () async {
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

  test('logout invoca signOut en el cliente de Supabase', () async {
    when(() => goTrue.signOut()).thenAnswer((_) async {});

    final controller = buildController();
    await controller.logout();

    verify(() => goTrue.signOut()).called(1);
    expect(controller.profile, isNull);
  });
}
