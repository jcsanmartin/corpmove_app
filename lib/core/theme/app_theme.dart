import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ──────────────────────────────────────────────
///  Design tokens — CorpMove Premium Light Theme
/// ──────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color scaffoldLight = Color(0xFF121212); // Ahora es oscuro
  static const Color surfaceLight = Color(0xFF1E1E1E);
  static const Color cardLight = Color(0xFF1E1E1E);
  static const Color cardElevated = Color(0xFF252525);

  // Accent
  static const Color accentLime = Color(0xFFC8E600);
  static const Color accentLimeDark = Color(0xFF9AB500);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE0E0E0);
  static const Color textMuted = Color(0xFFA0A0A0);
  static const Color textOnAccent = Color(0xFF121212);

  // Status
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Corporate toggle
  static const Color corporateGreen = Color(0xFF00C853);
  static const Color personalBlue = Color(0xFF007AFF);

  // Borders
  static const Color borderSubtle = Color(0xFF333333);
  static const Color borderAccent = Color(0xFF4A4A4A);

  // Map overlay
  static const Color mapOverlayTop = Color(0x80121212);
  static const Color mapOverlayBottom = Color(0xCC121212);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.scaffoldLight,
      primaryColor: AppColors.accentLime,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentLime,
        secondary: AppColors.accentLimeDark,
        surface: AppColors.surfaceLight,
        onPrimary: AppColors.textOnAccent,
        onSecondary: AppColors.textOnAccent,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffoldLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentLime,
          foregroundColor: AppColors.textOnAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderAccent),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.textPrimary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(color: AppColors.surfaceLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: AppColors.borderSubtle,
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surfaceLight,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnAccent,
      ),
    );
  }
}

/// Decoración reutilizable para tarjetas premium
class AppDecorations {
  AppDecorations._();

  /// Tarjeta con borde sutil y fondo blanco
  static BoxDecoration get card => BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      );

  /// Tarjeta con elevación y sombra muy suave
  static BoxDecoration get cardElevated => BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  /// Bottom sheet style con sombra suave
  static BoxDecoration get bottomSheet => BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: const Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      );
}
