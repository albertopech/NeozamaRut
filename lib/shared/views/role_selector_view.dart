import 'package:flutter/material.dart';
import '../../styles/app_styles.dart';
import '../../user/views/user_login_view.dart';
import '../../conductor/views/driver_login_view.dart';

/// Pantalla para seleccionar el tipo de usuario
///
/// Permite elegir entre:
/// - Usuario normal (puede registrarse)
/// - Conductor (requiere credenciales pre-asignadas)
class RoleSelectorView extends StatelessWidget {
  const RoleSelectorView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),

              // Logo o título
              Icon(
                Icons.directions_bus,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),

              Text(
                'Transporte Público',
                style: AppTextStyles.h1.copyWith(
                  color: isDark ? AppColors.slate100 : AppColors.slate800,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Selecciona cómo deseas continuar',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.slate400 : AppColors.slate600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Botón Usuario
              _buildRoleCard(
                context: context,
                icon: Icons.person,
                title: 'Soy Usuario',
                description: 'Consulta rutas, horarios y ubicación de autobuses',
                color: AppColors.primary,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserLoginView(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Botón Conductor
              _buildRoleCard(
                context: context,
                icon: Icons.local_shipping,
                title: 'Soy Conductor',
                description: 'Inicia tu ruta y comparte tu ubicación en tiempo real',
                color: AppColors.gold,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverLoginView(),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.slate800.withOpacity(0.5)
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Los conductores requieren credenciales asignadas por la empresa',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.slate400 : AppColors.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate800 : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppColors.slate100 : AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}