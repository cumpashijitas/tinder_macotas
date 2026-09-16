import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/controllers/matches_controller.dart';
import '../helpers/mock_api_service.dart';

Map<String, dynamic> _matchJson(String id, String status) => {
      'id': id,
      'pet_id': 'pet-1',
      'adopter_id': 'adopter-1',
      'shelter_id': 'shelter-1',
      'status': status,
      'created_at': '2026-01-01T00:00:00.000Z',
      'pets': {'id': 'pet-1', 'name': 'Rocky', 'photos': <String>[], 'status': 'available'},
    };

void main() {
  setUpAll(registerApiServiceFallbacks);

  late MockHttpClient client;
  late MatchesController controller;

  setUp(() {
    client = MockHttpClient();
    controller = MatchesController(apiService: buildApiService(client));
  });

  test('loadMatches puebla la lista de matches', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => jsonResponse([_matchJson('m1', 'approved_for_chat')]));

    await controller.loadMatches();

    expect(controller.matches.length, 1);
    expect(controller.matches.first.isChatEnabled, isTrue);
  });

  test('updateStatus reemplaza el match actualizado en la lista', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => jsonResponse([_matchJson('m1', 'pending_review')]));
    await controller.loadMatches();

    when(() => client.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => jsonResponse(_matchJson('m1', 'approved_for_chat')));

    final ok = await controller.updateStatus('m1', 'approved_for_chat');

    expect(ok, isTrue);
    expect(controller.matches.single.status, 'approved_for_chat');
  });

  test('updateStatus devuelve false y guarda el error si el backend rechaza', () async {
    when(() => client.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => errorResponse('Solo los refugios pueden actualizar', statusCode: 403));

    final ok = await controller.updateStatus('m1', 'approved_for_chat');

    expect(ok, isFalse);
    expect(controller.errorMessage, contains('Solo los refugios'));
  });
}
