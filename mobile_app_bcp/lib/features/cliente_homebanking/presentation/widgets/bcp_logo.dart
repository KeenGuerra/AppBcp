import 'package:flutter/material.dart';

class BcpLogo extends StatelessWidget {
  final double fontSize;
  final double paddingHorizontal;
  final double paddingVertical;
  final bool isDarkBackground;

  const BcpLogo({
    super.key,
    this.fontSize = 16.0,
    this.paddingHorizontal = 10.0,
    this.paddingVertical = 5.0,
    this.isDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B00), // BCP Orange
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'BCP',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
