import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class SchedulesView extends StatefulWidget {
  const SchedulesView({super.key});

  @override
  State<SchedulesView> createState() => _SchedulesViewState();
}

class _SchedulesViewState extends State<SchedulesView> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 2; // Horarios está seleccionado

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              // Header
              _buildHeader(isDark),

              // Search y Filtros
              _buildSearchAndFilters(isDark),

              // Contenido principal
              Expanded(
                child: _buildContent(isDark),
              ),
            ],
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
            decoration: BoxDecoration(
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
            decoration: BoxDecoration(
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
      child: Column(
        children: [
          // Barra de búsqueda
          Container(
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
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Botones de filtro
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterButton(
                  icon: Icons.directions_bus,
                  label: 'Tipo de transporte',
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildFilterButton(
                  icon: Icons.calendar_today,
                  label: 'Fecha',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.white,
        border: Border.all(
          color: isDark ? AppColors.slate600 : AppColors.slate300,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: isDark ? AppColors.brown : AppColors.brown),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.brown : AppColors.brown,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_drop_down, size: 20, color: isDark ? AppColors.brown : AppColors.brown),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
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

        // Acordeón 1 - Con detalles completos
        _buildRouteAccordion(
          icon: Icons.directions_bus,
          title: 'Ruta 5 - Metro Chapultepec',
          frequency: 'Frecuencia: 10-15 min',
          price: '\$6.00 MXN',
          hasDetails: true,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // Acordeón 2 - Sin detalles
        _buildRouteAccordion(
          icon: Icons.directions_bus,
          title: 'Ruta 12 - Auditorio Nacional',
          frequency: 'Frecuencia: 15-20 min',
          hasDetails: false,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // Acordeón 3 - Sin detalles
        _buildRouteAccordion(
          icon: Icons.airport_shuttle,
          title: 'Combi 3A - Santa Fe',
          frequency: 'Frecuencia: 5-10 min',
          hasDetails: false,
          isDark: isDark,
        ),
        const SizedBox(height: 24),

        // Estado vacío
        _buildEmptyState(isDark),
      ],
    );
  }

  Widget _buildRouteAccordion({
    required IconData icon,
    required String title,
    required String frequency,
    String? price,
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
                  ? _buildRouteDetails(isDark)
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

  Widget _buildRouteDetails(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarifas
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
                    '\$6.00 MXN',
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

        // Grid de tarifas
        _buildPriceRow('Tarifa General:', '\$6.00', isDark),
        const SizedBox(height: 8),
        _buildPriceRow('Tarifa Estudiante:', '\$4.50', isDark),
        const SizedBox(height: 16),

        // Horarios
        Text(
          'Horarios (Lunes a Viernes)',
          style: AppTextStyles.h3.copyWith(
            color: isDark ? AppColors.slate100 : AppColors.brown,
          ),
        ),
        const SizedBox(height: 12),

        // Tabla de horarios
        _buildScheduleTable(isDark),
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

  Widget _buildScheduleTable(bool isDark) {
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
                    'SALIDA',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.brown.withOpacity(0.7)
                          : AppColors.brown.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'LLEGADA (APROX.)',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.brown.withOpacity(0.7)
                          : AppColors.brown.withOpacity(0.7),
                      fontSize: 10,
                    ),
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
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Rows
          _buildScheduleRow('05:30 AM', '06:15 AM', '10 min', isDark, true),
          _buildScheduleRow('12:00 PM', '12:45 PM', '15 min', isDark, true),
          _buildScheduleRow('10:00 PM', '10:45 PM', '20 min', isDark, false),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(
      String departure,
      String arrival,
      String frequency,
      bool isDark,
      bool hasBorder,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: hasBorder
            ? Border(
          bottom: BorderSide(
            color: isDark ? AppColors.slate600 : AppColors.slate300,
          ),
        )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              departure,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.slate100 : AppColors.brown,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              arrival,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.brown.withOpacity(0.9)
                    : AppColors.brown.withOpacity(0.9),
              ),
            ),
          ),
          Expanded(
            child: Text(
              frequency,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.brown.withOpacity(0.9)
                    : AppColors.brown.withOpacity(0.9),
              ),
              textAlign: TextAlign.right,
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
              onTap: () {
                // Ya estamos en Horarios
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