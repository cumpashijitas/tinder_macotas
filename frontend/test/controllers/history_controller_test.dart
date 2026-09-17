import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/controllers/history_controller.dart';
import '../helpers/mock_api_service.dart';

Matcher _uriPathContains(String fragment) =>
    predicate<Uri>((uri) => uri.toString().contains(fragment), 'URL contiene "$fragment"');

void main() {
  setUpAll(registerApiServiceFallbacks);

  late MockHttpClient client;
  late HistoryController controller;

  setUp(() {
    client = MockHttpClient();
    controller = HistoryController(apiService: buildApiService(client));
  });

  test('load trae contratos y visitas en paralelo y los parsea con el pet embebido', () async {
    when(() => client.get(any(that: _uriPathContains('/contracts')), headers: any(named: 'headers'))).thenAnswer(
      (_) async => jsonResponse([
        {
          'id': 'c1',
          'match_id': 'm1',
          'signed_by_adopter': true,
          'signed_by_shelter': false,
          'created_at': '2026-01-01T00:00:00.000Z',
          'matches': {
            'status': 'interview_scheduled',
            'pets': {'name': 'Rocky', 'photos': ['https://example.com/rocky.jpg']},
          },
        },
      ]),
    );

    when(() => client.get(any(that: _uriPathContains('/visits')), headers: any(named: 'headers'))).thenAnswer(
      (_) async => jsonResponse([
        {
          'id': 'v1',
          'match_id': 'm1',
          'status': 'confirmed',
          'proposed_at': '2026-02-01T15:00:00.000Z',
          'notes': 'Visita al refugio',
          'matches': {
            'pets': {'name': 'Rocky', 'photos': ['https://example.com/rocky.jpg']},
          },
        },
      ]),
    );

    await controller.load();

    expect(controller.contracts.length, 1);
    expect(controller.contracts.first.petName, 'Rocky');
    expect(controller.contracts.first.fullySigned, isFalse);

    expect(controller.visits.length, 1);
    expect(controller.visits.first.petName, 'Rocky');
    expect(controller.visits.first.statusLabel, 'Confirmada');
  });

  test('guarda el error si alguna de las dos llamadas falla', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => errorResponse('Token inválido', statusCode: 401));

    await controller.load();

    expect(controller.errorMessage, contains('Token inválido'));
  });
}
