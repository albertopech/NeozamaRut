import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class DirectionsService {
  static const String _apiKey = 'AIzaSyAGCiyRubBEYjrqhfg--EzevEDrRuzc-oo';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Obtener ruta entre múltiples puntos
  Future<List<LatLng>> getRoutePoints(List<LatLng> waypoints) async {
    if (waypoints.length < 2) {
      return waypoints;
    }

    try {
      // Construir URL con origen, destino y puntos intermedios
      final origin = '${waypoints.first.latitude},${waypoints.first.longitude}';
      final destination = '${waypoints.last.latitude},${waypoints.last.longitude}';

      // Puntos intermedios (si hay más de 2 puntos)
      String waypointsParam = '';
      if (waypoints.length > 2) {
        final intermediatePoints = waypoints.sublist(1, waypoints.length - 1);
        waypointsParam = '&waypoints=' +
            intermediatePoints
                .map((point) => '${point.latitude},${point.longitude}')
                .join('|');
      }

      final url = Uri.parse(
          '$_baseUrl?origin=$origin&destination=$destination$waypointsParam&key=$_apiKey&mode=driving&language=es'
      );

      print('🗺️ Solicitando ruta a Google Directions API...');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final route = routes[0];
            final polylineString = route['overview_polyline']['points'] as String;

            // Decodificar polyline
            final polylinePoints = PolylinePoints();
            final decodedPoints = polylinePoints.decodePolyline(polylineString);

            final routePoints = decodedPoints
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();

            print('✅ Ruta obtenida: ${routePoints.length} puntos');
            return routePoints;
          }
        } else {
          print('❌ Error en Directions API: ${data['status']}');
          print('   Mensaje: ${data['error_message'] ?? 'Sin mensaje'}');
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error obteniendo ruta: $e');
    }

    // Si falla, devolver línea recta entre puntos
    return waypoints;
  }

  /// Obtener ruta simple entre dos puntos
  Future<List<LatLng>> getSimpleRoute(LatLng origin, LatLng destination) async {
    return getRoutePoints([origin, destination]);
  }

  /// Obtener distancia y duración entre dos puntos
  Future<Map<String, dynamic>?> getDistanceAndDuration(
      LatLng origin,
      LatLng destination,
      ) async {
    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';

      final url = Uri.parse(
          '$_baseUrl?origin=$originStr&destination=$destStr&key=$_apiKey&mode=driving&language=es'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final leg = routes[0]['legs'][0];

            return {
              'distance': leg['distance']['text'],
              'distance_value': leg['distance']['value'], // en metros
              'duration': leg['duration']['text'],
              'duration_value': leg['duration']['value'], // en segundos
            };
          }
        }
      }
    } catch (e) {
      print('❌ Error obteniendo distancia: $e');
    }

    return null;
  }
}