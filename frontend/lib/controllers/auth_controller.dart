import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/api_service.dart';
import '../models/profile_model.dart';

class AuthController extends ChangeNotifier {
  final ApiService _api;
  final SupabaseClient _supabase;
  late final StreamSubscription<AuthState> _authSubscription;

  AuthController({ApiService? apiService, SupabaseClient? supabaseClient})
    : _api = apiService ?? ApiService(),
      _supabase = supabaseClient ?? Supabase.instance.client {
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
    );
    if (_supabase.auth.currentSession != null) {
      refreshProfile();
    }
  }

  bool _isLoading = false;
  String? _errorMessage;
  String _pendingRole = 'adopter';
  ProfileModel? _profile;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _supabase.auth.currentSession != null;
  String? get currentUserEmail => _supabase.auth.currentUser?.email;
  ProfileModel? get profile => _profile;
  String get userRole => _profile?.role ?? _pendingRole;
  bool get canPublishPets =>
      userRole == 'shelter' || userRole == 'individual_rescuer';

  String get roleTitle {
    switch (_pendingRole) {
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
      _pendingRole = role;
      notifyListeners();
    }
  }

  /// Envía el código OTP de 6 dígitos al correo (Supabase Auth passwordless)
  Future<bool> sendOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.auth.signInWithOtp(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo enviar el código. Intenta nuevamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verifica el código OTP y crea el perfil si es el primer ingreso
  Future<bool> verifyOtp(String email, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: code,
      );
      await _bootstrapProfile(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Código inválido o expirado.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _bootstrapProfile(String email) async {
    try {
      final data = await _api.get('/auth/profile');
      if (data != null) {
        _profile = ProfileModel.fromJson(data as Map<String, dynamic>);
        return;
      }
    } catch (_) {
      // Continúa para crear el perfil si todavía no existe
    }

    final fallbackName = email.contains('@') ? email.split('@').first : email;
    final created = await _api.post('/auth/profile', {
      'full_name': fallbackName,
      'role': _pendingRole,
    });
    _profile = ProfileModel.fromJson(created as Map<String, dynamic>);
  }

  Future<void> refreshProfile() async {
    try {
      final data = await _api.get('/auth/profile');
      if (data != null) {
        _profile = ProfileModel.fromJson(data as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {
      // Sin conexión o sin perfil todavía; se reintentará en el próximo refresh
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? organizationName,
  }) async {
    if (_profile == null) return false;
    try {
      final updated = await _api.post('/auth/profile', {
        'full_name': fullName ?? _profile!.fullName,
        'role': _profile!.role,
        'phone': phone ?? _profile!.phone,
        'address': address ?? _profile!.address,
        'organization_name': organizationName ?? _profile!.organizationName,
      });
      _profile = ProfileModel.fromJson(updated as Map<String, dynamic>);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _profile = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
