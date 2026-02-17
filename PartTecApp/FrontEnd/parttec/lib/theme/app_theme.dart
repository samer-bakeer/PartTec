import 'package:flutter/material.dart';

class AppColors {
  // 🎯 Primary Identity (أزرق احترافي عميق)
  static const primary = Color(0xFF1E3A8A);       // Deep Blue
  static const primaryDark = Color(0xFF0F172A);   // Navy
  static const accent = Color(0xFF3B82F6);        // Electric Blue

  // 🌈 Gradient حديث ناعم
  static const bgGradientA = Color(0xFF1E3A8A);
  static const bgGradientB = Color(0xFF2563EB);
  static const bgGradientC = Color(0xFF38BDF8);

  // 🧾 Surfaces
  static const card = Colors.white;
  static const background = Color(0xFFF3F6FB);

  // 📝 Text
  static const text = Color(0xFF111827);
  static const textWeak = Color(0xFF6B7280);

  // 🟦 Chips
  static const chipBg = Colors.white;
  static const chipBorder = Color(0xFFE5E7EB);

  // 🔔 Status
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);
}

class AppSpaces {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class AppImages {
  static const String defaultPart =
      "https://res.cloudinary.com/dzjrgcxwt/image/upload/photo_2025-09-02_07-58-51_e8g6im.jpg";
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: false,
    fontFamily: "Tajawal",
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),

    textTheme: base.textTheme.copyWith(
      bodyMedium: const TextStyle(
        fontSize: 14,
        color: AppColors.text,
        height: 1.4,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.text,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.chipBg,
      side: const BorderSide(color: AppColors.chipBorder),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    ),

    cardTheme: CardTheme(
      color: AppColors.card,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.all(AppSpaces.sm),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.chipBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.chipBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.accent,
          width: 1.5,
        ),
      ),
      labelStyle: const TextStyle(color: AppColors.textWeak),
    ),
  );
}
