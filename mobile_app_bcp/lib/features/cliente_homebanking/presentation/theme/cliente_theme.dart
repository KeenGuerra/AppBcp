import 'package:flutter/material.dart';

class ClienteTheme {
  // Colores Oficiales BCP
  static const Color bcpBlue = Color(0xFF002A54); // Azul BCP
  static const Color bcpOrange = Color(0xFFFF6B00); // Naranja BCP
  static const Color bcpLightBlue = Color(0xFF00A3E0); // Celeste BCP
  static const Color bcpBgGrey = Color(0xFFF4F5F8); // Gris claro de fondo
  static const Color bcpTextDark = Color(0xFF1E293B); // Texto oscuro legible
  static const Color bcpTextGrey = Color(0xFF64748B); // Texto secundario
  
  static const Gradient headerGradient = LinearGradient(
    colors: [bcpBlue, Color(0xFF0A3E75)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient orangeButtonGradient = LinearGradient(
    colors: [bcpOrange, Color(0xFFFF8533)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static BoxDecoration cardDecoration({
    Color color = Colors.white,
    double borderRadius = 16.0,
    bool showShadow = true,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }
}
