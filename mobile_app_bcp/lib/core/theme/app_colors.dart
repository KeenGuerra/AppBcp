// app_colors.dart — Colores unificados del sistema BCP
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Colores principales BCP
  static const Color primaryBlue = Color(0xFF002A8D);
  static const Color primaryOrange = Color(0xFFFF7800);
  static const Color white = Color(0xFFFFFFFF);

  // Background
  static const Color backgroundLight = Color(0xFFF5F6FA);
  static const Color backgroundDark = Color(0xFF0D1628);

  // Texto
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textMuted = Color(0xFF8B949E);

  // Estado
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF9A825);
  static const Color info = Color(0xFF00A3E0);

  // BCP Branding
  static const Color bcpBlue = Color(0xFF002A8D);
  static const Color bcpOrange = Color(0xFFFF7800);
  static const Color bcpNavy = Color(0xFF0D1628);
  static const Color bcpNavyLight = Color(0xFF1A2744);

  // Card backgrounds
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE8ECF1);

  // Buro statuses
  static const Color buroNormal = Color(0xFF2E7D32);
  static const Color buroCpp = Color(0xFFF9A825);
  static const Color buroDeficiente = Color(0xFFFF9800);
  static const Color buroDudoso = Color(0xFFE53E3E);
  static const Color buroPerdida = Color(0xFF9B1B1B);
}
