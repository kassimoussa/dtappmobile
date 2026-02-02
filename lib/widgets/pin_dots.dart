// lib/widgets/pin_dots.dart
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';

/// Affiche les 4 cercles pour visualiser la saisie du PIN
///
/// Les cercles remplis représentent les chiffres saisis
/// Les cercles vides représentent les chiffres restants
class PinDots extends StatelessWidget {
  final int pinLength;
  final int maxLength;
  final Color activeColor;
  final Color inactiveColor;

  const PinDots({
    super.key,
    required this.pinLength,
    this.maxLength = 4,
    this.activeColor = AppTheme.dtBlue,
    this.inactiveColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    // Ajuster la taille en fonction du nombre de cercles (4 ou 6)
    final bool isOtp = maxLength == 6;
    final double dotSize = isOtp ? 40.0 : 50.0;
    final double spacing = isOtp ? 4.0 : 8.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        maxLength,
        (index) => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(spacing),
          ),
          child: _buildDot(context, index < pinLength, dotSize),
        ),
      ),
    );
  }

  Widget _buildDot(BuildContext context, bool isFilled, double size) {
    return Container(
      width: ResponsiveSize.getWidth(size),
      height: ResponsiveSize.getHeight(size),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isFilled ? activeColor : inactiveColor,
          width: 2,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isFilled ? ResponsiveSize.getWidth(12) : 0,
          height: isFilled ? ResponsiveSize.getHeight(12) : 0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activeColor,
          ),
        ),
      ),
    );
  }
}
