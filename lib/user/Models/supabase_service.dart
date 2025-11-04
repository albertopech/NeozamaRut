import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';


class SupabaseService {
  // Instancia única del servicio (Singleton)
  static final SupabaseService _instance = SupabaseService._internal();

  // Getter para acceder a la instancia
  static SupabaseService get instance => _instance;

  // Cliente de Supabase
  late final SupabaseClient _client;

  // Getter público para el cliente
  SupabaseClient get client => _client;

  // Variable para controlar si ya se inicializó
  bool _isInitialized = false;

  // Constructor privado
  SupabaseService._internal();


  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ Supabase ya está inicializado');
      return;
    }

    try {
      // Validar que las credenciales estén configuradas
      if (SupabaseConfig.supabaseUrl == 'TU_SUPABASE_URL' ||
          SupabaseConfig.supabaseAnonKey == 'TU_SUPABASE_ANON_KEY') {
        throw Exception(
          '❌ ERROR: Las credenciales de Supabase no están configuradas.\n'
              'Por favor, edita el archivo supabase_config.dart y agrega tus credenciales.',
        );
      }

      // Inicializar Supabase
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        debug: true, // Activar logs en desarrollo
      );

      _client = Supabase.instance.client;
      _isInitialized = true;

      print('✅ Supabase inicializado correctamente');
      print('📍 URL: ${SupabaseConfig.supabaseUrl}');
    } catch (e) {
      print('❌ Error al inicializar Supabase: $e');
      rethrow;
    }
  }

  /// Verifica si hay una sesión activa de usuario
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Obtiene el usuario actual
  User? get currentUser => _client.auth.currentUser;

  /// Obtiene el ID del usuario actual
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Stream de cambios en el estado de autenticación
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      print('✅ Sesión cerrada correctamente');
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      rethrow;
    }
  }
  Future<bool> testConnection() async {
    try {
      // Intentar hacer una consulta simple
      final response = await _client
          .from('routes')
          .select('id')
          .limit(1);

      print('✅ Conexión a Supabase exitosa');
      return true;
    } catch (e) {
      print('❌ Error de conexión: $e');
      return false;
    }
  }

  /// Dispose del cliente (raramente necesario)
  void dispose() {
    // Supabase maneja la limpieza automáticamente
    _isInitialized = false;
  }
}