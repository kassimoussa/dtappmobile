// lib/widgets/pin_entry_layout.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import 'pin_keyboard.dart';

/// Mise en page commune des écrans de saisie de PIN
///
/// Le clavier est dimensionné d'après la hauteur réellement disponible et
/// reste toujours entièrement visible en bas de l'écran. L'en-tête (titre,
/// cercles, messages) occupe l'espace restant, centré, et ne défile que s'il
/// ne tient pas (petit écran avec un message d'erreur, par exemple).
class PinEntryLayout extends StatelessWidget {
  final List<Widget> header;
  final PinKeyboard keyboard;

  /// Affiché sous le clavier (lien « PIN oublié », par exemple)
  final Widget? footer;

  const PinEntryLayout({
    super.key,
    required this.header,
    required this.keyboard,
    this.footer,
  });

  /// Part maximale de la hauteur disponible réservée au clavier
  static const double _keyboardShare = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardHeight = math.min(
          PinKeyboard.preferredHeight,
          math.max(
            constraints.maxHeight * _keyboardShare,
            PinKeyboard.minHeight,
          ),
        );

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(AppTheme.spacingL),
          ),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, headerConstraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: headerConstraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: header,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: keyboardHeight, child: keyboard),
              if (footer != null) footer!,
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            ],
          ),
        );
      },
    );
  }
}
