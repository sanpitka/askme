import 'package:flutter/material.dart';
import 'pages/intro_page.dart';
import 'utils/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Golden yellow-based color scheme using AppColors
        primarySwatch: AppColors.askyYellowSwatch,
        primaryColor: AppColors.askyYellow,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: AppColors.askyYellowSwatch,
        ).copyWith(
          secondary: AppColors.askyYellowLight,
          tertiary: AppColors.askyYellowDark,
          surface: AppColors.surface,
          onPrimary: AppColors.onAskyYellow,
          onSecondary: AppColors.textMedium,
          onSurface: AppColors.textDark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.askyYellow,
          foregroundColor: AppColors.onAskyYellow,
          elevation: 2,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.askyYellow,
          foregroundColor: AppColors.onAskyYellow,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.askyYellow,
            foregroundColor: AppColors.onAskyYellow,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2,
        ),
      ),
      home: const IntroPage(),
    );
  }
}