import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supabase_service.dart';

/// Controlador para gestionar las ubicaciones de autobuses en tiempo real
///
/// Maneja las operaciones de tracking, actualización y consulta
/// de posiciones de los autobuses en las rutas.
class BusLocationController {
  // Obtener el cliente de Supabase
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Obtener todas las ubicaciones activas de autobuses
  ///
  /// Retorna una lista de autobuses con sus ubicaciones actuales
  Future<List<Map<String, dynamic>>> getAllActiveBusLocations() async {
    try {
      final response = await _supabase
          .from('bus_locations')
          .select('''
            *,
            routes (
              route_number,
              route_name,
              color,
              transport_type
            )
          ''')
          .eq('is_active', true)
          .order('last_updated', ascending: false);

      print('✅ Se obtuvieron ${response.length} ubicaciones de autobuses');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error al obtener ubicaciones: $e');
      return [];
    }
  }

  /// Obtener ubicaciones de autobuses de una ruta específica
  ///
  /// [routeId] ID de la ruta
  Future<List<Map<String, dynamic>>> getBusLocationsByRoute(
      String routeId,
      ) async {
    try {
      final response = await _supabase
          .from('bus_locations')
          .select('''
            *,
            routes (
              route_number,
              route_name,
              color
            )
          ''')
          .eq('route_id', routeId)
          .eq('is_active', true)
          .order('last_updated', ascending: false);

      print('✅ Se obtuvieron ${response.length} autobuses en la ruta');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error al obtener autobuses de la ruta: $e');
      return [];
    }
  }

  /// Obtener la ubicación de un autobús específico
  ///
  /// [busIdentifier] Identificador del autobús (ej: "BUS-001")
  Future<Map<String, dynamic>?> getBusByIdentifier(
      String busIdentifier,
      ) async {
    try {
      final response = await _supabase
          .from('bus_locations')
          .select('''
            *,
            routes (
              route_number,
              route_name,
              color
            )
          ''')
          .eq('bus_identifier', busIdentifier)
          .eq('is_active', true)
          .single();

      print('✅ Ubicación del autobús $busIdentifier obtenida');
      return response;
    } catch (e) {
      print('❌ Error al obtener autobús: $e');
      return null;
    }
  }

  /// Obtener autobuses cercanos a una ubicación
  ///
  /// [latitude] Latitud de referencia
  /// [longitude] Longitud de referencia
  /// [radiusKm] Radio de búsqueda en kilómetros (por defecto 2 km)
  Future<List<Map<String, dynamic>>> getNearbyBuses(
      double latitude,
      double longitude, {
        double radiusKm = 2.0,
      }) async {
    try {
      final response = await _supabase
          .from('bus_locations')
          .select('''
            *,
            routes (
              route_number,
              route_name,
              color,
              transport_type
            )
          ''')
          .eq('is_active', true);

      // Filtrar autobuses dentro del radio
      final nearbyBuses = response.where((bus) {
        final busLat = bus['latitude'] as num;
        final busLon = bus['longitude'] as num;
        final distance = _calculateDistance(
          latitude,
          longitude,
          busLat.toDouble(),
          busLon.toDouble(),
        );
        return distance <= radiusKm;
      }).toList();

      // Ordenar por distancia (más cercano primero)
      nearbyBuses.sort((a, b) {
        final distA = _calculateDistance(
          latitude,
          longitude,
          (a['latitude'] as num).toDouble(),
          (a['longitude'] as num).toDouble(),
        );
        final distB = _calculateDistance(
          latitude,
          longitude,
          (b['latitude'] as num).toDouble(),
          (b['longitude'] as num).toDouble(),
        );
        return distA.compareTo(distB);
      });

      print('✅ Se encontraron ${nearbyBuses.length} autobuses cercanos');
      return List<Map<String, dynamic>>.from(nearbyBuses);
    } catch (e) {
      print('❌ Error al buscar autobuses cercanos: $e');
      return [];
    }
  }

  /// Stream de ubicaciones en tiempo real para una ruta
  ///
  /// [routeId] ID de la ruta
  /// Retorna un Stream que se actualiza cuando hay cambios
  Stream<List<Map<String, dynamic>>> watchBusLocationsByRoute(
      String routeId,
      ) {
    return _supabase
        .from('bus_locations')
        .stream(primaryKey: ['id'])
        .map((data) => data
        .where((item) => item['route_id'] == routeId && item['is_active'] == true)
        .toList());
  }

  /// Stream de todas las ubicaciones activas en tiempo real
  ///
  /// Útil para visualizar todos los autobuses en el mapa
  Stream<List<Map<String, dynamic>>> watchAllActiveBusLocations() {
    return _supabase
        .from('bus_locations')
        .stream(primaryKey: ['id'])
        .map((data) => data
        .where((item) => item['is_active'] == true)
        .toList());
  }

