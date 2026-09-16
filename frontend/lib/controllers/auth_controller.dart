import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String? _currentUserEmail;
  String? _authToken;
  String _userRole = 'adopter'; // 'adopter' | 'shelter' | 'individual_rescuer'
  final bool _isFormCompleted = true;

  bool get isLoading => _isLoading;
  String? get currentUserEmail => _currentUserEmail;
  String? get authToken => _authToken;
  String get userRole => _userRole;
  bool get isFormCompleted => _isFormCompleted;
  bool get isAuthenticated => _authToken != null || !kReleaseMode;

  bool get canPublishPets => _userRole == 'shelter' || _userRole == 'individual_rescuer';

  String get roleTitle {
    switch (_userRole) {
      case 'shelter':
        return 'Refugio u ONG';
      case 'individual_rescuer':
        return 'Particular con Camada / Rescatista';
      case 'adopter':
      default:
        return 'Adoptante';
    }
  }

  void setRole(String role) {
    if (['adopter', 'shelter', 'individual_rescuer'].contains(role)) {
      _userRole = role;
      notifyListeners();
    }
  }

  Future<bool> sendOtp(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _currentUserEmail = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _authToken = 'demo-jwt-token-123';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _authToken = null;
    _currentUserEmail = null;
    notifyListeners();
  }
}
