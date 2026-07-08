// lib/widgets/dt_button.dart
import 'package:flutter/material.dart';
import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/utils/responsive_size.dart';

/// Bouton standard de l'app — une seule source de vérité pour tous les CTA.
///
/// Variantes :
///  - [DtButton.primary]   : bleu plein, texte blanc — action principale
///  - [DtButton.secondary] : contour bleu, texte bleu — action secondaire
///  - [DtButton.text]      : lien texte bleu — action tertiaire
///  - [DtButton.danger]    : rouge — action destructive
///
/// L'état de chargement ([loading] : true) remplace le libellé par un
/// spinner et désactive le bouton — plus besoin de le recoder par écran.
class DtButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;
  final _DtButtonVariant _variant;

  const DtButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
  }) : _variant = _DtButtonVariant.primary;

  const DtButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
  }) : _variant = _DtButtonVariant.secondary;

  const DtButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = false,
  }) : _variant = _DtButtonVariant.text;

  const DtButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
  }) : _variant = _DtButtonVariant.danger;

  static const double _height = 56;
  static const double _radius = 14;
  static const Color _dangerRed = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnPressed = loading ? null : onPressed;

    final TextStyle labelStyle = TextStyle(
      fontFamily: 'Outfit',
      fontSize: ResponsiveSize.getFontSize(16),
      fontWeight: FontWeight.w600,
    );

    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(_radius)),
    );

    final Widget child = loading
        ? SizedBox(
            width: ResponsiveSize.getWidth(22),
            height: ResponsiveSize.getWidth(22),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _variant == _DtButtonVariant.secondary ||
                      _variant == _DtButtonVariant.text
                  ? AppTheme.dtBlue
                  : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: ResponsiveSize.getFontSize(20)),
                SizedBox(width: ResponsiveSize.getWidth(8)),
              ],
              Flexible(
                child: Text(label,
                    style: labelStyle, overflow: TextOverflow.ellipsis),
              ),
            ],
          );

    Widget button;
    switch (_variant) {
      case _DtButtonVariant.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.dtBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.dtBlueO30,
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            shape: shape,
          ),
          child: child,
        );
        break;
      case _DtButtonVariant.danger:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _dangerRed,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: shape,
          ),
          child: child,
        );
        break;
      case _DtButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.dtBlue,
            side: const BorderSide(color: AppTheme.dtBlueO50, width: 1.5),
            shape: shape,
          ),
          child: child,
        );
        break;
      case _DtButtonVariant.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(foregroundColor: AppTheme.dtBlue),
          child: child,
        );
        break;
    }

    if (_variant == _DtButtonVariant.text) return button;

    return SizedBox(
      width: expanded ? double.infinity : null,
      height: ResponsiveSize.getHeight(_height),
      child: button,
    );
  }
}

enum _DtButtonVariant { primary, secondary, text, danger }
