import 'package:flutter/material.dart';
import '../../shared/controllers/auth_controller.dart';
import '../../styles/app_styles.dart';
import 'driver_route_selector_view.dart';

/// Pantalla de login para conductores
///
/// Solo permite acceso a usuarios con credenciales de conductor
/// asignadas por la empresa
class DriverLoginView extends StatefulWidget {
  const DriverLoginView({super.key});

  @override
  State<DriverLoginView> createState() => _DriverLoginViewState();
}

class _DriverLoginViewState extends State<DriverLoginView> {
  final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Por favor completa todos los campos', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authController.loginDriver(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result != null && mounted) {
        _showSnackBar('¡Bienvenido, conductor!', Colors.green);

        // Navegar a la selección de ruta
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DriverRouteSelectorView(),
          ),
        );
      } else {
        _showSnackBar(
          'Credenciales inválidas o no tienes permisos de conductor',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.slate100 : AppColors.slate800,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícono de conductor
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    size: 50,
                    color: AppColors.gold,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Título
              Text(
                'Portal de Conductores',
                style: AppTextStyles.h1.copyWith(
                  color: isDark ? AppColors.slate100 : AppColors.slate800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa con tus credenciales asignadas',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.slate400 : AppColors.slate600,
                ),
              ),

              const SizedBox(height: 40),

              // Alerta informativa
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.gold,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Solo personal autorizado puede acceder',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.slate200 : AppColors.slate800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Formulario
              _buildTextField(
                controller: _emailController,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _passwordController,
                label: 'Contraseña',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                isDark: isDark,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.slate400,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Botón de login
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.slate800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.slate800,
                      strokeWidth: 2,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.login,
                        color: AppColors.slate800,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Iniciar Sesión',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.slate800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Información de contacto
              Center(
                child: Column(
                  children: [
                    Text(
                      '¿Problemas para acceder?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.slate400 : AppColors.slate600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        // Aquí podrías agregar un diálogo o pantalla de ayuda
                        _showSnackBar(
                          'Contacta al administrador del sistema',
                          AppColors.gold,
                        );
                      },
                      child: Text(
                        'Contactar soporte',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.slate600 : AppColors.slate300,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.slate100 : AppColors.slate800,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.slate400,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.slate400,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}