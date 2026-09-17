import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/api_service.dart';
import '../models/profile_model.dart';

const _pendingRolePrefsKey = 'petmatch_pending_role';

class AuthController extends ChangeNotifier {
  final ApiService _api;
  final SupabaseClient _supabase;
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isBootstrapping = false;

  AuthController({ApiService? apiService, SupabaseClient? supabaseClient})
    : _api = apiService ?? ApiService(),
      _supabase = supabaseClient ?? Supabase.instance.client {
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
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

  void _handleAuthStateChange(AuthState data) {
    if (data.event == AuthChangeEvent.signedIn && _profile == null) {
      _bootstrapProfile();
    } else if (data.event == AuthChangeEvent.signedOut) {
      _profile = null;
    }
    notifyListeners();
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

  /// Verifica el código OTP. El bootstrap del perfil lo dispara automáticamente
  /// el listener de onAuthStateChange (mismo mecanismo que usa Google Sign-In).
  Future<bool> verifyOtp(String email, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _persistPendingRole();
      await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: code,
      );
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

  /// Inicia sesión con Google. En web esto redirige la página completa a
  /// Google y vuelve; por eso el rol elegido se persiste en SharedPreferences
  /// antes de salir, ya que la instancia de este controller se recrea al volver.
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _persistPendingRole();
      await _supabase.auth.signInWithOAuth(OAuthProvider.google);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo iniciar sesión con Google.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _persistPendingRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingRolePrefsKey, _pendingRole);
    } catch (_) {
      // Si falla el storage local, seguimos igual con _pendingRole en memoria.
    }
  }

  Future<void> _bootstrapProfile() async {
    if (_isBootstrapping) return;
    _isBootstrapping = true;
    try {
      final data = await _api.get('/auth/profile');
      if (data != null) {
        _profile = ProfileModel.fromJson(data as Map<String, dynamic>);
        notifyListeners();
        return;
      }

      String role = _pendingRole;
      try {
        final prefs = await SharedPreferences.getInstance();
        final storedRole = prefs.getString(_pendingRolePrefsKey);
        if (storedRole != null) {
          role = storedRole;
          await prefs.remove(_pendingRolePrefsKey);
        }
      } catch (_) {
        // Sin storage disponible, usamos _pendingRole tal cual.
      }

      final user = _supabase.auth.currentUser;
      final metadataName =
          user?.userMetadata?['full_name'] as String? ??
          user?.userMetadata?['name'] as String?;
      final email = user?.email ?? '';
      final fallbackName =
          metadataName ??
          (email.contains('@') ? email.split('@').first : email);

      final created = await _api.post('/auth/profile', {
        'full_name': fallbackName,
        'role': role,
      });
      _profile = ProfileModel.fromJson(created as Map<String, dynamic>);
      notifyListeners();
    } catch (_) {
      // Sin conexión; se reintentará en el próximo refresh.
    } finally {
      _isBootstrapping = false;
    }
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
    double? latitude,
    double? longitude,
  }) async {
    if (_profile == null) return false;
    try {
      final updated = await _api.post('/auth/profile', {
        'full_name': fullName ?? _profile!.fullName,
        'role': _profile!.role,
        'phone': phone ?? _profile!.phone,
        'address': address ?? _profile!.address,
        'organization_name': organizationName ?? _profile!.organizationName,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
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

  /// Intenta capturar la ubicación real del dispositivo una sola vez (si el
  /// perfil todavía no tiene una guardada) y la persiste. Silenciosa ante
  /// cualquier error (permiso denegado, GPS apagado, plataforma sin soporte):
  /// las funciones de distancia simplemente quedan ocultas si no hay ubicación.
  Future<void> ensureLocationCaptured() async {
    if (_profile == null || _profile!.hasLocation) return;

    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission granted = permission;
      if (granted == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }
      if (granted == LocationPermission.denied ||
          granted == LocationPermission.deniedForever) {
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      await updateProfile(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Ubicación no disponible; se sigue funcionando sin distancia real.
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
