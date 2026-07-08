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

  // Couleurs pré-calculées — évite les allocations withOpacity() dans les build()
  // dtBlue (#0D47A1) à différentes opacités
  static const Color dtBlueO02 = Color(0x050D47A1);
  static const Color dtBlueO05 = Color(0x0D0D47A1);
  static const Color dtBlueO08 = Color(0x140D47A1);
  static const Color dtBlueO10 = Color(0x1A0D47A1);
  static const Color dtBlueO15 = Color(0x260D47A1);
  static const Color dtBlueO20 = Color(0x330D47A1);
  static const Color dtBlueO30 = Color(0x4D0D47A1);
  static const Color dtBlueO35 = Color(0x590D47A1);
  static const Color dtBlueO50 = Color(0x800D47A1);
  // dtYellow (#FFCA28) à différentes opacités
  static const Color dtYellowO10 = Color(0x1AFFCA28);
  static const Color dtYellowO30 = Color(0x4DFFCA28);
  static const Color dtYellowO50 = Color(0x80FFCA28);
  // Blanc/Noir pré-calculés
  static const Color white50 = Color(0x80FFFFFF);
  static const Color white95 = Color(0xF2FFFFFF);
  static const Color black04 = Color(0x0A000000);
  static const Color black15 = Color(0x26000000);
  
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
  
  // Styles de boutons — préférer le widget DtButton (lib/widgets/dt_button.dart)
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: dtBlue,
    foregroundColor: Colors.white,
    elevation: 0, // Flat premium look
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  );
  
  // Décorations
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: const [
      BoxShadow( // Ombre beaucoup plus douce et diffuse (premium)
        color: black04,
        blurRadius: 30,
        spreadRadius: 2,
        offset: Offset(0, 10),
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