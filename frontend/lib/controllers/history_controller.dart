import 'package:flutter/material.dart';

import '../core/services/api_service.dart';
import '../models/history_models.dart';

/// Historial consolidado de contratos y visitas de todos los matches del
/// usuario, en vez de tener que revisar match por match.
class HistoryController extends ChangeNotifier {
  final ApiService _api;

  HistoryController({ApiService? apiService}) : _api = apiService ?? ApiService();

  List<ContractHistoryItem> _contracts = [];
  List<VisitHistoryItem> _visits = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ContractHistoryItem> get contracts => _contracts;
  List<VisitHistoryItem> get visits => _visits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([_api.get('/contracts'), _api.get('/visits')]);

      _contracts = (results[0] as List<dynamic>)
          .map((e) => ContractHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _visits = (results[1] as List<dynamic>)
          .map((e) => VisitHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
