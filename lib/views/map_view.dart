import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Controllers/bus_location_controller.dart';
import '../Controllers/routes_controller.dart';
import '../Controllers/user_subscriptions_controller.dart';
import '../styles/app_styles.dart';
import 'routes_view.dart';
import 'schedules_view.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  int _selectedIndex = 0;
  GoogleMapController? _mapController;
  final BusLocationController _busController = BusLocationController();
  final RoutesController _routesController = RoutesController();
  final UserSubscriptionsController _subscriptionsController = UserSubscriptionsController();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;

  // ID del usuario (mismo que en routes_view)
  final String _userId = '11111111-1111-1111-1111-111111111111';

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(18.5001, -88.2961),
    zoom: 13,
  );

  @override
  void initState() {
    super.initState();
    _loadMapData();
    _startRealTimeTracking();
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

      print('✅ Parseados ${points.length} puntos del polyline');
    } catch (e) {
      print('❌ Error parseando polyline: $e');
    }

    return points;
  }

  Future<void> _loadMapData() async {
    setState(() => _isLoading = true);

    try {
      print('📍 Cargando datos del mapa...');

      // 🔑 Obtener solo las rutas suscritas del usuario
      final subscriptions = await _subscriptionsController.getUserSubscriptions(_userId);
      final subscribedRouteIds = subscriptions.map((sub) => sub['route_id'] as String).toSet();

      print('📋 Usuario suscrito a ${subscribedRouteIds.length} rutas');

      if (subscribedRouteIds.isEmpty) {
        setState(() {
          _markers = {};
          _polylines = {};
          _isLoading = false;
        });
        print('⚠️ No hay rutas suscritas para mostrar');
        return;
      }

      // Cargar todas las rutas
      final allRoutes = await _routesController.getAllActiveRoutes();

      // Filtrar solo las rutas suscritas
      final subscribedRoutes = allRoutes.where(
              (route) => subscribedRouteIds.contains(route['id'])
      ).toList();

      print('🗺️ Mostrando ${subscribedRoutes.length} rutas en el mapa');

      // Cargar autobuses de todas las rutas
      final buses = await _busController.getAllActiveBusLocations();

      // Filtrar solo autobuses de rutas suscritas
      final subscribedBuses = buses.where(
              (bus) => subscribedRouteIds.contains(bus['route_id'])
      ).toList();

      print('🚌 ${subscribedBuses.length} autobuses obtenidos');

      final newMarkers = <Marker>{};
      final newPolylines = <Polyline>{};

      // 🚌 Crear marcadores para autobuses de rutas suscritas
      for (final bus in subscribedBuses) {
        final lat = (bus['latitude'] as num).toDouble();
        final lon = (bus['longitude'] as num).toDouble();
        final busId = bus['bus_identifier'] as String;
        final route = bus['routes'];

        newMarkers.add(
          Marker(
            markerId: MarkerId(busId),
            position: LatLng(lat, lon),
            infoWindow: InfoWindow(
              title: '🚌 ${route != null ? route['route_name'] : 'Autobús'}',
              snippet: busId,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerColor(route?['transport_type'] ?? 'bus'),
            ),
            rotation: (bus['heading'] as num?)?.toDouble() ?? 0,
          ),
        );
      }

      // 🗺️ Procesar solo las rutas suscritas
      for (final route in subscribedRoutes) {
        final routeId = route['id'] as String;
        final routeName = route['route_name'] as String;
        final routeNumber = route['route_number'] as String;
        final polylineString = route['route_polyline'] as String?;

        print('\n📍 Procesando Ruta $routeNumber: $routeName');

        // Cargar paradas
        final stops = await _routesController.getRouteStops(routeId);

        // ✅ Marcadores de inicio y fin
        if (stops.isNotEmpty) {
          // 🟢 Inicio
          final firstStop = stops.first;
          newMarkers.add(
            Marker(
              markerId: MarkerId('start_$routeId'),
              position: LatLng(
                (firstStop['latitude'] as num).toDouble(),
                (firstStop['longitude'] as num).toDouble(),
              ),
              infoWindow: InfoWindow(
                title: '🟢 Inicio - ${firstStop['stop_name']}',
                snippet: 'Ruta $routeNumber',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );

          // 🔴 Final
          if (stops.length > 1) {
            final lastStop = stops.last;
            newMarkers.add(
              Marker(
                markerId: MarkerId('end_$routeId'),
                position: LatLng(
                  (lastStop['latitude'] as num).toDouble(),
                  (lastStop['longitude'] as num).toDouble(),
                ),
                infoWindow: InfoWindow(
                  title: '🔴 Final - ${lastStop['stop_name']}',
                  snippet: 'Ruta $routeNumber',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            );
          }
        }

        // 🛣️ Crear polyline
        if (polylineString != null && polylineString.isNotEmpty) {
          final routePoints = _parsePolyline(polylineString);

          if (routePoints.length >= 2) {
            newPolylines.add(
              Polyline(
                polylineId: PolylineId('route_$routeId'),
                points: routePoints,
                color: _getRouteColor(route['color'] as String?),
                width: 5,
                patterns: [
                  PatternItem.dash(20),
                  PatternItem.gap(10),
                ],
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                geodesic: true,
              ),
            );

            print('   ✅ Ruta trazada con ${routePoints.length} puntos');
          }
        }
      }

      setState(() {
        _markers = newMarkers;
        _polylines = newPolylines;
        _isLoading = false;
      });

      print('\n✅ TOTAL: ${newMarkers.length} marcadores y ${newPolylines.length} rutas\n');

    } catch (e) {
      print('❌ Error cargando datos: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startRealTimeTracking() {
    _busController.watchAllActiveBusLocations().listen((buses) async {
      // Obtener rutas suscritas
      final subscriptions = await _subscriptionsController.getUserSubscriptions(_userId);
      final subscribedRouteIds = subscriptions.map((sub) => sub['route_id'] as String).toSet();

      // Filtrar solo autobuses de rutas suscritas
      final subscribedBuses = buses.where(
              (bus) => subscribedRouteIds.contains(bus['route_id'])
      ).toList();

      final busMarkers = <Marker>{};

      for (final bus in subscribedBuses) {
        final lat = (bus['latitude'] as num).toDouble();
        final lon = (bus['longitude'] as num).toDouble();
        final busId = bus['bus_identifier'] as String;
        final route = bus['routes'];

        busMarkers.add(
          Marker(
            markerId: MarkerId(busId),
            position: LatLng(lat, lon),
            infoWindow: InfoWindow(
              title: '🚌 ${route != null ? route['route_name'] : 'Autobús'}',
              snippet: busId,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerColor(route?['transport_type'] ?? 'bus'),
            ),
            rotation: (bus['heading'] as num?)?.toDouble() ?? 0,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _markers = {
            ..._markers.where((m) =>
            m.markerId.value.startsWith('start_') ||
                m.markerId.value.startsWith('end_')
            ),
            ...busMarkers
          };
        });
      }
    });
  }

  double _getMarkerColor(String transportType) {
    switch (transportType) {
      case 'bus':
        return BitmapDescriptor.hueRed;
      case 'combi':
        return BitmapDescriptor.hueOrange;
      case 'rtp':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  Color _getRouteColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return AppColors.primary;

    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            compassEnabled: true,
            trafficEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),

          if (_isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Cargando rutas suscritas...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Mensaje cuando no hay rutas suscritas
          if (!_isLoading && _markers.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.route_outlined,
                      size: 64,
                      color: AppColors.gold,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay rutas suscritas',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.slate800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ve a la sección de Rutas para suscribirte a una ruta y verla en el mapa.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.slate600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RoutesView()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Ver Rutas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Buscar rutas en Chetumal...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.slate400 : AppColors.slate600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: isDark ? AppColors.gold : AppColors.primary,
                    ),
                    onPressed: _loadMapData,
                    tooltip: 'Recargar',
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
            Colors.transparent,
            AppColors.backgroundDark.withValues(alpha: 0.8),
            AppColors.backgroundDark,
          ]
              : [
            Colors.transparent,
            AppColors.white.withValues(alpha: 0.8),
            AppColors.white,
          ],
          stops: const [0.0, 0.2, 0.5],
        ),
      ),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.backgroundDark.withValues(alpha: 0.9)
              : AppColors.white.withValues(alpha: 0.9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.map,
              label: 'Mapa',
              isSelected: _selectedIndex == 0,
              isDark: isDark,
              onTap: () {},
            ),
            _buildNavItem(
              icon: Icons.subscriptions_outlined,
              label: 'Rutas',
              isSelected: _selectedIndex == 1,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RoutesView()),
                ).then((_) => _loadMapData()); // ⬅️ Recargar al volver
              },
            ),
            _buildNavItem(
              icon: Icons.schedule,
              label: 'Horarios',
              isSelected: _selectedIndex == 2,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SchedulesView()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final color = isSelected
        ? (isDark ? AppColors.gold : AppColors.primary)
        : (isDark ? AppColors.slate400 : AppColors.slate500);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected && label == 'Mapa' ? Icons.map : icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}