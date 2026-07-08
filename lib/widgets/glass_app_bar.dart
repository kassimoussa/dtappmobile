// lib/widgets/glass_app_bar.dart
import 'package:flutter/material.dart';
import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/utils/responsive_size.dart';

/// Header standard de l'app (modèle : écran historique).
///
/// Fond transparent — il se fond dans le fond de l'écran (gris clair + halo),
/// titre bleu en Outfit w800, bouton retour et actions en chips glass.
///
/// Toute évolution du header se fait ici, une seule fois.
class GlassAppBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final double titleFontSize;

  const GlassAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.titleFontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(12),
        vertical: ResponsiveSize.getHeight(12),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            GlassAppBarAction(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack ?? () => Navigator.of(context).pop(),
            ),
            SizedBox(width: ResponsiveSize.getWidth(16)),
          ],
          Expanded(
            // Les titres longs rétrécissent pour tenir en entier plutôt
            // que d'être tronqués par « … »
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                style: AppTheme.headingStyle.copyWith(
                  fontSize: ResponsiveSize.getFontSize(titleFontSize),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Chip d'action glass du header : icône seule (bouton retour, toggle…),
/// libellé seul (« Annuler »), icône + libellé (« Stats » sur l'historique),
/// ou variante pleine [filled] pour l'action principale (« Enregistrer »).
class GlassAppBarAction extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;
  final bool filled;

  const GlassAppBarAction({
    super.key,
    this.icon,
    this.label,
    required this.onTap,
    this.filled = false,
  }) : assert(icon != null || label != null,
            'GlassAppBarAction: fournir au moins icon ou label');

  @override
  Widget build(BuildContext context) {
    final Color contentColor = filled ? AppTheme.dtYellow : AppTheme.dtBlueDark;
    final children = <Widget>[
      if (icon != null) Icon(icon, color: contentColor, size: 20),
      if (icon != null && label != null) const SizedBox(width: 6),
      if (label != null)
        Text(
          label!,
          style: AppTheme.bodyStyle.copyWith(
            color: contentColor,
            fontWeight: filled ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: label == null
            ? const EdgeInsets.all(10)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? AppTheme.dtBlueDark : AppTheme.white50,
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: Colors.white),
        ),
        child: children.length == 1
            ? children.single
            : Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
