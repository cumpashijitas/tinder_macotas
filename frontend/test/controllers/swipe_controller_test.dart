import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/controllers/swipe_controller.dart';
import 'package:frontend/models/pet_model.dart';
import '../helpers/mock_api_service.dart';

PetModel _samplePetJson() => PetModel.fromJson({
      'id': 'pet-1',
      'shelter_id': 'shelter-1',
      'publisher_type': 'shelter',
      'name': 'Rocky',
      'species': 'dog',
      'breed': 'Mestizo',
      'age_years': 2.0,
      'gender': 'male',
      'size': 'medium',
      'energy_level': 3,
      'is_vaccinated': true,
      'is_neutered': true,
      'good_with_dogs': true,
      'good_with_cats': true,
      'good_with_kids': true,
      'requires_yard': false,
      'story': 'Buen perro',
      'photos': <String>[],
      'status': 'available',
    });

void main() {
  setUpAll(registerApiServiceFallbacks);

  late MockHttpClient client;
  late SwipeController controller;

  setUp(() {
    client = MockHttpClient();
    controller = SwipeController(apiService: buildApiService(client));
  });

  test('loadFeed puebla pets con la respuesta del backend', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => jsonResponse([_samplePetJson().toJson()]));

    await controller.loadFeed();

    expect(controller.pets.length, 1);
    expect(controller.pets.first.name, 'Rocky');
    expect(controller.isLoading, isFalse);
  });

  test('loadFeed vacía la lista y guarda el error si falla la red', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => errorResponse('Token inválido', statusCode: 401));

    await controller.loadFeed();

    expect(controller.pets, isEmpty);
    expect(controller.errorMessage, contains('Token inválido'));
  });

  test('publishPet agrega la mascota creada al inventario', () async {
    when(() => client.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => jsonResponse(_samplePetJson().toJson(), statusCode: 201));

    final pet = await controller.publishPet({'name': 'Rocky'});

    expect(pet, isNotNull);
    expect(controller.inventory.length, 1);
    expect(controller.inventory.first.name, 'Rocky');
  });

  test('publishPet devuelve null y guarda el error si el backend rechaza', () async {
    when(() => client.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => errorResponse('Solo refugios pueden publicar', statusCode: 403));

    final pet = await controller.publishPet({'name': 'Rocky'});

    expect(pet, isNull);
    expect(controller.inventory, isEmpty);
    expect(controller.errorMessage, contains('Solo refugios'));
  });

  test('applyToAdopt devuelve true cuando el backend crea un match', () async {
    when(() => client.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => jsonResponse({'matchCreated': true}));

    final matched = await controller.applyToAdopt(_samplePetJson());

    expect(matched, isTrue);
    expect(controller.lastSwipeFeedback, isNotNull);
  });

  test('applyToAdopt devuelve false cuando no se crea match', () async {
    when(() => client.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => jsonResponse({'matchCreated': false}));

    final matched = await controller.applyToAdopt(_samplePetJson());

    expect(matched, isFalse);
  });

  test('updatePetStatus actualiza el status local en éxito', () async {
    when(() => client.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => jsonResponse(null));

    final pet = _samplePetJson();
    final ok = await controller.updatePetStatus(pet, 'paused');

    expect(ok, isTrue);
    expect(pet.status, 'paused');
  });
}
