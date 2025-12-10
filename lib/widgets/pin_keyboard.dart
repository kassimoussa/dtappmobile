// lib/widgets/pin_keyboard.dart
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';

/// Clavier numérique pour saisie de PIN
///
/// Affiche un clavier de 0 à 9 avec un bouton effacer
/// Appelle onNumberPressed pour chaque chiffre pressé
/// Appelle onDeletePressed quand le bouton effacer est pressé
class PinKeyboard extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDeletePressed;

  const PinKeyboard({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lignes 1-2-3, 4-5-6, 7-8-9
        for (int row = 0; row < 3; row++)
          Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveSize.getHeight(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int col = 1; col <= 3; col++)
                  _buildNumberButton(
                    context,
                    (row * 3 + col).toString(),
                  ),
              ],
            ),
          ),

        // Ligne avec 0 et effacer
        Padding(
          padding: EdgeInsets.only(
            bottom: ResponsiveSize.getHeight(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Espace vide à gauche
              SizedBox(
                width: ResponsiveSize.getWidth(80),
                height: ResponsiveSize.getHeight(80),
              ),

              // Bouton 0
              _buildNumberButton(context, '0'),

              // Bouton effacer
              _buildDeleteButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberButton(BuildContext context, String number) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onNumberPressed(number),
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(40),
        ),
        child: Container(
          width: ResponsiveSize.getWidth(80),
          height: ResponsiveSize.getHeight(80),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(28),
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDeletePressed,
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(40),
        ),
        child: Container(
          width: ResponsiveSize.getWidth(80),
          height: ResponsiveSize.getHeight(80),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: ResponsiveSize.getWidth(28),
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
