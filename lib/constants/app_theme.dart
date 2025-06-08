// lib/constants/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs principales
  static const Color dtBlue = Color(0xFF002464);
  static const Color dtBlue2 = Color(0xFF003B7F);
  static const Color dtYellow = Color(0xFFF8C02C);
  
  // Couleurs secondaires
  static const Color backgroundGrey = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  
  // Dimensions de base (adaptées dynamiquement selon l'écran)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // Border radius
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;
  
  // Styles de texte (les tailles seront adaptées via ScreenUtil)
  static TextStyle get headingStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: dtBlue,
  );
  
  static TextStyle get subheadingStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: dtBlue,
  );
  
  static TextStyle get bodyStyle => const TextStyle(
    fontSize: 16,
    color: textPrimary,
  );
  
  // Styles de boutons
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: dtBlue,
    foregroundColor: dtYellow,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
  );
  
  // Décorations
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [dtBlue, dtBlue2],
  );
}