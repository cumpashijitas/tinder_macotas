import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/controllers/adopter_form_controller.dart';
import '../helpers/mock_api_service.dart';

void main() {
  setUpAll(registerApiServiceFallbacks);

  late MockHttpClient client;
  late AdopterFormController controller;

  setUp(() {
    client = MockHttpClient();
    controller = AdopterFormController(apiService: buildApiService(client));
  });

  group('AdopterFormController.submitForm', () {
    test('rechaza localmente sin llamar a la red si no todos están de acuerdo', () async {
      controller.updateHousehold(members: 'family_with_young_kids', allAgree: false, hasAllergies: false);

      final ok = await controller.submitForm();

      expect(ok, isFalse);
      expect(controller.errorMessage, isNotNull);
      verifyNever(() => client.post(any(), headers: any(named: 'headers'), body: any(named: 'body')));
    });

    test('en éxito actualiza el formulario con la respuesta del servidor y marca completado', () async {
      when(() => client.post(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenAnswer(
        (_) async => jsonResponse({
          'housing_type': 'house',
          'housing_status': 'owned',
          'has_yard': true,
          'has_protective_netting': false,
          'household_members': 'couple',
          'all_members_agree': true,
          'has_allergies': false,
          'hours_pet_alone_per_day': 4,
          'has_other_pets': false,
          'monthly_budget_confirmed': true,
          'emergency_fund_available': true,
          'agrees_to_follow_up': true,
          'agrees_to_mandatory_neutering': true,
          'evaluation_status': 'approved',
          'evaluation_score': 90,
        }),
      );

      final ok = await controller.submitForm();

      expect(ok, isTrue);
      expect(controller.isCompleted, isTrue);
      expect(controller.form.evaluationStatus, 'approved');
      expect(controller.form.evaluationScore, 90);
    });

    test('propaga el error del backend cuando la validación falla (422)', () async {
      when(() => client.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => errorResponse('Faltan campos obligatorios', statusCode: 422));

      final ok = await controller.submitForm();

      expect(ok, isFalse);
      expect(controller.errorMessage, contains('Faltan campos obligatorios'));
      expect(controller.isCompleted, isFalse);
    });
  });

  group('AdopterFormController.loadExistingForm', () {
    test('carga un formulario previo y lo marca como completado', () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => jsonResponse({
          'housing_type': 'apartment',
          'housing_status': 'rented_allowed',
          'has_yard': false,
          'has_protective_netting': true,
          'household_members': 'alone',
          'all_members_agree': true,
          'has_allergies': false,
          'hours_pet_alone_per_day': 6,
          'has_other_pets': false,
          'monthly_budget_confirmed': true,
          'emergency_fund_available': true,
          'agrees_to_follow_up': true,
          'agrees_to_mandatory_neutering': true,
        }),
      );

      await controller.loadExistingForm();

      expect(controller.isCompleted, isTrue);
      expect(controller.form.housingType, 'apartment');
    });

    test('cuando no hay formulario (data null) no marca como completado', () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer((_) async => jsonResponse(null));

      await controller.loadExistingForm();

      expect(controller.isCompleted, isFalse);
    });
  });
}
