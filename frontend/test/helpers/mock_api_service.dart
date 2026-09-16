import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:frontend/core/services/api_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void registerApiServiceFallbacks() {
  registerFallbackValue(FakeUri());
}

/// Construye una respuesta con el mismo sobre {success, message, data} que usa el backend.
http.Response jsonResponse(dynamic data, {bool success = true, String? message, int statusCode = 200}) {
  return http.Response(
    jsonEncode({'success': success, 'message': message, 'data': data}),
    statusCode,
  );
}

http.Response errorResponse(String message, {int statusCode = 400}) {
  return http.Response(
    jsonEncode({'success': false, 'message': message}),
    statusCode,
  );
}

ApiService buildApiService(MockHttpClient client) {
  return ApiService(client: client, tokenProvider: () => 'fake-token');
}
