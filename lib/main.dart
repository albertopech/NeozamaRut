import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'styles/app_styles.dart';
import 'user/views/user_login_view.dart';
import 'models/supabase_service.dart';

void main() async {
  // Asegurar que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // ⭐ INICIALIZAR SUPABASE
  try {
    await SupabaseService.instance.initialize();
    print('✅ Aplicación iniciada correctamente');
  } catch (e) {
    print('❌ Error crítico al iniciar la aplicación: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rutas de Transporte Público',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const UserLoginView(), // ⬅️ Inicia directamente en login de usuario
    );
  }
}