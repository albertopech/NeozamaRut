import 'package:flutter/material.dart';
import '../Controllers/routes_controller.dart';
import '../Controllers/schedules_controller.dart';
import '../styles/app_styles.dart';

class SchedulesView extends StatefulWidget {
  const SchedulesView({super.key});

  @override
  State<SchedulesView> createState() => _SchedulesViewState();
}

class _SchedulesViewState extends State<SchedulesView> {
  final TextEditingController _searchController = TextEditingController();
  final RoutesController _routesController = RoutesController();
  final SchedulesController _schedulesController = SchedulesController();

  int _selectedIndex = 2;
  List<Map<String, dynamic>> _routesWithSchedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);

    try {
      final routes = await _routesController.getAllActiveRoutes();
      final routesWithSchedules = <Map<String, dynamic>>[];

      for (final route in routes) {
        final routeId = route['id'] as String;
        final schedules = await _schedulesController.getRouteSchedules(routeId);

        routesWithSchedules.add({
          ...route,
          'schedules': schedules,
          'hasSchedules': schedules.isNotEmpty,
        });
      }

      setState(() {
        _routesWithSchedules = routesWithSchedules;
        _isLoading = false;
      });

      print('✅ Cargados horarios de ${routesWithSchedules.length} rutas');
    } catch (e) {
      print('❌ Error cargando horarios: $e');
      setState(() => _isLoading = false);
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
              _buildSearchAndFilters(isDark),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(isDark),
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
        8,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withOpacity(0.8)
            : AppColors.backgroundLight.withOpacity(0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: IconButton(
              icon: Icon(
                Icons.menu,
                color: isDark ? AppColors.brown : AppColors.brown,
              ),
              onPressed: () {},
            ),
          ),
          Expanded(
            child: Text(
              'Horarios y Precios',
              style: AppTextStyles.h2.copyWith(
                color: isDark ? AppColors.slate100 : AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: isDark ? AppColors.brown : AppColors.brown,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate800 : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.slate600 : AppColors.slate300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                Icons.search,
                color: isDark ? AppColors.brown : AppColors.brown,
                size: 24,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.slate200 : AppColors.brown,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar ruta, parada o destino...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.brown.withOpacity(0.6)
                        : AppColors.brown.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final filteredRoutes = _routesWithSchedules.where((route) {
      if (_searchController.text.isEmpty) return true;

      final searchLower = _searchController.text.toLowerCase();
      final routeName = (route['route_name'] as String).toLowerCase();
      final routeNumber = (route['route_number'] as String).toLowerCase();

      return routeName.contains(searchLower) || routeNumber.contains(searchLower);
    }).toList();

    // Solo mostrar mensaje de "no resultados" si hay búsqueda activa y no hay resultados
    final showNoResults = _searchController.text.isNotEmpty && filteredRoutes.isEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        Text(
          'Rutas Populares',
          style: AppTextStyles.h2.copyWith(
            color: isDark ? AppColors.slate100 : AppColors.brown,
          ),
        ),
        const SizedBox(height: 12),

        // Mostrar rutas
        ...filteredRoutes.map((route) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRouteAccordion(
              icon: Icons.directions_bus,
              title: '${route['route_number']} - ${route['route_name']}',
              frequency: 'Frecuencia: ${route['frequency_minutes']} min',
              schedules: route['schedules'] as List,
              hasDetails: route['hasSchedules'] as bool,
              isDark: isDark,
            ),
          );
        }).toList(),

        // Solo mostrar "no resultados" si hay búsqueda y no hay resultados
        if (showNoResults) ...[
          const SizedBox(height: 24),
          _buildEmptyState(isDark),
        ],
      ],
    );
  }

  Widget _buildRouteAccordion({
    required IconData icon,
    required String title,
    required String frequency,
    required List<dynamic> schedules,
    required bool hasDetails,
    required bool isDark,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate800 : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.slate600 : AppColors.slate300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          title: Text(
            title,
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppColors.slate100 : AppColors.brown,
            ),
          ),
          subtitle: Text(
            frequency,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.brown.withOpacity(0.7)
                  : AppColors.brown.withOpacity(0.7),
            ),
          ),
          trailing: Icon(
            Icons.expand_more,
            color: isDark ? AppColors.brown : AppColors.brown,
          ),
          children: [
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.slate600 : AppColors.slate300,
                  ),
                ),
              ),
              child: hasDetails
                  ? _buildRouteDetails(schedules, isDark)
                  : Text(
                'Detalles de horarios y precios para $title no disponibles en este momento.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.brown.withOpacity(0.7)
                      : AppColors.brown.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteDetails(List<dynamic> schedules, bool isDark) {
    if (schedules.isEmpty) {
      return Text(
        'No hay horarios disponibles.',
        style: AppTextStyles.bodySmall.copyWith(
          color: isDark
              ? AppColors.brown.withOpacity(0.7)
              : AppColors.brown.withOpacity(0.7),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tarifas',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppColors.slate100 : AppColors.brown,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sell, color: AppColors.gold, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '\$12.00 MXN',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPriceRow('Tarifa General:', '\$12.00', isDark),
        const SizedBox(height: 8),
        _buildPriceRow('Tarifa Estudiante:', '\$8.00', isDark),
        const SizedBox(height: 16),
        Text(
          'Horarios (Lunes a Viernes)',
          style: AppTextStyles.h3.copyWith(
            color: isDark ? AppColors.slate100 : AppColors.brown,
          ),
        ),
        const SizedBox(height: 12),
        _buildScheduleTable(schedules, isDark),
      ],
    );
  }

  Widget _buildPriceRow(String label, String price, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark
                ? AppColors.brown.withOpacity(0.8)
                : AppColors.brown.withOpacity(0.8),
          ),
        ),
        Text(
          price,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppColors.slate100 : AppColors.brown,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTable(List<dynamic> schedules, bool isDark) {
    if (schedules.isEmpty) {
      return Text(
        'No hay horarios disponibles.',
        style: AppTextStyles.bodySmall.copyWith(
          color: isDark
              ? AppColors.brown.withOpacity(0.7)
              : AppColors.brown.withOpacity(0.7),
        ),
      );
    }

    // Tomar el primer horario
    final schedule = schedules.first;
    final startTime = _schedulesController.formatTime(schedule['start_time']);
    final endTime = _schedulesController.formatTime(schedule['end_time']);
    final frequency = '${schedule['frequency_minutes']} min';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.slate600 : AppColors.slate300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'PRIMER CAMIÓN',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.brown.withOpacity(0.7)
                          : AppColors.brown.withOpacity(0.7),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'ÚLTIMO CAMIÓN',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.brown.withOpacity(0.7)
                          : AppColors.brown.withOpacity(0.7),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'FRECUENCIA',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.brown.withOpacity(0.7)
                          : AppColors.brown.withOpacity(0.7),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$startTime AM',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.slate100 : AppColors.brown,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    '$endTime PM',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.brown.withOpacity(0.9)
                          : AppColors.brown.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    frequency,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.brown.withOpacity(0.9)
                          : AppColors.brown.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.slate600 : AppColors.slate300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: AppColors.gold,
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppColors.slate100 : AppColors.brown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Intenta con otra búsqueda o revisa los filtros aplicados.',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.brown.withOpacity(0.7)
                  : AppColors.brown.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.slate600 : AppColors.slate300,
          ),
        ),
        color: isDark
            ? AppColors.backgroundDark.withOpacity(0.8)
            : AppColors.white.withOpacity(0.8),
      ),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
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
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            _buildNavItem(
              icon: Icons.bookmarks_outlined,
              label: 'Rutas',
              isSelected: _selectedIndex == 1,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildNavItem(
              icon: Icons.schedule,
              label: 'Horarios',
              isSelected: _selectedIndex == 2,
              isDark: isDark,
              onTap: () {},
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
        : (isDark
        ? AppColors.brown.withOpacity(0.6)
        : AppColors.brown.withOpacity(0.6));

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
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
}