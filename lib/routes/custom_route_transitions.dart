// lib/routes/custom_route_transitions.dart
import 'package:flutter/material.dart';

/// Classe utilitaire contenant toutes les animations de transition de page personnalisées
class CustomRouteTransitions {
  /// Transition avec effet de grossissement
  static PageRouteBuilder sizeRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => 
        Align(
          child: SizeTransition(
            sizeFactor: animation,
            child: child,
          ),
        ),
    );
  }

  /// Transition avec effet de fondu
  static PageRouteBuilder fadeRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => 
        FadeTransition(
          opacity: animation,
          child: child,
        ),
    );
  }

  /// Transition avec effet d'échelle
  static PageRouteBuilder scaleRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.fastOutSlowIn,
    double beginScale = 0.0,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => 
        ScaleTransition(
          scale: Tween<double>(
            begin: beginScale,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: curve,
            ),
          ),
          child: child,
        ),
    );
  }

  /// Transition avec glissement de la droite
  static PageRouteBuilder slideRightRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => 
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: curve,
            ),
          ),
          child: child,
        ),
    );
  }
  
  /// Transition avec glissement de la gauche
  static PageRouteBuilder slideLeftRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => 
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: curve,
            ),
          ),
          child: child,
        ),
    );
  }
  
  /// Transition avec glissement du bas
  static PageRouteBuilder slideUpRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => 
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: curve,
            ),
          ),
          child: child,
        ),
    );
  }

  /// Transition avec rotation
  static PageRouteBuilder rotationRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => 
        RotationTransition(
          turns: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: curve,
            ),
          ),
          child: child,
        ),
    );
  }
  
  /// Transition combinant un fondu et un effet d'échelle
  static PageRouteBuilder fadeScaleRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutQuad,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Animation<double> fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(fadeAnimation),
            child: child,
          ),
        );
      },
    );
  }
}