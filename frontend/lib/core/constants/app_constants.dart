class AppConstants {
  // URL del backend local (Android Emulator usa 10.0.2.2, Web/Dispositivo local usa localhost o tu IP)
  static const String backendBaseUrl = 'http://localhost:3000/api';

  // Configuración de Supabase Cloud
  static const String supabaseUrl = 'https://dummy-project.supabase.co';
  static const String supabaseAnonKey = 'dummy-anon-key';

  // Almacenamiento local keys
  static const String tokenKey = 'petmatch_auth_token';
}
