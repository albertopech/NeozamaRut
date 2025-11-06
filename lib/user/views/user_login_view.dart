import 'package:flutter/material.dart';
import '../../shared/controllers/auth_controller.dart';
import '../../styles/app_styles.dart';
import 'map_view.dart';
import '../../conductor/views/driver_map_view.dart';
import '../../models/supabase_service.dart';

class UserLoginView extends StatefulWidget {
  const UserLoginView({super.key});

  @override
  State<UserLoginView> createState() => _UserLoginViewState();
}

class _UserLoginViewState extends State<UserLoginView> {
  final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLogin = true; // true = login, false = registro
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Nuevo método para obtener la ruta asignada al conductor desde Supabase
  Future<Map<String, dynamic>?> _fetchDriverRoute(String userId) async {
    try {
      final response = await SupabaseService.instance.client
          .from('user_subscriptions')
          .select('route_id, routes(*)') // Obtener ruta por suscripción (join)
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (response != null && response['routes'] != null) {
        // Retorna el mapa de detalles de la ruta
        return response['routes'] as Map<String, dynamic>;
      }
      return null;
    } catch (error) {
      print('❌ Error al obtener la ruta del conductor: $error');
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Por favor completa todos los campos', Colors.orange);
      return;
    }

    if (!_isLogin && _nameController.text.isEmpty) {
      _showSnackBar('Por favor ingresa tu nombre', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? result;

      if (_isLogin) {
        // ⭐ Login con detección automática de rol
        result = await _authController.loginUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (result != null && mounted) {
          // Obtener el rol del usuario
          final role = result['role'] ?? 'user';

          print('✅ Login exitoso - Rol detectado: $role');

          // Redirigir según el rol
          if (role == 'driver') {
            // Es conductor. Obtenemos la ruta de la DB.
            final userId = _authController.getCurrentUser()?.id;

            if (userId == null) {
              // Esto no debería pasar, pero es una protección
              _showSnackBar('Error: Usuario no autenticado tras login.', Colors.red);
              await _authController.signOut();
              return;
            }

            _showSnackBar('¡Bienvenido, conductor! Cargando ruta...', Colors.green);

            final driverRoute = await _fetchDriverRoute(userId);

            if (mounted) {
              if (driverRoute != null) {
                // Ruta encontrada: Navegar directamente a DriverMapView
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverMapView(route: driverRoute),
                  ),
                );
              } else {
                // Ruta NO encontrada: Mostrar error y evitar la navegación
                _showSnackBar('Error: No se encontró una ruta asignada. Contacta a soporte.', Colors.red);
                // Cerrar sesión ya que el conductor no puede operar sin ruta
                await _authController.signOut();
              }
            }
          } else {
            // Es usuario normal
            _showSnackBar('¡Bienvenido!', Colors.green);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MapView(),
              ),
            );
          }
        } else {
          _showSnackBar('Credenciales inválidas', Colors.red);
        }
      } else {
        // Registro (siempre crea usuarios normales)
        result = await _authController.registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );

        if (result != null && mounted) {
          _showSnackBar('¡Cuenta creada exitosamente!', Colors.green);

          // Los usuarios registrados van al mapa
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MapView()),
          );
        } else {
          _showSnackBar('Error al crear la cuenta', Colors.red);
        }
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo o ícono de la app
              Center(
                child: Icon(
                  Icons.directions_bus,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Título
              Center(
                child: Text(
                  _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                  style: AppTextStyles.h1.copyWith(
                    color: isDark ? AppColors.slate100 : AppColors.slate800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _isLogin
                      ? 'Usuarios y conductores'
                      : 'Regístrate para empezar',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Formulario
              if (!_isLogin) ...[
                _buildTextField(
                  controller: _nameController,
                  label: 'Nombre completo',
                  icon: Icons.person_outline,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
              ],

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

              // Botón principal
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                      : Text(
                    _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Toggle entre login y registro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin
                        ? '¿No tienes cuenta? '
                        : '¿Ya tienes cuenta? ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _nameController.clear();
                      });
                    },
                    child: Text(
                      _isLogin ? 'Regístrate' : 'Inicia sesión',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Información para conductores
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
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Los conductores usan sus credenciales asignadas para acceder',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.slate200 : AppColors.slate800,
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