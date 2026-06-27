import 'package:flutter/material.dart';

class FuerzaVentasTheme {
  // Colores Oficiales BCP
  static const Color bcpBlue = Color(0xFF002F6C); // Azul BCP
  static const Color bcpOrange = Color(0xFFFF7900); // Naranja BCP
  static const Color bcpCyan = Color(0xFF00A9E0); // Celeste BCP
  
  // Fondos Premium (Obsidian Blue)
  static const Color darkBackground = Color(0xFF060B1A); // Obsidian profundo
  static const Color cardDark = Color(0xFF0E172E); // obsidian profundo para tarjetas
  static const Color inputFieldColor = Color(0xFF142247); // Inputs mejor integrados

  // Colores de Acento y Neón
  static const Color neonOrange = Color(0xFFFF9E40);
  static const Color neonCyan = Color(0xFF33CFFF);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonRed = Color(0xFFFF3838);

  // Gradientes oficiales y premium
  static const Gradient bcpGradient = LinearGradient(
    colors: [
      Color(0xFF001E4D), // Azul BCP profundo
      Color(0xFF060B1A), // Obsidian Background
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient bcpOrangeGradient = LinearGradient(
    colors: [
      Color(0xFFFF7900), // Naranja BCP
      Color(0xFFFF9E40), // Naranja neón brillante
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Gradient bcpCyanGradient = LinearGradient(
    colors: [
      Color(0xFF00A9E0), // Celeste BCP
      Color(0xFF33CFFF), // Celeste neón
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Gradient glassBorderGradient = LinearGradient(
    colors: [
      Colors.white38,
      Colors.white10,
      Colors.transparent,
      Colors.white10,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Decoración de Vidrio (Glassmorphism) Reutilizable
  static BoxDecoration glassDecoration({
    Color color = cardDark,
    double opacity = 0.75,
    double borderRadius = 24.0,
    Color borderColor = Colors.white,
    double borderOpacity = 0.06,
  }) {
    return BoxDecoration(
      color: color.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor.withOpacity(borderOpacity),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // Sombra con Brillo (Neon Glow)
  static List<BoxShadow> neonGlowShadow({
    required Color color,
    double opacity = 0.3,
    double blurRadius = 12.0,
    Offset offset = const Offset(0, 4),
  }) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: blurRadius,
        spreadRadius: 1,
        offset: offset,
      ),
    ];
  }
}
