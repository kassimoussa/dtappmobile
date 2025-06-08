// lib/utils/responsive_size.dart
import 'package:flutter/material.dart';

class ResponsiveSize {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  
  static late double _designWidth;
  static late double _designHeight;
  
  // Initialiser avec la taille d'écran de référence (design de base)
  static void init(BuildContext context, {double designWidth = 375, double designHeight = 812}) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    _designWidth = designWidth;
    _designHeight = designHeight;
    
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    
    safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeAreaVertical) / 100;
  }
  
  // Adapter la largeur en fonction de l'écran
  static double getWidth(double designValue) {
    return (designValue / _designWidth) * screenWidth;
  }
  
  // Adapter la hauteur en fonction de l'écran
  static double getHeight(double designValue) {
    return (designValue / _designHeight) * screenHeight;
  }
  
  // Adapter la taille de police en fonction de l'écran
  static double getFontSize(double designValue) {
    double scale = screenWidth < 360 ? 0.75 : screenWidth > 600 ? 1.25 : 1.0;
    return designValue * scale;
  }
  
  // Vérifier si l'appareil est une tablette
  static bool get isTablet => screenWidth > 600;
  
  // Vérifier si l'appareil est un petit téléphone
  static bool get isSmallPhone => screenWidth < 360;
}