// lib/widgets/settings_card.dart
import 'package:flutter/material.dart';
import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/utils/responsive_size.dart';

/// Carte de réglages standard (modèle : écran profil).
///
/// Fond blanc premium (AppTheme.cardDecoration), titre optionnel en Outfit,
/// lignes séparées par un divider fin inséré automatiquement.
///
/// À utiliser sur tous les écrans de réglages : toute évolution du style
/// des cartes se fait ici, une seule fois.
class SettingsCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingsCard({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(height: 1, color: Colors.grey[200]));
      rows.add(children[i]);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
        vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
      ),
      decoration: AppTheme.cardDecoration,
      child: Column(
        // min : la carte épouse son contenu au lieu de s'étirer jusqu'en bas
        // quand le parent a une hauteur bornée (ex. Expanded sans scroll).
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveSize.getHeight(AppTheme.spacingS),
                bottom: ResponsiveSize.getHeight(AppTheme.spacingXS),
              ),
              child: Text(
                title!,
                style: AppTheme.subheadingStyle.copyWith(
                  fontSize: ResponsiveSize.getFontSize(16),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ...rows,
        ],
      ),
    );
  }
}

/// Ligne standard d'une [SettingsCard] : icône optionnelle + libellé +
/// élément de droite (chevron par défaut ; passer un Switch, une Radio,
/// un loader… via [trailing]).
class SettingsTile extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? labelColor;
  final FontWeight fontWeight;

  const SettingsTile({
    super.key,
    this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.labelColor,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveSize.getHeight(AppTheme.spacingS + 2),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? Colors.grey[600],
              size: ResponsiveSize.getFontSize(22),
            ),
            SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: ResponsiveSize.getFontSize(15),
                color: labelColor ?? Colors.black87,
                fontWeight: fontWeight,
              ),
            ),
          ),
          trailing ?? const SettingsChevron(),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// Chevron de navigation standard des lignes de réglages.
class SettingsChevron extends StatelessWidget {
  final Color? color;

  const SettingsChevron({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.arrow_forward_ios,
      color: color ?? Colors.grey[400],
      size: ResponsiveSize.getFontSize(15),
    );
  }
}
