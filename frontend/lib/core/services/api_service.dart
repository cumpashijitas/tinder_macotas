import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

/// Cliente HTTP hacia el backend Express de PetMatch.
/// Inyecta automáticamente el Bearer token de la sesión de Supabase Auth.
class ApiService {
  final http.Client _client;
  final String? Function() _tokenProvider;

  ApiService({http.Client? client, String? Function()? tokenProvider})
    : _client = client ?? http.Client(),
      _tokenProvider =
          tokenProvider ??
          (() => Supabase.instance.client.auth.currentSession?.accessToken);

  Map<String, String> get _headers {
    final token = _tokenProvider();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) => Uri.parse('${AppConstants.backendBaseUrl}$path');

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _send('PATCH', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = _uri(path);
    final headers = _headers;
    final encodedBody = body != null ? jsonEncode(body) : null;

    late http.Response res;
    switch (method) {
      case 'GET':
        res = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        res = await _client.post(uri, headers: headers, body: encodedBody);
        break;
      case 'PATCH':
        res = await _client.patch(uri, headers: headers, body: encodedBody);
        break;
      case 'DELETE':
        res = await _client.delete(uri, headers: headers);
        break;
      default:
        throw ArgumentError('Método HTTP no soportado: $method');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = res.body.isNotEmpty
          ? jsonDecode(res.body) as Map<String, dynamic>
          : <String, dynamic>{};
    } catch (_) {
      throw ApiException(
        'Respuesta inválida del servidor (${res.statusCode})',
        res.statusCode,
      );
    }

    final success = decoded['success'] == true;
    if (!success) {
      throw ApiException(
        decoded['message'] as String? ?? 'Error de red (${res.statusCode})',
        res.statusCode,
      );
    }

    return decoded['data'];
  }
}
