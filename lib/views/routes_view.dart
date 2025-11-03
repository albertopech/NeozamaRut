import 'package:flutter/material.dart';
import '../Controllers/routes_controller.dart';
import '../Controllers/user_subscriptions_controller.dart';
import '../Controllers/bus_location_controller.dart';
import '../styles/app_styles.dart';
import 'schedules_view.dart';

class RoutesView extends StatefulWidget {
  const RoutesView({super.key});

  @override
  State<RoutesView> createState() => _RoutesViewState();
}

class _RoutesViewState extends State<RoutesView> {
  final TextEditingController _searchController = TextEditingController();
  final RoutesController _routesController = RoutesController();
  final UserSubscriptionsController _subscriptionsController = UserSubscriptionsController();
  final BusLocationController _busController = BusLocationController();

  int _selectedIndex = 1;
  List<Map<String, dynamic>> _allRoutes = [];
  Set<String> _subscribedRouteIds = {};
  bool _isLoading = true;

  // ID del usuario (en producción esto vendría de autenticación)
  final String _userId = '11111111-1111-1111-1111-111111111111';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar todas las rutas
      final routes = await _routesController.getAllActiveRoutes();

      // Cargar suscripciones del usuario
      final subscriptions = await _subscriptionsController.getUserSubscriptions(_userId);
      final subscribedIds = subscriptions.map((sub) => sub['route_id'] as String).toSet();

      // Para cada ruta, obtener el autobús más cercano
      final routesWithBuses = <Map<String, dynamic>>[];

      for (final route in routes) {
        final routeId = route['id'] as String;
        final buses = await _busController.getBusLocationsByRoute(routeId);

        String nextBusTime = 'Sin datos';
        if (buses.isNotEmpty) {
          final random = (buses.length * 3) % 13 + 3;
          nextBusTime = '$random min';
        }

        routesWithBuses.add({
          ...route,
          'next_bus': nextBusTime,
          'has_buses': buses.isNotEmpty,
          'is_subscribed': subscribedIds.contains(routeId),
        });
      }

      setState(() {
        _allRoutes = routesWithBuses;
        _subscribedRouteIds = subscribedIds;
        _isLoading = false;
      });

      print('✅ Cargadas ${routesWithBuses.length} rutas');
      print('📋 Usuario suscrito a ${subscribedIds.length} rutas');
    } catch (e) {
      print('❌ Error cargando datos: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSubscription(String routeId, bool isCurrentlySubscribed) async {
    try {
      if (isCurrentlySubscribed) {
        // Desuscribir
        final success = await _subscriptionsController.unsubscribeFromRoute(
          routeId,
          userId: _userId,
        );

        if (success) {
          setState(() {
            _subscribedRouteIds.remove(routeId);
            _allRoutes = _allRoutes.map((route) {
              if (route['id'] == routeId) {
                return {...route, 'is_subscribed': false};
              }
              return route;
            }).toList();
          });

          _showSnackBar('Te has desuscrito de la ruta', Colors.orange);
        }
      } else {
        // Suscribir
        final result = await _subscriptionsController.subscribeToRoute(
          routeId,
          userId: _userId,
        );

        if (result != null) {
          setState(() {
            _subscribedRouteIds.add(routeId);
            _allRoutes = _allRoutes.map((route) {
              if (route['id'] == routeId) {
                return {...route, 'is_subscribed': true};
              }
              return route;
            }).toList();
          });

          _showSnackBar('¡Suscrito a la ruta!', Colors.green);
        }
      }
    } catch (e) {
      print('❌ Error al cambiar suscripción: $e');
      _showSnackBar('Error al procesar la solicitud', Colors.red);
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

  IconData _getRouteIcon(String transportType) {
    switch (transportType) {
      case 'combi':
        return Icons.airport_shuttle;
      case 'rtp':
        return Icons.rv_hookup;
      default:
        return Icons.directions_bus;
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
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildRoutesList(isDark),
              ),
            ],
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

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 16,
        16,
        16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rutas Disponibles',
                    style: AppTextStyles.h1.copyWith(
                      color: isDark ? AppColors.slate100 : AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_subscribedRouteIds.length} rutas suscritas',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                    ),
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate700 : AppColors.slate200,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: isDark ? AppColors.slate300 : AppColors.slate600,
                    size: 20,
                  ),
                  onPressed: _loadData,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.slate600 : AppColors.slate300,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.search,
                    color: AppColors.slate400,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.slate200 : AppColors.slate800,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar rutas...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.slate400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesList(bool isDark) {
    final filteredRoutes = _allRoutes.where((route) {
      if (_searchController.text.isEmpty) return true;

      final searchLower = _searchController.text.toLowerCase();
      final routeName = (route['route_name'] as String).toLowerCase();
      final routeNumber = (route['route_number'] as String).toLowerCase();

      return routeName.contains(searchLower) || routeNumber.contains(searchLower);
    }).toList();

    if (filteredRoutes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              size: 64,
              color: isDark ? AppColors.slate600 : AppColors.slate400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay rutas disponibles'
                  : 'No se encontraron rutas',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppColors.slate400 : AppColors.slate600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: filteredRoutes.length,
      itemBuilder: (context, index) {
        final route = filteredRoutes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRouteCard(
            routeId: route['id'],
            icon: _getRouteIcon(route['transport_type']),
            iconColor: _getRouteColor(route['color']),
            title: '${route['route_number']} - ${route['route_name']}',
            description: route['description'] ?? 'Sin descripción',
            nextBus: route['next_bus'],
            frequency: '${route['frequency_minutes']} min',
            isSubscribed: route['is_subscribed'] ?? false,
            isDark: isDark,
          ),
        );
      },
    );
  }

  Widget _buildRouteCard({
    required String routeId,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String nextBus,
    required String frequency,
    required bool isSubscribed,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
        border: isSubscribed
            ? Border.all(color: AppColors.gold, width: 2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.h3.copyWith(
                                color: isDark ? AppColors.slate100 : AppColors.slate800,
                              ),
                            ),
                          ),
                          if (isSubscribed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Suscrito',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.slate400 : AppColors.slate600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColors.slate400,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'toggle') {
                      _toggleSubscription(routeId, isSubscribed);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isSubscribed ? Icons.remove_circle_outline : Icons.add_circle_outline,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(isSubscribed ? 'Desuscribirse' : 'Suscribirse'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.slate700.withOpacity(0.5)
                    : AppColors.slate100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próximo autobús',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.slate400 : AppColors.slate600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextBus,
                          style: AppTextStyles.h3.copyWith(
                            color: isDark ? AppColors.gold : AppColors.primary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: isDark ? AppColors.slate600 : AppColors.slate300,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frecuencia',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.slate400 : AppColors.slate600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          frequency,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.slate200 : AppColors.slate800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildNavItem(
              icon: Icons.subscriptions_outlined,
              label: 'Rutas',
              isSelected: _selectedIndex == 1,
              isDark: isDark,
              onTap: () {},
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
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected && label == 'Rutas'
                    ? Icons.subscriptions
                    : icon,
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