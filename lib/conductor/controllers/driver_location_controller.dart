import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math; // ⬅️ Agregar este import

/// Controlador para manejar la ubicación GPS del conductor
class DriverLocationController {
  Stream<Position>? _positionStream;

  /// Verificar y solicitar permisos de ubicación
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Servicio de ubicación deshabilitado');
      return false;
    }

    // Verificar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Permisos de ubicación denegados');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Permisos de ubicación denegados permanentemente');
      return false;
    }

    print('✅ Permisos de ubicación concedidos');
    return true;
  }

  /// Obtener la ubicación actual del dispositivo
  Future<LatLng?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('📍 Ubicación actual: ${position.latitude}, ${position.longitude}');
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('❌ Error obteniendo ubicación: $e');
      return null;
    }
  }

  /// Stream de actualizaciones de ubicación en tiempo real
  Stream<Position> getLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Actualizar cada 10 metros
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );

    return _positionStream!;
  }

  /// Calcular la dirección (heading) entre dos puntos
  double calculateHeading(LatLng from, LatLng to) {
    final lat1 = from.latitude * (math.pi / 180);
    final lat2 = to.latitude * (math.pi / 180);
    final dLon = (to.longitude - from.longitude) * (math.pi / 180);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final heading = math.atan2(y, x) * (180 / math.pi);
    return (heading + 360) % 360;
  }

  /// Calcular velocidad en km/h desde m/s
  double calculateSpeed(double speedMps) {
    return speedMps * 3.6; // Convertir m/s a km/h
  }
}