import 'package:flutter/material.dart';

class AppColors {
  // Colores principales
  static const Color primary = Color(0xFF8C2332); // Morena Red
  static const Color gold = Color(0xFFC6A265); // Gold accent
  static const Color brown = Color(0xFF6F4E37); // Brown/Coffee

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF6F7F8);
  static const Color backgroundDark = Color(0xFF101922);

  // Grises
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);

  // Otros
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

class AppTextStyles {
  // Títulos
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.4,
  );

  // Texto regular
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  // Texto especial
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> cardLarge = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];

  static const List<BoxShadow> icon = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,

    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.gold,
      surface: AppColors.white,
      error: Colors.red,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.slate800,
      elevation: 0,
      centerTitle: true,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.gold,
      surface: AppColors.slate800,
      error: Colors.red,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
    ),
  );
}