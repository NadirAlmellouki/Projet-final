import 'package:flutter/material.dart';

/// Palette StudySync — indigo électrique + menthe, cohérente sur toute l'app.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF6C5CE7);
  static const primaryLight = Color(0xFFA29BFE);
  static const primaryDark = Color(0xFF4E44C9);
  static const primaryTint = Color(0xFFF0EEFF);
  static const primarySoft = Color(0xFFE4E0FF);

  static const accent = Color(0xFF00CEC9);
  static const accentLight = Color(0xFF81ECEC);
  static const accentTint = Color(0xFFE0FFFE);
  static const accentDark = Color(0xFF00A8A3);

  static const success = Color(0xFF00B894);
  static const successTint = Color(0xFFE8FFF8);

  static const warning = Color(0xFFFDCB6E);
  static const warningTint = Color(0xFFFFF8E8);

  static const error = Color(0xFFFF6B6B);
  static const errorTint = Color(0xFFFFF0F0);

  static const text1 = Color(0xFF2D3436);
  static const text2 = Color(0xFF636E72);
  static const text3 = Color(0xFFB2BEC3);

  static const border = Color(0xFFDFE6E9);
  static const surface = Color(0xFFF5F6FA);
  static const surfaceElevated = Color(0xFFFFFFFF);

  static const white = Color(0xFFFFFFFF);
  static const gradientStart = Color(0xFF6C5CE7);
  static const gradientEnd = Color(0xFF2D1B69);

  static const cardShadow = Color(0x142D3436);

  // Carte
  static const mapOverlay = Color(0xE6FFFFFF);
  static const mapMarkerOpen = Color(0xFF6C5CE7);
  static const mapMarkerJoined = Color(0xFF00CEC9);
  static const mapUserDot = Color(0xFF0984E3);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF6), Color(0xFF00CEC9)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primary, primaryLight],
  );

  static const LinearGradient chatBubbleMine = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF6)],
  );

  static const List<Color> statAccents = [
    primary,
    accent,
    success,
    Color(0xFFFD79A8),
    Color(0xFF0984E3),
  ];
}
