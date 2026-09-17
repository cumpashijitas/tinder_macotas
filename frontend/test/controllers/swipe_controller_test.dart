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

  group('updatePet', () {
    test('reemplaza la mascota en el inventario con la respuesta del servidor', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse([_samplePetJson().toJson()]));
      await controller.loadInventory();

      final updatedJson = _samplePetJson().toJson()..['name'] = 'Rocky Editado';
      when(() => client.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => jsonResponse(updatedJson));

      final updated = await controller.updatePet('pet-1', {'name': 'Rocky Editado'});

      expect(updated?.name, 'Rocky Editado');
      expect(controller.inventory.single.name, 'Rocky Editado');
    });

    test('devuelve null y guarda el error si el backend rechaza', () async {
      when(() => client.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => errorResponse('No autorizado', statusCode: 403));

      final updated = await controller.updatePet('pet-1', {'name': 'X'});

      expect(updated, isNull);
      expect(controller.errorMessage, contains('No autorizado'));
    });
  });

  group('deletePet', () {
    test('quita la mascota del inventario en éxito', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse([_samplePetJson().toJson()]));
      await controller.loadInventory();

      when(() => client.delete(any(), headers: any(named: 'headers'))).thenAnswer((_) async => jsonResponse(null));

      final ok = await controller.deletePet('pet-1');

      expect(ok, isTrue);
      expect(controller.inventory, isEmpty);
    });

    test('mantiene la mascota si el backend rechaza (409, ya tiene matches)', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse([_samplePetJson().toJson()]));
      await controller.loadInventory();

      when(() => client.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => errorResponse('Ya tiene postulaciones', statusCode: 409));

      final ok = await controller.deletePet('pet-1');

      expect(ok, isFalse);
      expect(controller.inventory.length, 1);
      expect(controller.errorMessage, contains('Ya tiene postulaciones'));
    });
  });

  group('moderación (admin)', () {
    test('loadPendingModeration puebla la cola de pendientes', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse([_samplePetJson().toJson()]));

      await controller.loadPendingModeration();

      expect(controller.pendingModeration.length, 1);
    });

    test('moderatePet quita la mascota de la cola al aprobar/rechazar', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse([_samplePetJson().toJson()]));
      await controller.loadPendingModeration();

      when(() => client.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => jsonResponse(null));

      final ok = await controller.moderatePet('pet-1', 'approved');

      expect(ok, isTrue);
      expect(controller.pendingModeration, isEmpty);
    });
  });
}