  /// Actualizar la ubicación de un autobús
  ///
  /// [busId] ID del registro de ubicación
  /// [latitude] Nueva latitud
  /// [longitude] Nueva longitud
  /// [heading] Dirección en grados (opcional)
  /// [speed] Velocidad en km/h (opcional)
  Future<bool> updateBusLocation(
      String busId, {
        required double latitude,
        required double longitude,
        double? heading,
        double? speed,
      }) async {
    try {
      final updates = {
        'latitude': latitude,
        'longitude': longitude,
        'last_updated': DateTime.now().toIso8601String(),
      };

      if (heading != null) updates['heading'] = heading;
      if (speed != null) updates['speed'] = speed;

      await _supabase
          .from('bus_locations')
          .update(updates)
          .eq('id', busId);

      print('✅ Ubicación del autobús actualizada');
      return true;
    } catch (e) {
      print('❌ Error al actualizar ubicación: $e');
      return false;
    }
  }

  /// Registrar un nuevo autobús en el sistema
  ///
  /// [busData] Datos del autobús incluyendo route_id, bus_identifier, ubicación, etc.
  Future<Map<String, dynamic>?> registerBus(
      Map<String, dynamic> busData,
      ) async {
    try {
      // Asegurar que tenga el timestamp correcto
      busData['last_updated'] = DateTime.now().toIso8601String();
      busData['is_active'] = busData['is_active'] ?? true;

      final response = await _supabase
          .from('bus_locations')
          .insert(busData)
          .select()
          .single();

      print('✅ Autobús registrado: ${response['bus_identifier']}');
      return response;
    } catch (e) {
      print('❌ Error al registrar autobús: $e');
      return null;
    }
  }

  /// Activar un autobús
  ///
  /// [busId] ID del autobús
  Future<bool> activateBus(String busId) async {
    try {
      await _supabase
          .from('bus_locations')
          .update({
        'is_active': true,
        'last_updated': DateTime.now().toIso8601String(),
      })
          .eq('id', busId);

      print('✅ Autobús activado');
      return true;
    } catch (e) {
      print('❌ Error al activar autobús: $e');
      return false;
    }
  }

  /// Desactivar un autobús
  ///
  /// [busId] ID del autobús
  Future<bool> deactivateBus(String busId) async {
    try {
      await _supabase
          .from('bus_locations')
          .update({'is_active': false})
          .eq('id', busId);

      print('✅ Autobús desactivado');
      return true;
    } catch (e) {
      print('❌ Error al desactivar autobús: $e');
      return false;
    }
  }

  /// Calcular tiempo estimado de llegada a una parada
  ///
  /// [busLatitude] Latitud del autobús
  /// [busLongitude] Longitud del autobús
  /// [stopLatitude] Latitud de la parada
  /// [stopLongitude] Longitud de la parada
  /// [averageSpeed] Velocidad promedio en km/h (por defecto 30 km/h)
  ///
  /// Retorna el tiempo estimado en minutos
  int calculateETA(
      double busLatitude,
      double busLongitude,
      double stopLatitude,
      double stopLongitude, {
        double averageSpeed = 30.0, // km/h
      }) {
    final distanceKm = _calculateDistance(
      busLatitude,
      busLongitude,
      stopLatitude,
      stopLongitude,
    );

    // Tiempo = Distancia / Velocidad (en horas)
    final timeHours = distanceKm / averageSpeed;

    // Convertir a minutos y redondear
    final timeMinutes = (timeHours * 60).round();

    return timeMinutes;
  }

  /// Obtener el autobús más cercano a una parada
  ///
  /// [routeId] ID de la ruta
  /// [stopLatitude] Latitud de la parada
  /// [stopLongitude] Longitud de la parada
  Future<Map<String, dynamic>?> getClosestBusToStop(
      String routeId,
      double stopLatitude,
      double stopLongitude,
      ) async {
    try {
      final buses = await getBusLocationsByRoute(routeId);

      if (buses.isEmpty) return null;

      // Encontrar el autobús más cercano
      Map<String, dynamic>? closestBus;
      double minDistance = double.infinity;

      for (final bus in buses) {
        final busLat = (bus['latitude'] as num).toDouble();
        final busLon = (bus['longitude'] as num).toDouble();

        final distance = _calculateDistance(
          stopLatitude,
          stopLongitude,
          busLat,
          busLon,
        );

        if (distance < minDistance) {
          minDistance = distance;
          closestBus = bus;
        }
      }

      if (closestBus != null) {
        // Agregar información de distancia y ETA
        closestBus['distance_km'] = minDistance;
        closestBus['eta_minutes'] = calculateETA(
          (closestBus['latitude'] as num).toDouble(),
          (closestBus['longitude'] as num).toDouble(),
          stopLatitude,
          stopLongitude,
        );
      }

      return closestBus;
    } catch (e) {
      print('❌ Error al encontrar autobús más cercano: $e');
      return null;
    }
  }

  /// Eliminar un autobús del sistema
  ///
  /// [busId] ID del autobús
  Future<bool> deleteBus(String busId) async {
    try {
      await _supabase
          .from('bus_locations')
          .delete()
          .eq('id', busId);

      print('✅ Autobús eliminado');
      return true;
    } catch (e) {
      print('❌ Error al eliminar autobús: $e');
      return false;
    }
  }

  /// Calcular distancia entre dos puntos usando fórmula de Haversine
  double _calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const double earthRadius = 6371; // Radio de la Tierra en km

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}