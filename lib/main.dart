
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const PondApp());
}

class PondApp extends StatelessWidget {
  const PondApp({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF0B63C6); // slightly brighter blue
    final accent = const Color(0xFF2E7D32);
    final colorScheme = ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: accent);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pond Management',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F9FB),
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
          toolbarHeight: 64,
          titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            // use withAlpha to avoid withOpacity deprecation
            side: BorderSide(color: primary.withAlpha((0.14 * 255).round())),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          // prefer surfaceContainerHighest from the color scheme for input fills
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
        cardColor: Colors.white,
        textTheme: const TextTheme(
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          bodyMedium: TextStyle(fontSize: 14),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
  home: const SplashScreen(),
    );
  }
}

