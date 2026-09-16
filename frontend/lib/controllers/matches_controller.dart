import 'package:flutter/material.dart';

import '../core/services/api_service.dart';
import '../models/match_model.dart';

/// Fuente única de verdad para los matches del usuario actual (adoptante o refugio).
/// El backend decide qué matches devolver según el rol del token JWT.
class MatchesController extends ChangeNotifier {
  final ApiService _api;

  MatchesController({ApiService? apiService})
    : _api = apiService ?? ApiService();

  List<MatchModel> _matches = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MatchModel> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.get('/swipes/matches');
      _matches = (data as List<dynamic>)
          .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
      _matches = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Actualiza el estado de una solicitud (solo refugios): aprobar para chat,
  /// programar entrevista, rechazar o finalizar la adopción.
  Future<bool> updateStatus(
    String matchId,
    String status, {
    String? comments,
  }) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (comments != null) {
        body['comments'] = comments;
      }
      final data = await _api.patch('/swipes/matches/$matchId/status', body);
      final updated = MatchModel.fromJson(data as Map<String, dynamic>);
      final idx = _matches.indexWhere((m) => m.id == matchId);
      if (idx != -1) {
        _matches[idx] = updated;
      } else {
        _matches.insert(0, updated);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
