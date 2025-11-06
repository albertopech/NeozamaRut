import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supabase_service.dart';

/// Controlador para gestionar las suscripciones de usuarios a rutas
///
/// Maneja las operaciones de suscripción, favoritos y preferencias
/// de notificaciones de los usuarios.
class UserSubscriptionsController {
  // Obtener el cliente de Supabase
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Obtener todas las suscripciones de un usuario
  ///
  /// [userId] ID del usuario (si es null, usa el usuario autenticado)
  Future<List<Map<String, dynamic>>> getUserSubscriptions([
    String? userId,
  ]) async {
    try {
      final uid = userId ?? SupabaseService.instance.currentUserId;

      if (uid == null) {
        print('⚠️ No hay usuario autenticado');
        return [];
      }

      final response = await _supabase
          .from('user_subscriptions')
          .select('''
            *,
            routes (
              id,
              route_number,
              route_name,
              description,
              transport_type,
              color,
              frequency_minutes
            )
          ''')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      print('✅ Se obtuvieron ${response.length} suscripciones');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error al obtener suscripciones: $e');
      return [];
    }
  }

  /// Obtener solo las rutas favoritas del usuario
  ///
  /// [userId] ID del usuario (si es null, usa el usuario autenticado)
  Future<List<Map<String, dynamic>>> getFavoriteRoutes([
    String? userId,
  ]) async {
    try {
      final uid = userId ?? SupabaseService.instance.currentUserId;

      if (uid == null) {
        print('⚠️ No hay usuario autenticado');
        return [];
      }

      final response = await _supabase
          .from('user_subscriptions')
          .select('''
            *,
            routes (
              id,
              route_number,
              route_name,
              description,
              transport_type,
              color,
              frequency_minutes
            )
          ''')
          .eq('user_id', uid)
          .eq('is_favorite', true)
          .order('created_at', ascending: false);

      print('✅ Se obtuvieron ${response.length} rutas favoritas');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error al obtener favoritos: $e');
      return [];
    }
  }

  /// Suscribir usuario a una ruta
  ///
  /// [routeId] ID de la ruta
  /// [userId] ID del usuario (si es null, usa el usuario autenticado)
  /// [isFavorite] Marcar como favorita
  /// [notificationsEnabled] Habilitar notificaciones
  Future<Map<String, dynamic>?> subscribeToRoute(
      String routeId, {
        String? userId,
        bool isFavorite = false,
        bool notificationsEnabled = true,
      }) async {
    try {
      final uid = userId ?? SupabaseService.instance.currentUserId;

      if (uid == null) {
        print('⚠️ No hay usuario autenticado');
        return null;
      }

      // Verificar si ya existe la suscripción
      final existing = await _supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', uid)
          .eq('route_id', routeId)
          .maybeSingle();

      if (existing != null) {
        print('ℹ️ El usuario ya está suscrito a esta ruta');
        return existing;
      }

      // Crear nueva suscripción
      final response = await _supabase
          .from('user_subscriptions')
          .insert({
        'user_id': uid,
        'route_id': routeId,
        'is_favorite': isFavorite,
        'notifications_enabled': notificationsEnabled,
      })
          .select('''
            *,
            routes (
              route_number,
              route_name
            )
          ''')
          .single();

      print('✅ Usuario suscrito a la ruta ${response['routes']['route_name']}');
      return response;
    } catch (e) {
      print('❌ Error al suscribir a ruta: $e');
      return null;
    }
  }

  /// Desuscribir usuario de una ruta
  ///
  /// [routeId] ID de la ruta
  /// [userId] ID del usuario (si es null, usa el usuario autenticado)
  Future<bool> unsubscribeFromRoute(
      String routeId, {
        String? userId,
      }) async {
    try {
      final uid = userId ?? SupabaseService.instance.currentUserId;

      if (uid == null) {
        print('⚠️ No hay usuario autenticado');
        return false;
      }

      await _supabase
          .from('user_subscriptions')
          .delete()
          .eq('user_id', uid)
          .eq('route_id', routeId);

      print('✅ Usuario desuscrito de la ruta');
      return true;
    } catch (e) {
      print('❌ Error al desuscribir: $e');
      return false;
    }
  }

  /// Marcar/desmarcar una ruta como favorita
  ///
  /// [routeId] ID de la ruta
  /// [isFavorite] true para marcar como favorita, false para desmarcar
  /// [userId] ID del usuario (si es null, usa el usuario autenticado)
  Future<bool> toggleFavorite(
      String routeId,
      bool isFavorite, {
        String? userId,
      }) async {
    try {
      final uid = userId ?? SupabaseService.instance.currentUserId;

      if (uid == null) {
        print('⚠️ No hay usuario autenticado');
        return false;
      }

      await _supabase
          .from('user_subscriptions')
          .update({'is_favorite': isFavorite})
          .eq('user_id', uid)
          .eq('route_id', routeId);

      print('✅ Favorito ${isFavorite ? 'marcado' : 'desmarcado'}');
      return true;
    } catch (e) {
      print('❌ Error al actualizar favorito: $e');
      return false;
    }
  }

