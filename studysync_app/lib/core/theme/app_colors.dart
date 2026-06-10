import 'package:flutter/material.dart';

/// Palette StudySync — indigo profond, corail chaud, teal frais.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark = Color(0xFF3730A3);
  static const primaryTint = Color(0xFFEEF2FF);
  static const primarySoft = Color(0xFFE0E7FF);

  static const accent = Color(0xFF0D9488);
  static const accentLight = Color(0xFF2DD4BF);
  static const accentTint = Color(0xFFCCFBF1);

  static const coral = Color(0xFFF97316);
  static const coralTint = Color(0xFFFFF7ED);

  static const success = Color(0xFF059669);
  static const successTint = Color(0xFFECFDF5);

  static const warning = Color(0xFFD97706);
  static const warningTint = Color(0xFFFFFBEB);

  static const error = Color(0xFFDC2626);
  static const errorTint = Color(0xFFFEF2F2);

  static const text1 = Color(0xFF0F172A);
  static const text2 = Color(0xFF475569);
  static const text3 = Color(0xFF94A3B8);

  static const border = Color(0xFFE2E8F0);
  static const surface = Color(0xFFF1F5F9);
  static const surfaceElevated = Color(0xFFFFFFFF);

  static const white = Color(0xFFFFFFFF);
  static const gradientStart = Color(0xFF4F46E5);
  static const gradientEnd = Color(0xFF1E1B4B);

  static const cardShadow = Color(0x140F172A);
  static const navShadow = Color(0x1F4F46E5);

  static const mapOverlay = Color(0xCC0F172A);
  static const mapPinMine = Color(0xFF0D9488);
  static const mapPinOther = Color(0xFF4F46E5);
  static const mapPinJoined = Color(0xFFF97316);

  static const List<Color> statAccents = [
    primary,
    coral,
    accent,
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
  ];

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF0D9488)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient mapHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF0D9488)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primary, primaryLight],
  );

  static const LinearGradient chatMineGradient = LinearGradient(
    colors: [primary, Color(0xFF6366F1)],
  );
}
