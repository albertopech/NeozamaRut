import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supabase_service.dart';

/// Controlador de autenticación
///
/// Maneja el login, registro y gestión de sesiones
/// para usuarios normales y conductores
class AuthController {
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Registrar un nuevo usuario normal
  ///
  /// [email] Correo electrónico
  /// [password] Contraseña
  /// [fullName] Nombre completo
  Future<Map<String, dynamic>?> registerUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Registrar en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': 'user', // Rol de usuario normal
        },
      );

      if (response.user == null) {
        print('❌ Error al registrar usuario');
        return null;
      }

      print('✅ Usuario registrado: ${response.user!.email}');
      return {
        'user': response.user,
        'session': response.session,
      };
    } catch (e) {
      print('❌ Error en registro: $e');
      return null;
    }
  }

  /// Login para usuarios normales
  ///
  /// [email] Correo electrónico
  /// [password] Contraseña
  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        print('❌ Error al iniciar sesión');
        return null;
      }

      // Verificar que sea un usuario normal
      final role = response.user!.userMetadata?['role'] ?? 'user';

      print('✅ Usuario autenticado: ${response.user!.email} (rol: $role)');
      return {
        'user': response.user,
        'session': response.session,
        'role': role,
      };
    } catch (e) {
      print('❌ Error en login: $e');
      return null;
    }
  }

  /// Login para conductores
  ///
  /// [email] Correo electrónico
  /// [password] Contraseña
  /// Solo permite acceso a usuarios con rol 'driver'
  Future<Map<String, dynamic>?> loginDriver({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        print('❌ Error al iniciar sesión');
        return null;
      }

      // Verificar que sea un conductor
      final role = response.user!.userMetadata?['role'];

      if (role != 'driver') {
        print('❌ El usuario no tiene permisos de conductor');
        await _supabase.auth.signOut();
        return null;
      }

      print('✅ Conductor autenticado: ${response.user!.email}');
      return {
        'user': response.user,
        'session': response.session,
        'role': role,
      };
    } catch (e) {
      print('❌ Error en login de conductor: $e');
      return null;
    }
  }

  /// Obtener el rol del usuario actual
  String? getCurrentUserRole() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    return user.userMetadata?['role'] ?? 'user';
  }

  /// Verificar si el usuario actual es conductor
  bool isDriver() {
    return getCurrentUserRole() == 'driver';
  }

  /// Verificar si hay una sesión activa
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  /// Obtener el usuario actual
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Cerrar sesión
  Future<bool> signOut() async {
    try {
      await _supabase.auth.signOut();
      print('✅ Sesión cerrada');
      return true;
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      return false;
    }
  }

  /// Stream de cambios en la sesión
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }
}