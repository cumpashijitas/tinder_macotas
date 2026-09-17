import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:frontend/controllers/notifications_controller.dart';
import 'package:frontend/views/notifications/notifications_screen.dart';
import '../helpers/mock_api_service.dart';

Widget _wrap(NotificationsController controller) {
  return ChangeNotifierProvider<NotificationsController>.value(
    value: controller,
    child: const MaterialApp(home: NotificationsScreen()),
  );
}

void main() {
  setUpAll(registerApiServiceFallbacks);

  testWidgets('muestra el estado vacío cuando no hay notificaciones', (tester) async {
    final client = MockHttpClient();
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => jsonResponse({'notifications': [], 'unreadCount': 0}));
    final controller = NotificationsController(apiService: buildApiService(client));

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.textContaining('No tenés notificaciones'), findsOneWidget);
  });

  testWidgets('lista notificaciones y muestra "Marcar todas" cuando hay no leídas', (tester) async {
    final client = MockHttpClient();
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => jsonResponse({
        'notifications': [
          {
            'id': 'n1',
            'type': 'new_message',
            'title': 'Nuevo mensaje',
            'body': 'Hola!',
            'related_id': 'm1',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          },
        ],
        'unreadCount': 1,
      }),
    );
    final controller = NotificationsController(apiService: buildApiService(client));

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo mensaje'), findsOneWidget);
    expect(find.text('Marcar todas'), findsOneWidget);
  });

  testWidgets('tocar una notificación la marca como leída', (tester) async {
    final client = MockHttpClient();
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => jsonResponse({
        'notifications': [
          {
            'id': 'n1',
            'type': 'new_message',
            'title': 'Nuevo mensaje',
            'body': 'Hola!',
            'related_id': 'm1',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          },
        ],
        'unreadCount': 1,
      }),
    );
    when(() => client.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => jsonResponse(null));

    final controller = NotificationsController(apiService: buildApiService(client));

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo mensaje'));
    await tester.pumpAndSettle();

    expect(controller.unreadCount, 0);
    verify(() => client.patch(any(), headers: any(named: 'headers'), body: any(named: 'body'))).called(1);
  });
}
