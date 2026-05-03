// lib/constants/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Nouvelles Couleurs : Plus claires et vibrantes basées sur le Logo (Bleu et Doré)
  static const Color dtBlue = Color(0xFF0D47A1); // Bleu principal (désormais le bleu profond)
  static const Color dtBlueLight = Color(0xFF1E88E5); // Ancien bleu conservé si besoin
  static const Color dtBlue2 = Color(0xFF1565C0); // Bleu royal doux
  static const Color dtBlueDark = Color(0xFF0D47A1); // Bleu profond mais chaleureux
  static const Color dtYellow = Color(0xFFFFCA28); // Un doré vif, éclatant et clair
  
  // Couleurs secondaires
  static const Color backgroundGrey = Color(0xFFF8F9FE); // Slightly cooler/modern grey
  static const Color textPrimary = Color(0xFF1E293B); // Slate-like modern text color
  static const Color textSecondary = Color(0xFF64748B); 
  
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
  static const TextStyle headingStyle = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: dtBlueDark,
    letterSpacing: -0.5,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: dtBlueDark,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    color: textPrimary,
  );
  
  // Styles de boutons
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: dtBlueDark,
    foregroundColor: dtYellow,
    elevation: 0, // Flat premium look
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
  );
  
  // Décorations
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: [
      BoxShadow( // Ombre beaucoup plus douce et diffuse (premium)
        color: Colors.black.withOpacity(0.04),
        blurRadius: 30,
        spreadRadius: 2,
        offset: const Offset(0, 10),
      ),
    ],
  );
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dtBlueDark, dtBlue2],
  );
}