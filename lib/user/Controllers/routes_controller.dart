import 'dart:math' as Math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase_service.dart';

/// Controlador para gestionar las rutas de transporte público
///
/// Este controlador maneja todas las operaciones CRUD y consultas
/// relacionadas con las rutas de transporte.
class RoutesController {
  // Obtener el cliente de Supabase
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Obtener todas las rutas activas
  ///
  /// Retorna una lista de rutas ordenadas por número de ruta
  Future<List<Map<String, dynamic>>> getAllActiveRoutes() async {
    try {
      final response = await _supabase
          .from('routes')
          .select()
          .eq('is_active', true)
          .order('route_number');

      print('✅ Se obtuvieron ${response.length} rutas activas');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error al obtener rutas: $e');
      return [];
    }
  }

  /// Obtener una ruta por su número
  ///
  /// [routeNumber] Número de la ruta (ej: "5", "12", "27A")
  Future<Map<String, dynamic>?> getRouteByNumber(String routeNumber) async {
    try {
      final response = await _supabase
          .from('routes')
          .select()
          .eq('route_number', routeNumber)
          .single();

      print('✅ Ruta encontrada: ${response['route_name']}');
      return response;
    } catch (e) {
      print('❌ Error al buscar ruta $routeNumber: $e');
      return null;
    }
  }

  /// Obtener una ruta por su ID
  ///
  /// [routeId] ID único de la ruta (UUID)
  Future<Map<String, dynamic>?> getRouteById(String routeId) async {
    try {
      final response = await _supabase
          .from('routes')
          .select()
          .eq('id', routeId)
          .single();

      print('✅ Ruta encontrada: ${response['route_name']}');
      return response;
    } catch (e) {
      print('❌ Error al buscar ruta por ID: $e');
      return null;
    }
  }

  /// Buscar rutas por nombre o número
  ///
  /// [searchTerm] Término de búsqueda
  /// [limit] Número máximo de resultados (por defecto 10)
  Future<List<Map<String, dynamic>>> searchRoutes(
      String searchTerm, {
        int limit = 10,
      }) async {
    try {
      final response = await _supabase
          .from('routes')
          .select()
          .or('route_name.ilike.%$searchTerm%,route_number.ilike.%$searchTerm%')
          .eq('is_active', true)
          .limit(limit);

      print('✅ Se encontraron ${response.length} rutas para "$searchTerm"');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error al buscar rutas: $e');
      return [];
    }
  }

  /// Obtener rutas por tipo de transporte
  ///
  /// [transportType] Tipo de transporte ('bus', 'combi', 'rtp', etc.)
  Future<List<Map<String, dynamic>>> getRoutesByType(
      String transportType,
      ) async {
    try {
      final response = await _supabase
          .from('routes')
          .select()
          .eq('transport_type', transportType)
          .eq('is_active', true)
          .order('route_number');

      print('✅ Se obtuvieron ${response.length} rutas de tipo $transportType');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error al obtener rutas por tipo: $e');
      return [];
    }
  }

  /// Obtener las paradas de una ruta específica
  ///
  /// [routeId] ID de la ruta
  Future<List<Map<String, dynamic>>> getRouteStops(String routeId) async {
    try {
      final response = await _supabase
          .from('stops')
          .select()
          .eq('route_id', routeId)
          .order('stop_order');

      print('✅ Se obtuvieron ${response.length} paradas para la ruta');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error al obtener paradas: $e');
      return [];
    }
  }

  /// Obtener ruta con sus paradas incluidas
  ///
  /// [routeId] ID de la ruta
  Future<Map<String, dynamic>?> getRouteWithStops(String routeId) async {
    try {
      final response = await _supabase
          .from('routes')
          .select('''
            *,
            stops (
              id,
              stop_name,
              latitude,
              longitude,
              stop_order,
              estimated_time_from_start
            )
          ''')
          .eq('id', routeId)
          .single();

      print('✅ Ruta con paradas obtenida: ${response['route_name']}');
      return response;
    } catch (e) {
      print('❌ Error al obtener ruta con paradas: $e');
      return null;
    }
  }

  /// Obtener paradas cercanas a una ubicación
  ///
  /// [latitude] Latitud de la ubicación
  /// [longitude] Longitud de la ubicación
  /// [radiusKm] Radio de búsqueda en kilómetros (por defecto 1 km)
  Future<List<Map<String, dynamic>>> getNearbyStops(
      double latitude,
      double longitude, {
        double radiusKm = 1.0,
      }) async {
    try {
      // Supabase usa funciones de PostGIS para búsquedas geoespaciales
      // Por ahora, obtenemos todas las paradas y filtramos en el cliente
      final response = await _supabase
          .from('stops')
          .select('''
            *,
            routes (
              route_number,
              route_name,
              transport_type
            )
          ''');

      // Filtrar paradas dentro del radio usando fórmula de Haversine
      final nearbyStops = response.where((stop) {
        final stopLat = stop['latitude'] as num;
        final stopLon = stop['longitude'] as num;
        final distance = _calculateDistance(
          latitude,
          longitude,
          stopLat.toDouble(),
          stopLon.toDouble(),
        );
        return distance <= radiusKm;
      }).toList();

      print('✅ Se encontraron ${nearbyStops.length} paradas cercanas');
      return List<Map<String, dynamic>>.from(nearbyStops);
    } catch (e) {
      print('❌ Error al buscar paradas cercanas: $e');
      return [];
    }
  }

  /// Calcular distancia entre dos puntos usando fórmula de Haversine
  ///
  /// Retorna la distancia en kilómetros
  double _calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const double earthRadius = 6371; // Radio de la Tierra en km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_toRadians(lat1)) *
            Math.cos(_toRadians(lat2)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);

    final double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * Math.pi / 180;
  }

  /// Crear una nueva ruta (solo para administradores)
  ///
  /// [routeData] Datos de la ruta a crear
  Future<Map<String, dynamic>?> createRoute(
      Map<String, dynamic> routeData,
      ) async {
    try {
      final response = await _supabase
          .from('routes')
          .insert(routeData)
          .select()
          .single();

      print('✅ Ruta creada: ${response['route_name']}');
      return response;
    } catch (e) {
      print('❌ Error al crear ruta: $e');
      return null;
    }
  }

  /// Actualizar una ruta existente
  ///
  /// [routeId] ID de la ruta a actualizar
  /// [updates] Datos a actualizar
  Future<bool> updateRoute(
      String routeId,
      Map<String, dynamic> updates,
      ) async {
    try {
      await _supabase
          .from('routes')
          .update(updates)
          .eq('id', routeId);

      print('✅ Ruta actualizada correctamente');
      return true;
    } catch (e) {
      print('❌ Error al actualizar ruta: $e');
      return false;
    }
  }

  /// Desactivar una ruta (soft delete)
  ///
  /// [routeId] ID de la ruta a desactivar
  Future<bool> deactivateRoute(String routeId) async {
    try {
      await _supabase
          .from('routes')
          .update({'is_active': false})
          .eq('id', routeId);

      print('✅ Ruta desactivada correctamente');
      return true;
    } catch (e) {
      print('❌ Error al desactivar ruta: $e');
      return false;
    }
  }

  /// Eliminar una ruta permanentemente (solo administradores)
  ///
  /// [routeId] ID de la ruta a eliminar
  Future<bool> deleteRoute(String routeId) async {
    try {
      await _supabase
          .from('routes')
          .delete()
          .eq('id', routeId);

      print('✅ Ruta eliminada permanentemente');
      return true;
    } catch (e) {
      print('❌ Error al eliminar ruta: $e');
      return false;
    }
  }
}