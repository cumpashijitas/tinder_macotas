import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:frontend/controllers/matches_controller.dart';
import 'package:frontend/views/matches/matches_screen.dart';
import '../helpers/mock_api_service.dart';
import '../helpers/network_image_mock.dart';

Map<String, dynamic> _matchJson(String id, String status) => {
      'id': id,
      'pet_id': 'pet-1',
      'adopter_id': 'adopter-1',
      'shelter_id': 'shelter-1',
      'status': status,
      'created_at': '2026-01-01T00:00:00.000Z',
      'pets': {
        'id': 'pet-1',
        'name': 'Rocky',
        'breed': 'Mestizo',
        'age_years': 2.0,
        'photos': <String>[],
        'status': 'available',
      },
    };

Widget _wrap(MatchesController controller) {
  return ChangeNotifierProvider<MatchesController>.value(
    value: controller,
    child: const MaterialApp(home: MatchesScreen()),
  );
}

void main() {
  setUpAll(registerApiServiceFallbacks);

  setUp(() => HttpOverrides.global = NetworkImageMockHttpOverrides());
  tearDown(() => HttpOverrides.global = null);

  testWidgets('muestra el estado vacío cuando no hay matches', (tester) async {
    final client = MockHttpClient();
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer((_) async => jsonResponse([]));
    final controller = MatchesController(apiService: buildApiService(client));

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aún no tienes matches'), findsOneWidget);
  });

  testWidgets('muestra un match aprobado con botón de Chat', (tester) async {
    final client = MockHttpClient();
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => jsonResponse([_matchJson('m1', 'approved_for_chat')]));
    final controller = MatchesController(apiService: buildApiService(client));

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.text('Rocky'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
  });

  testWidgets('un match pendiente no muestra botón de Chat', (tester) async {
    final client = MockHttpClient();
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => jsonResponse([_matchJson('m1', 'pending_review')]));
    final controller = MatchesController(apiService: buildApiService(client));

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.text('Rocky'), findsOneWidget);
    expect(find.text('Chat'), findsNothing);
  });
}
