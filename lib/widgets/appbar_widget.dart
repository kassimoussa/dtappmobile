import 'package:dtapp3/constants/app_theme.dart';
import 'package:dtapp3/extensions/color_extensions.dart';
import 'package:dtapp3/utils/responsive_size.dart';
import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double? value;
  final bool showAction;
  final bool showLeading;
  final VoidCallback? onLeadingPressed;
  final Widget? customLeading;
  final List<Widget>? customActions;
  final String? currency;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool showCancelToHome;
  final String? homeRouteName;

  const AppBarWidget({
    super.key,
    required this.title,
    this.value,
    required this.showAction,
    this.showLeading = true,
    this.onLeadingPressed,
    this.customLeading,
    this.customActions,
    this.currency = 'FDJ',
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.showCancelToHome = false,
    this.homeRouteName,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    final bgColor = backgroundColor ?? AppTheme.dtBlue;
    final fgColor = foregroundColor ?? Colors.white;

    return AppBar(
      backgroundColor: bgColor,
      elevation: elevation ?? 0,
      automaticallyImplyLeading: false,
      leading: _buildLeading(context, fgColor),
      title: Text(
        title,
        style: TextStyle(
          color: fgColor,
          fontSize: ResponsiveSize.getFontSize(16),
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: _buildActions(context, fgColor),
    );
  }

  Widget? _buildLeading(BuildContext context, Color foregroundColor) {
    if (!showLeading) return null;
    
    if (customLeading != null) return customLeading;
    
    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        color: foregroundColor,
        size: ResponsiveSize.getFontSize(24),
      ),
      onPressed: onLeadingPressed ?? () => Navigator.of(context).pop(),
      tooltip: 'Retour',
    );
  }

  List<Widget>? _buildActions(BuildContext context, Color foregroundColor) {
    final actions = <Widget>[];
    
    // Ajouter le bouton "Annuler" vers l'accueil si demandé
    if (showCancelToHome) {
      actions.add(_buildCancelButton(context, foregroundColor));
    }
    
    // Ajouter l'affichage du solde si demandé
    if (showAction && value != null) {
      actions.add(_buildSoldeWidget(foregroundColor));
    }
    
    // Ajouter des actions personnalisées si fournies
    if (customActions != null) {
      actions.addAll(customActions!);
    }
    
    return actions.isEmpty ? null : actions;
  }

  Widget _buildCancelButton(BuildContext context, Color foregroundColor) {
    return Padding(
      padding: EdgeInsets.only(
        right: ResponsiveSize.getWidth(AppTheme.spacingS),
      ),
      child: TextButton(
        onPressed: () => _navigateToHome(context),
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor,
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(AppTheme.spacingS),
            vertical: ResponsiveSize.getHeight(AppTheme.spacingXS),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.close,
              color: foregroundColor,
              size: ResponsiveSize.getFontSize(18),
            ),
            SizedBox(width: ResponsiveSize.getWidth(4)),
            Text(
              'Annuler',
              style: TextStyle(
                color: foregroundColor,
                fontSize: ResponsiveSize.getFontSize(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    // Si un nom de route est spécifié, l'utiliser
    if (homeRouteName != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        homeRouteName!,
        (route) => false,
      );
    } else {
      // Sinon, retourner à la racine de la navigation
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Widget _buildSoldeWidget(Color foregroundColor) {
    return Padding(
      padding: EdgeInsets.only(
        right: ResponsiveSize.getWidth(AppTheme.spacingM),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(AppTheme.spacingS),
            vertical: ResponsiveSize.getHeight(AppTheme.spacingXS),
          ),
          decoration: BoxDecoration(
            color: AppTheme.dtYellow.withOpacityValue(0.2),
            borderRadius: BorderRadius.circular(
              ResponsiveSize.getWidth(AppTheme.radiusS),
            ),
            border: Border.all(
              color: AppTheme.dtYellow.withOpacityValue(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: foregroundColor,
                size: ResponsiveSize.getFontSize(14),
              ),
              SizedBox(width: ResponsiveSize.getWidth(4)),
              Text(
                'Solde: ${_formatValue(value!)} $currency',
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: ResponsiveSize.getFontSize(12),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue(double value) {
    // Formater le nombre avec des espaces pour les milliers
    if (value >= 1000) {
      return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );
    }
    return value.toStringAsFixed(0);
  }
}

// Extension optionnelle pour des AppBars prédéfinies
extension AppBarWidgetExtensions on AppBarWidget {
  // AppBar pour les processus d'achat avec bouton annuler
  static AppBarWidget purchase({
    required String title,
    double? solde,
    String? homeRoute,
    VoidCallback? onBack,
  }) {
    return AppBarWidget(
      title: title,
      value: solde,
      showAction: solde != null,
      showCancelToHome: true,
      homeRouteName: homeRoute,
      onLeadingPressed: onBack,
    );
  }

  // AppBar pour les écrans principaux
  static AppBarWidget home({
    required String title,
    double? solde,
    List<Widget>? actions,
  }) {
    return AppBarWidget(
      title: title,
      value: solde,
      showAction: solde != null,
      showLeading: false,
      customActions: actions,
    );
  }

  // AppBar pour les écrans de navigation
  static AppBarWidget navigation({
    required String title,
    double? solde,
    VoidCallback? onBack,
  }) {
    return AppBarWidget(
      title: title,
      value: solde,
      showAction: solde != null,
      onLeadingPressed: onBack,
    );
  }

  // AppBar pour les écrans de confirmation
  static AppBarWidget confirmation({
    required String title,
    double? solde,
    Color? backgroundColor,
  }) {
    return AppBarWidget(
      title: title,
      value: solde,
      showAction: solde != null,
      backgroundColor: backgroundColor ?? AppTheme.dtBlue,
    );
  }

  // AppBar minimale sans solde
  static AppBarWidget simple({
    required String title,
    bool showBack = true,
    VoidCallback? onBack,
  }) {
    return AppBarWidget(
      title: title,
      showAction: false,
      showLeading: showBack,
      onLeadingPressed: onBack,
    );
  }
}