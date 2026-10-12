// lib/widgets/staggered_text.dart
import 'package:flutter/material.dart';

/// Affiche [text] lettre par lettre : chaque caractère apparaît en fondu en
/// remontant légèrement, avec un petit décalage sur le précédent.
///
/// [progress] (de 0 à 1) pilote toute l'animation ; c'est au parent de le
/// fournir, par exemple `controller.value` dans un `AnimatedBuilder`.
/// [letterDuration] est la part de [progress] dont dispose chaque lettre : plus
/// elle est grande, plus les lettres se chevauchent.
class StaggeredText extends StatelessWidget {
  const StaggeredText({
    super.key,
    required this.text,
    required this.progress,
    required this.style,
    this.letterDuration = 0.4,
    this.rise = 10,
  }) : assert(letterDuration > 0 && letterDuration <= 1);

  final String text;
  final double progress;
  final TextStyle style;
  final double letterDuration;

  /// Distance (en pixels logiques) que chaque lettre parcourt en remontant.
  final double rise;

  @override
  Widget build(BuildContext context) {
    final chars = text.characters.toList();
    final last = chars.length - 1;
    final step = last > 0 ? (1 - letterDuration) / last : 0.0;

    // Les lecteurs d'écran lisent le texte entier, pas lettre par lettre.
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < chars.length; i++)
            _letter(chars[i], begin: i * step),
        ],
      ),
    );
  }

  Widget _letter(String char, {required double begin}) {
    final t = Interval(
      begin,
      begin + letterDuration,
      curve: Curves.easeOut,
    ).transform(progress);

    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * rise),
        child: Text(char, style: style),
      ),
    );
  }
}
