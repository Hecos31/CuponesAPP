import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta Oficial Zello (extraída de zello (1).svg)
  static const Color primaryColor = Color(0xFF4B1484);
  static const Color primaryMid = Color(0xFF3B0D6F);
  static const Color primaryDeep = Color(0xFF210543);
  static const Color primarySoft = Color(0xFFEEE8F7);
  static const Color accentColor = Color(0xFFFF9312);
  static const Color accentBright = Color(0xFFFFA81E);
  static const Color accentDeep = Color(0xFFFF7A00);
  static const Color accentSoft = Color(0xFFFFF3E0);
  static const Color backgroundColor = Color(0xFFF4F1FA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color darkInk = Color(0xFF1D0C34);
  static const Color mutedSlate = Color(0xFF685F7D);
  static const Color successColor = Color(0xFF10B981);
  static const Color dangerColor = Color(0xFFEF4444);

  // Gradientes modernos de la marca Zello
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5D1BA3),
      Color(0xFF4B1484),
      Color(0xFF3B0D6F),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFA81E),
      Color(0xFFFF9312),
      Color(0xFFFF7A00),
    ],
  );

  static const LinearGradient darkHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF210543),
      Color(0xFF3B0D6F),
      Color(0xFF4B1484),
    ],
  );

  static const LinearGradient pageBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF6F2FC),
      Color(0xFFEDE6F8),
      Color(0xFFFDFBFF),
    ],
  );

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: dangerColor,
        brightness: Brightness.light,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: darkInk,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: darkInk,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: darkInk,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: darkInk,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: darkInk,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: mutedSlate,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkInk),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: darkInk,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          side: BorderSide(
            color: primaryColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withValues(alpha: 0.35), width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: const TextStyle(color: mutedSlate, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: mutedSlate.withValues(alpha: 0.65), fontSize: 14),
        prefixIconColor: primaryColor,
        suffixIconColor: mutedSlate,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dangerColor, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkInk,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: primaryColor.withValues(alpha: 0.15)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: primaryColor.withValues(alpha: 0.08),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
