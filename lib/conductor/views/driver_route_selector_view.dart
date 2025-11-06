import 'package:flutter/material.dart';
import '../../styles/app_styles.dart';

/// Pantalla de selección de ruta para conductores
///
/// Permite al conductor seleccionar qué ruta va a conducir
/// antes de iniciar el tracking
class DriverRouteSelectorView extends StatelessWidget {
  const DriverRouteSelectorView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Selecciona tu ruta',
          style: AppTextStyles.h2.copyWith(
            color: isDark ? AppColors.slate100 : AppColors.slate800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.route,
                size: 80,
                color: AppColors.gold,
              ),
              const SizedBox(height: 24),
              Text(
                'Módulo de Conductor',
                style: AppTextStyles.h1.copyWith(
                  color: isDark ? AppColors.slate100 : AppColors.slate800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'En desarrollo',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.slate400 : AppColors.slate600,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '✅ Login exitoso\n\nPróximamente podrás:\n• Seleccionar tu ruta\n• Iniciar tracking GPS\n• Compartir ubicación en tiempo real',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.slate200 : AppColors.slate800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}