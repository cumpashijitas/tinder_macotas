import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/controllers/notifications_controller.dart';
import '../helpers/mock_api_service.dart';

Map<String, dynamic> _notifJson(String id, {bool isRead = false}) => {
      'id': id,
      'type': 'new_message',
      'title': 'Nuevo mensaje',
      'body': 'Hola',
      'related_id': 'match-1',
      'is_read': isRead,
      'created_at': '2026-01-01T00:00:00.000Z',
    };

void main() {
  setUpAll(registerApiServiceFallbacks);

  late MockHttpClient client;
  late NotificationsController controller;

  setUp(() {
    client = MockHttpClient();
    controller = NotificationsController(apiService: buildApiService(client));
  });

  test('load puebla notificaciones y el conteo de no leídas', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => jsonResponse({
        'notifications': [_notifJson('n1'), _notifJson('n2', isRead: true)],
        'unreadCount': 1,
      }),
    );

    await controller.load();

    expect(controller.notifications.length, 2);
    expect(controller.unreadCount, 1);
  });

  test('load guarda hasMore según lo que informa el backend', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => jsonResponse({
        'notifications': [_notifJson('n1')],
        'unreadCount': 0,
        'hasMore': true,
      }),
    );

    await controller.load();

    expect(controller.hasMore, isTrue);
  });

  test('loadMore pide el siguiente offset y agrega notificaciones al final', () async {
    when(() => client.get(
          any(that: predicate<Uri>((u) => !u.toString().contains('offset'))),
          headers: any(named: 'headers'),
        )).thenAnswer(
      (_) async => jsonResponse({
        'notifications': [_notifJson('n1')],
        'unreadCount': 0,
        'hasMore': true,
      }),
    );
    await controller.load();

    when(() => client.get(
          any(that: predicate<Uri>((u) => u.toString().contains('offset=1'))),
          headers: any(named: 'headers'),
        )).thenAnswer(
      (_) async => jsonResponse({
        'notifications': [_notifJson('n2')],
        'unreadCount': 0,
        'hasMore': false,
      }),
    );

    await controller.loadMore();

    expect(controller.notifications.map((n) => n.id), ['n1', 'n2']);
    expect(controller.hasMore, isFalse);
  });

  test('loadMore no hace nada si hasMore es false', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => jsonResponse({
        'notifications': [_notifJson('n1')],
        'unreadCount': 0,
        'hasMore': false,
      }),
    );
    await controller.load();

    await controller.loadMore();

    verify(() => client.get(any(), headers: any(named: 'headers'))).called(1);
  });

  test('markRead marca localmente y descuenta el contador', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => jsonResponse({
        'notifications': [_notifJson('n1')],
        'unreadCount': 1,
      }),
    );
    await controller.load();

    when(() => client.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => jsonResponse(null));

    await controller.markRead('n1');

    expect(controller.notifications.single.isRead, isTrue);
    expect(controller.unreadCount, 0);
  });

  test('markAllRead marca todas localmente y resetea el contador', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => jsonResponse({
        'notifications': [_notifJson('n1'), _notifJson('n2')],
        'unreadCount': 2,
      }),
    );
    await controller.load();

    when(() => client.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => jsonResponse(null));

    await controller.markAllRead();

    expect(controller.notifications.every((n) => n.isRead), isTrue);
    expect(controller.unreadCount, 0);
  });
}
