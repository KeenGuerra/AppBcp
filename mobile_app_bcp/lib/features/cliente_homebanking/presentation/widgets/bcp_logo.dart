import 'package:flutter/material.dart';

class BcpLogo extends StatelessWidget {
  final double fontSize;
  final double paddingHorizontal;
  final double paddingVertical;
  final bool isDarkBackground;
  final bool isCircle;
  final double? size;

  const BcpLogo({
    super.key,
    this.fontSize = 16.0,
    this.paddingHorizontal = 10.0,
    this.paddingVertical = 5.0,
    this.isDarkBackground = false,
    this.isCircle = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (isCircle) {
      final double s = size ?? (fontSize * 2.8);
      return Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B00),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'BCP',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              letterSpacing: 1.0,
            ),
          ),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B00),
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
