import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'FemLyra_colors.dart';

class FemFlowTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: FemFlowColors.primary,
        secondary: FemFlowColors.deepRose,
        surface: FemFlowColors.white,
        error: FemFlowColors.period,
        onPrimary: FemFlowColors.white,
        onSecondary: FemFlowColors.white,
        onSurface: FemFlowColors.textPrimary,
      ),
      scaffoldBackgroundColor: FemFlowColors.background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          color: FemFlowColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.inter(
          color: FemFlowColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.inter(
          color: FemFlowColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: FemFlowColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          color: FemFlowColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          color: FemFlowColors.textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: FemFlowColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: FemFlowColors.textPrimary),
        titleTextStyle: TextStyle(
          color: FemFlowColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FemFlowColors.primary,
          foregroundColor: FemFlowColors.white,
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
        color: FemFlowColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: FemFlowColors.border),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: FemFlowColors.white,
        selectedItemColor: FemFlowColors.primary,
        unselectedItemColor: FemFlowColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }
}
