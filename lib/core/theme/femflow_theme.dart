import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'FemLyra_colors.dart';

class FemLyraTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: FemLyraColors.primary,
        secondary: FemLyraColors.deepRose,
        surface: FemLyraColors.white,
        error: FemLyraColors.period,
        onPrimary: FemLyraColors.white,
        onSecondary: FemLyraColors.white,
        onSurface: FemLyraColors.textPrimary,
      ),
      scaffoldBackgroundColor: FemLyraColors.background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          color: FemLyraColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.inter(
          color: FemLyraColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.inter(
          color: FemLyraColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: FemLyraColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          color: FemLyraColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          color: FemLyraColors.textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: FemLyraColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: FemLyraColors.textPrimary),
        titleTextStyle: TextStyle(
          color: FemLyraColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FemLyraColors.primary,
          foregroundColor: FemLyraColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: FemLyraColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: FemLyraColors.border),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: FemLyraColors.white,
        selectedItemColor: FemLyraColors.primary,
        unselectedItemColor: FemLyraColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }
}
