// lib/widgets/pin_keyboard.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';

/// Clavier numérique pour saisie de PIN
///
/// Affiche un clavier de 0 à 9 avec un bouton effacer
/// Appelle onNumberPressed pour chaque chiffre pressé
/// Appelle onDeletePressed quand le bouton effacer est pressé
///
/// Les touches s'adaptent à la place que le parent leur donne : placé dans
/// une boîte de hauteur bornée (voir [PinEntryLayout]), le clavier rétrécit
/// pour tenir entièrement au lieu de déborder de l'écran.
class PinKeyboard extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDeletePressed;

  const PinKeyboard({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
  });

  /// Écart entre deux lignes, proportionnel à la taille des touches
  static const double _rowGapRatio = 0.2;

  /// Plus petite touche acceptable (cible tactile Material de 48 dp)
  static const double minButtonSize = 48;

  /// Taille des touches quand la place ne manque pas
  static double get preferredButtonSize =>
      ResponsiveSize.getWidth(80).clamp(64.0, 96.0);

  /// Hauteur occupée par les 4 lignes pour une taille de touche donnée
  static double heightFor(double buttonSize) =>
      buttonSize * (4 + 3 * _rowGapRatio);

  static double get preferredHeight => heightFor(preferredButtonSize);

  static double get minHeight => heightFor(minButtonSize);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var size = preferredButtonSize;
        if (constraints.hasBoundedWidth) {
          // Garder de l'air entre les trois colonnes
          size = math.min(size, constraints.maxWidth / 3 * 0.8);
        }
        if (constraints.hasBoundedHeight) {
          size = math.min(size, constraints.maxHeight / heightFor(1));
        }
        size = math.max(size, minButtonSize);
        final rowGap = size * _rowGapRatio;

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lignes 1-2-3, 4-5-6, 7-8-9
            for (int row = 0; row < 3; row++) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int col = 1; col <= 3; col++)
                    _buildNumberButton((row * 3 + col).toString(), size),
                ],
              ),
              SizedBox(height: rowGap),
            ],

            // Ligne avec 0 et effacer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Espace vide à gauche
                SizedBox.square(dimension: size),

                // Bouton 0
                _buildNumberButton('0', size),

                // Bouton effacer
                _buildKey(
                  size: size,
                  onTap: onDeletePressed,
                  child: Icon(
                    Icons.backspace_outlined,
                    size: size * 0.35,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildNumberButton(String number, double size) {
    return _buildKey(
      size: size,
      onTap: () => onNumberPressed(number),
      child: Text(
        number,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildKey({
    required double size,
    required VoidCallback onTap,
    required Widget child,
  }) {
    // La couleur est portée par le Material (et non par un Container
    // au-dessus de l'InkWell) pour que l'effet d'appui reste visible
    return SizedBox.square(
      dimension: size,
      child: Material(
        color: Colors.grey[200],
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Center(child: child)),
      ),
    );
  }
}
