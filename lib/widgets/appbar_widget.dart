import 'package:dtapp3/constants/app_theme.dart';
import 'package:dtapp3/extensions/color_extensions.dart';
import 'package:dtapp3/utils/responsive_size.dart';
import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {

  final String title;
  final double? value;
  final bool showAction;

  const AppBarWidget({super.key, required this.title, this.value, required this.showAction});

  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.dtBlue,
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: ResponsiveSize.getFontSize(16),
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      leadingWidth: 30,
      elevation: 0,
      actions: showAction
        ? [
            Padding(
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
                  ),
                  child: Text(
                    'Solde: ${value?.toStringAsFixed(0)} FDJ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveSize.getFontSize(12),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ]
        : null,
    );
  }
}
