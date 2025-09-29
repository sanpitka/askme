import 'package:flutter/material.dart';

/// App color palette
/// Main theme color: #FAB70C (Asky Yellow)
class AppColors {
  // Primary Asky Yellow palette
  static const Color askyYellow = Color(0xFFFAB70C);
  static const Color askyYellowLight = Color.fromARGB(255, 252, 207, 59); // Made darker - between light and main
  static const Color askyYellowDark = Color(0xFFF8A208);
  static const Color askyYellowDarker = Color(0xFFF69906);
  static const Color askyYellowDarkest = Color(0xFFF48902);
  
  // Light tints for backgrounds
  static const Color askyYellowTint50 = Color(0xFFFFFBE7);
  static const Color askyYellowTint100 = Color(0xFFFFF4C4);
  static const Color askyYellowTint200 = Color(0xFFFEED9D);
  static const Color askyYellowTint300 = Color(0xFFFDE676);
  static const Color askyYellowTint400 = Color(0xFFFCDF59);
  
  // Surface colors
  static const Color surface = Color(0xFFFFFBF4);
  static const Color surfaceLight = Color(0xFFFFFBE7);
  
  // Text colors
  static const Color onAskyYellow = Colors.white;
  static const Color textDark = Color(0xFF5D4A0A);
  static const Color textMedium = Color(0xFF8B6914);
  
  // Material color swatch for theme
  static const MaterialColor askyYellowSwatch = MaterialColor(0xFFFAB70C, {
    50: Color(0xFFFFFBE7),
    100: Color(0xFFFFF4C4),
    200: Color(0xFFFEED9D),
    300: Color(0xFFFDE676),
    400: Color(0xFFFCDF59),
    500: Color(0xFFFAB70C),
    600: Color(0xFFF9AF0A),
    700: Color(0xFFF8A208),
    800: Color(0xFFF69906),
    900: Color(0xFFF48902),
  });
}
