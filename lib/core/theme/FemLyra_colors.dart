import 'package:femlyra/core/config/brand_config.dart';
import 'package:flutter/material.dart';
import '../config/brand_config.dart';

class FemLyraColors {
  // Dynamic Brand Colors from BrandConfig
  static const Color primary = BrandConfig.primaryColor;
  static const Color deepRose = BrandConfig.secondaryColor;
  static const Color blushMist = BrandConfig.cardColor;
  static const Color warmWhite = BrandConfig.backgroundColor;

  // Status Colors
  static const Color period = BrandConfig.periodColor;
  static const Color fertileWindow = BrandConfig.fertileColor;
  static const Color ovulation = BrandConfig.ovulationColor;
  static const Color pmsCaution = Color(0xFFF4A261);
  static const Color aiWellness = BrandConfig.accentColor;

  // Text Colors
  static const Color textPrimary = BrandConfig.textPrimary;
  static const Color textSecondary = BrandConfig.textSecondary;
  static const Color textMuted = BrandConfig.textMuted;

  // UI Elements
  static const Color border = BrandConfig.borderColor;
  static const Color background = BrandConfig.backgroundColor;
  static const Color white = Colors.white;

  // Premium Palette
  static const Color softBlush = Color(0xFFFFF0F5);
  static const Color lavender = Color(0xFFE6E6FA);
  static const Color mint = Color(0xFFE0FFF0);
  static const Color rosePill = Color(0xFFFFC0CB);
  static const Color fertilePill = Color(0xFFE0F2F1);
}
