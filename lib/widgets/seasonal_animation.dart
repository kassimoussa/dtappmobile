// lib/widgets/seasonal_animation.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Décor animé (Lottie) posé dans un conteneur parent, sans jamais intercepter
/// les touches.
///
/// À placer dans un `Stack`, par exemple via `Positioned.fill`. La position et
/// la taille sont relatives au parent, pas en pixels, pour suivre les différents
/// écrans : [alignment] est l'`Alignment` de Flutter (de -1 à 1) et
/// [widthFraction] la part de la largeur du parent occupée par l'animation.
class SeasonalAnimation extends StatelessWidget {
  const SeasonalAnimation({
    super.key,
    required this.asset,
    this.alignment = Alignment.center,
    this.widthFraction = 0.3,
    this.repeat = true,
  }) : assert(widthFraction > 0 && widthFraction <= 1);

  final String asset;
  final Alignment alignment;
  final double widthFraction;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: alignment,
            child: Lottie.asset(
              asset,
              width: constraints.maxWidth * widthFraction,
              fit: BoxFit.contain,
              repeat: repeat,
              // Décor : figé sur la première image si l'utilisateur a réduit
              // les animations dans les réglages système.
              animate: !MediaQuery.disableAnimationsOf(context),
              // Un fichier introuvable ou invalide ne doit jamais gêner l'écran.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
