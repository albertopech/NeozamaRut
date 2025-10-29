import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../styles/app_styles.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _pulseController;
  int _selectedIndex = 0;
  GoogleMapController? _mapController;

  // Coordenadas iniciales (Cancún, México)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(21.1619, -86.8515),
    zoom: 14,
  );

  // Marcadores de autobuses
  final Set<Marker> _busMarkers = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _createBusMarkers();
  }

  void _createBusMarkers() {
    _busMarkers.addAll([
      Marker(
        markerId: const MarkerId('bus1'),
        position: const LatLng(21.1619, -86.8515),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Ruta 12'),
      ),
      Marker(
        markerId: const MarkerId('bus2'),
        position: const LatLng(21.1650, -86.8480),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Ruta 8'),
      ),
      Marker(
        markerId: const MarkerId('bus3'),
        position: const LatLng(21.1590, -86.8550),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: const InfoWindow(title: 'Ruta 5'),
      ),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Google Maps de fondo
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            markers: _busMarkers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            mapType: MapType.normal,
          ),

          // Barra de búsqueda superior
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildSearchBar(isDark),
          ),

          // Botones laterales
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 96,
            child: _buildSideButtons(isDark),
          ),

          // Tarjeta de información de ruta
          Positioned(
            bottom: 96,
            left: 16,
            right: 16,
            child: _buildRouteCard(isDark),
          ),

          // Barra de navegación inferior
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

  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate800.withOpacity(0.9)
            : AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.cardLarge,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 12),
            child: Icon(
              Icons.search,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
              size: 24,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.slate200 : AppColors.slate800,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar ruta o parada',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideButtons(bool isDark) {
    return Column(
      children: [
        _buildRoundButton(
          icon: Icons.layers_outlined,
          color: isDark ? AppColors.gold : AppColors.brown,
          isDark: isDark,
          onPressed: () {
            // Cambiar tipo de mapa
            if (_mapController != null) {
              setState(() {
                // Aquí puedes alternar entre mapType
              });
            }
          },
        ),
        const SizedBox(height: 12),
        _buildRoundButton(
          icon: Icons.my_location,
          color: isDark ? AppColors.white : AppColors.slate800,
          isDark: isDark,
          onPressed: () {
            // Centrar en ubicación actual
            if (_mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(const LatLng(21.1619, -86.8515)),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate800.withOpacity(0.9)
            : AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 24),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildRouteCard(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.slate800.withOpacity(0.9)
              : AppColors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.cardLarge,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus,
                color: AppColors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ruta 12 - Centro Histórico',
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppColors.slate100 : AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Próximo: 2 min - Av. Juárez',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.slate200.withOpacity(0.5)
                    : AppColors.slate200.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right,
                color: isDark ? AppColors.slate300 : AppColors.slate600,
                size: 20,
              ),
            ),
          ],
        ),
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
            AppColors.backgroundDark.withOpacity(0.8),
            AppColors.backgroundDark,
          ]
              : [
            Colors.transparent,
            AppColors.white.withOpacity(0.8),
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
              ? AppColors.backgroundDark.withOpacity(0.9)
              : AppColors.white.withOpacity(0.9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.map,
              label: 'Mapa',
              isSelected: _selectedIndex == 0,
              isDark: isDark,
              onTap: () => setState(() => _selectedIndex = 0),
            ),
            _buildNavItem(
              icon: Icons.subscriptions_outlined,
              label: 'Rutas',
              isSelected: _selectedIndex == 1,
              isDark: isDark,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            _buildNavItem(
              icon: Icons.schedule,
              label: 'Horarios',
              isSelected: _selectedIndex == 2,
              isDark: isDark,
              onTap: () => setState(() => _selectedIndex = 2),
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
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.map : icon,
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
      ),
    );
  }
}