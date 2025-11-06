import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../../styles/app_styles.dart';
import '../../models/supabase_service.dart';
import '../../shared/controllers/auth_controller.dart';
import '../controllers/driver_location_controller.dart';

/// Vista del mapa para conductores con GPS en tiempo real
class DriverMapView extends StatefulWidget {
  final Map<String, dynamic> route;

  const DriverMapView({
    super.key,
    required this.route,
  });

  @override
  State<DriverMapView> createState() => _DriverMapViewState();
}

class _DriverMapViewState extends State<DriverMapView> {
  GoogleMapController? _mapController;
  final AuthController _authController = AuthController();
  final DriverLocationController _locationController = DriverLocationController();

  bool _isTracking = false;
  bool _isLoading = false;
  String? _busLocationId;
  StreamSubscription<Position>? _locationSubscription;

  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _currentPosition;
  double _currentSpeed = 0.0;
  double _currentHeading = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final hasPermission = await _locationController.checkAndRequestPermissions();
    if (!hasPermission) {
      _showSnackBar(
        'Se requieren permisos de ubicación para el tracking',
        Colors.orange,
      );
    }
  }

  void _initializeMap() {
    try {
      final routePoints = _parsePolyline(widget.route['route_polyline'] as String);

      if (routePoints.isNotEmpty) {
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('driver_route'),
              points: routePoints,
              color: _getRouteColor(widget.route['color'] as String?),
              width: 6,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              geodesic: true,
            ),
          );

          _markers.add(
            Marker(
              markerId: const MarkerId('start'),
              position: routePoints.first,
              infoWindow: const InfoWindow(
                title: '🟢 Inicio de Ruta',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );

          if (routePoints.length > 1) {
            _markers.add(
              Marker(
                markerId: const MarkerId('end'),
                position: routePoints.last,
                infoWindow: const InfoWindow(
                  title: '🔴 Fin de Ruta',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            );
          }
        });

        print('✅ Ruta cargada: ${routePoints.length} puntos');
      }

      // Obtener ubicación inicial
      _getCurrentLocation();
    } catch (e) {
      print('❌ Error inicializando mapa: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    final location = await _locationController.getCurrentLocation();
    if (location != null && mounted) {
      setState(() {
        _currentPosition = location;
      });

      // Centrar el mapa en la ubicación actual
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15),
      );
    }
  }

  List<LatLng> _parsePolyline(String polylineString) {
    final points = <LatLng>[];
    try {
      final segments = polylineString.split('|');
      for (final segment in segments) {
        final coords = segment.split(',');
        if (coords.length == 2) {
          final lat = double.parse(coords[0].trim());
          final lng = double.parse(coords[1].trim());
          points.add(LatLng(lat, lng));
        }
      }
    } catch (e) {
      print('❌ Error parseando polyline: $e');
    }
    return points;
  }

  Color _getRouteColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return AppColors.primary;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  Future<void> _startTracking() async {
    setState(() => _isLoading = true);

    try {
      final supabase = SupabaseService.instance.client;
      final user = _authController.getCurrentUser();

      if (user == null) {
        _showSnackBar('Error: Usuario no autenticado', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // Obtener ubicación actual
      final location = await _locationController.getCurrentLocation();
      if (location == null) {
        _showSnackBar('No se pudo obtener la ubicación GPS', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final busIdentifier = 'BUS-${widget.route['route_number']}-${user.id.substring(0, 8)}';

      // Verificar si ya existe una ubicación activa
      final existing = await supabase
          .from('bus_locations')
          .select()
          .eq('route_id', widget.route['id'])
          .eq('bus_identifier', busIdentifier)
          .eq('is_active', true)
          .maybeSingle();

      if (existing != null) {
        _busLocationId = existing['id'];
        print('ℹ️ Reanudando tracking existente: $_busLocationId');
      } else {
        // Crear nueva ubicación
        final response = await supabase
            .from('bus_locations')
            .insert({
          'route_id': widget.route['id'],
          'bus_identifier': busIdentifier,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'heading': 0.0,
          'speed': 0.0,
          'is_active': true,
          'last_updated': DateTime.now().toIso8601String(),
        })
            .select()
            .single();

        _busLocationId = response['id'];
        print('✅ Bus location creado: $_busLocationId');
      }

      // Iniciar tracking GPS en tiempo real
      _startGPSTracking();

      setState(() {
        _isTracking = true;
        _isLoading = false;
      });

      _showSnackBar('✅ Tracking GPS iniciado', Colors.green);
    } catch (e) {
      print('❌ Error iniciando tracking: $e');
      _showSnackBar('Error al iniciar tracking: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  void _startGPSTracking() {
    _locationSubscription = _locationController.getLocationStream().listen(
          (Position position) async {
        if (!_isTracking || _busLocationId == null) return;

        try {
          final newPosition = LatLng(position.latitude, position.longitude);
          final speed = _locationController.calculateSpeed(position.speed);

          double heading = _currentHeading;
          if (_currentPosition != null) {
            heading = _locationController.calculateHeading(_currentPosition!, newPosition);
          }

          // Actualizar en Supabase
          await SupabaseService.instance.client
              .from('bus_locations')
              .update({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'heading': heading,
            'speed': speed,
            'last_updated': DateTime.now().toIso8601String(),
          })
              .eq('id', _busLocationId!);

          // Actualizar UI
          if (mounted) {
            setState(() {
              _currentPosition = newPosition;
              _currentSpeed = speed;
              _currentHeading = heading;

              // COMENTARIO: Se ha eliminado la lógica del marcador 'current_bus'
              // porque se utiliza el punto de ubicación nativo de Google Maps
              // habilitado con myLocationEnabled: true.

              /*
              _markers.removeWhere((m) => m.markerId.value == 'current_bus');
              _markers.add(
                Marker(
                  markerId: const MarkerId('current_bus'),
                  position: newPosition,
                  infoWindow: InfoWindow(
                    title: '🚌 Mi Autobús',
                    snippet: '${speed.toStringAsFixed(1)} km/h',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                  rotation: heading,
                ),
              );
              */
            });

            // Centrar cámara en la posición actual
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(newPosition),
            );
          }

          print('📍 GPS: ${position.latitude}, ${position.longitude} - ${speed.toStringAsFixed(1)} km/h');
        } catch (e) {
          print('❌ Error actualizando ubicación: $e');
        }
      },
      onError: (error) {
        print('❌ Error en stream GPS: $error');
        _showSnackBar('Error en GPS: $error', Colors.red);
      },
    );
  }

  Future<void> _stopTracking() async {
    if (_busLocationId == null) return;

    setState(() => _isLoading = true);

    try {
      // Cancelar suscripción GPS
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      // Desactivar la ubicación del autobús
      await SupabaseService.instance.client
          .from('bus_locations')
          .update({'is_active': false})
          .eq('id', _busLocationId!);

      setState(() {
        _isTracking = false;
        _isLoading = false;
        _currentSpeed = 0.0;
        // COMENTARIO: Se elimina la limpieza del marcador personalizado
        // _markers.removeWhere((m) => m.markerId.value == 'current_bus');
      });

      _showSnackBar('✅ Tracking detenido', Colors.orange);
      print('✅ Tracking detenido: $_busLocationId');
    } catch (e) {
      print('❌ Error deteniendo tracking: $e');
      _showSnackBar('Error al detener tracking: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routePoints = _parsePolyline(widget.route['route_polyline'] as String);
    final initialPosition = _currentPosition != null
        ? CameraPosition(
      target: _currentPosition!,
      zoom: 15,
    )
        : routePoints.isNotEmpty
        ? CameraPosition(
      target: routePoints.first,
      zoom: 14,
    )
        : const CameraPosition(
      target: LatLng(18.5001, -88.2961),
      zoom: 13,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            initialCameraPosition: initialPosition,
            markers: _markers, // Muestra solo marcadores de inicio/fin de ruta
            polylines: _polylines,
            myLocationEnabled: true, // ⬅️ Muestra el punto azul (ubicación del conductor)
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            compassEnabled: true,
            trafficEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),

          // Header
// ... (resto del código del widget build)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16,
                16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.route['route_name'] as String,
                          style: AppTextStyles.h3.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Ruta ${widget.route['route_number']}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isTracking ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isTracking ? Icons.radio_button_checked : Icons.circle,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isTracking ? 'En ruta' : 'Detenido',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Panel de control
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        icon: Icons.speed,
                        label: 'Velocidad',
                        value: '${_currentSpeed.toStringAsFixed(1)} km/h',
                        isDark: isDark,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: isDark ? AppColors.slate600 : AppColors.slate300,
                      ),
                      _buildInfoItem(
                        icon: Icons.timer,
                        label: 'Frecuencia',
                        value: '${widget.route['frequency_minutes']} min',
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_isTracking ? _stopTracking : _startTracking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTracking ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isTracking ? Icons.stop : Icons.play_arrow,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isTracking ? 'Detener Ruta' : 'Iniciar Ruta',
                            style: AppTextStyles.h3.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.gold,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppColors.slate400 : AppColors.slate600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.slate100 : AppColors.slate800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}