  /// Habilitar/deshabilitar notificaciones para una ruta
  ///
  /// [routeId] ID de la ruta
  /// [enabled] true para habilitar, false para deshabilitar
  /// [userId] ID del usuario (si es null, usa el usuario autenticado)
  Future<bool> toggleNotifications(
      String routeId,
      bool enabled, {
        String? userId,
      }) async {
    try {
      final uid = userId ?? SupabaseService.instance.currentUserId;

      if (uid == null) {
        print('⚠️ No hay usuario autenticado');
        return false;
      }

      await _supabase
          .from('user_subscriptions')
          .update({'notifications_enabled': enabled})
          .eq('user_id', uid)
          .eq('route_id', routeId);

      print('✅ Notificaciones ${enabled ? 'habilitadas' : 'deshabilitadas'}');
      return true;
    } catch (e) {
      print('❌ Error al actualizar notificaciones: $e');
      return false;
    }
  }

  /// Verificar si el usuario está suscrito a una ruta
  ///
  /// [routeId] ID de la ruta
  /// [userId] ID del usuario (si es null, usa el usuario autenticado)
  Future<bool> isSubscribed(
      String routeId, {
        String? userId,
      }) async {
    try {
      final uid = userId ?? SupabaseService.instance.currentUserId;

      if (uid == null) {
        return false;
      }

      final response = await _supabase
          .from('user_subscriptions')
          .select('id')
          .eq('user_id', uid)
          .eq('route_id', routeId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error al verificar suscripción: $e');
      return false;
    }
  }

  /// Verificar si una ruta es favorita del usuario
  ///
  /// [routeId] ID de la ruta
  /// [userId] ID del usuario (si es null, usa el usuario autenticado)
  Future<bool> isFavorite(
      String routeId, {
        String? userId,
      }) async {
    try {
      final uid = userId ?? SupabaseService.instance.currentUserId;

      if (uid == null) {
        return false;
      }

      final response = await _supabase
          .from('user_subscriptions')
          .select('is_favorite')
          .eq('user_id', uid)
          .eq('route_id', routeId)
          .maybeSingle();

      return response != null && response['is_favorite'] == true;
    } catch (e) {
      print('❌ Error al verificar favorito: $e');
      return false;
    }
  }

  /// Obtener el número de suscripciones del usuario
  ///
  /// [userId] ID del usuario (si es null, usa el usuario autenticado)
  Future<int> getSubscriptionCount([String? userId]) async {
    try {
      final uid = userId ?? SupabaseService.instance.currentUserId;

      if (uid == null) {
        return 0;
      }

      final response = await _supabase
          .from('user_subscriptions')
          .select('id')
          .eq('user_id', uid);

      return response.length;
    } catch (e) {
      print('❌ Error al contar suscripciones: $e');
      return 0;
    }
  }

  /// Obtener el número de favoritos del usuario
  ///
  /// [userId] ID del usuario (si es null, usa el usuario autenticado)
  Future<int> getFavoriteCount([String? userId]) async {
    try {
      final uid = userId ?? SupabaseService.instance.currentUserId;

      if (uid == null) {
        return 0;
      }

      final response = await _supabase
          .from('user_subscriptions')
          .select('id')
          .eq('user_id', uid)
          .eq('is_favorite', true);

      return response.length;
    } catch (e) {
      print('❌ Error al contar favoritos: $e');
      return 0;
    }
  }

  /// Stream de suscripciones en tiempo real
  ///
  /// [userId] ID del usuario (si es null, usa el usuario autenticado)
  Stream<List<Map<String, dynamic>>>? watchUserSubscriptions([
    String? userId,
  ]) {
    try {
      final uid = userId ?? SupabaseService.instance.currentUserId;

      if (uid == null) {
        print('⚠️ No hay usuario autenticado');
        return null;
      }

      return _supabase
          .from('user_subscriptions')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid)
          .order('created_at', ascending: false);
    } catch (e) {
      print('❌ Error al crear stream: $e');
      return null;
    }
  }

  /// Actualizar configuración de una suscripción
  ///
  /// [routeId] ID de la ruta
  /// [updates] Mapa con los campos a actualizar
  /// [userId] ID del usuario (si es null, usa el usuario autenticado)
  Future<bool> updateSubscription(
      String routeId,
      Map<String, dynamic> updates, {
        String? userId,
      }) async {
    try {
      final uid = userId ?? SupabaseService.instance.currentUserId;

      if (uid == null) {
        print('⚠️ No hay usuario autenticado');
        return false;
      }

      await _supabase
          .from('user_subscriptions')
          .update(updates)
          .eq('user_id', uid)
          .eq('route_id', routeId);

      print('✅ Suscripción actualizada');
      return true;
    } catch (e) {
      print('❌ Error al actualizar suscripción: $e');
      return false;
    }
  }

  /// Eliminar todas las suscripciones del usuario
  ///
  /// [userId] ID del usuario (si es null, usa el usuario autenticado)
  Future<bool> clearAllSubscriptions([String? userId]) async {
    try {
      final uid = userId ?? SupabaseService.instance.currentUserId;

      if (uid == null) {
        print('⚠️ No hay usuario autenticado');
        return false;
      }

      await _supabase
          .from('user_subscriptions')
          .delete()
          .eq('user_id', uid);

      print('✅ Todas las suscripciones eliminadas');
      return true;
    } catch (e) {
      print('❌ Error al eliminar suscripciones: $e');
      return false;
    }
  }
}