import 'dart:ui';
import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/extensions/color_extensions.dart';
import 'package:dtservices/routes/custom_route_transitions.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/enums/purchase_enums.dart';
import 'package:flutter/material.dart';
import 'forfaits_screen.dart';
import '../../generated/l10n/app_localizations.dart';

class ForfaitCategoriesScreen extends StatelessWidget {
  final String? phoneNumber;
  final PurchaseMode purchaseMode;

  const ForfaitCategoriesScreen({
    super.key,
    this.phoneNumber,
    this.purchaseMode = PurchaseMode.personal,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.dtBlueDark.withOpacityValue(0.08),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildGlassAppBar(context, l10n.buyPackageTitle),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: ResponsiveSize.getHeight(8)),
                        Text(
                          l10n.choosePackageHeader,
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(14),
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                        _buildCategoryCard(
                          context,
                          title: l10n.internetClassique,
                          description: l10n.internetClassiqueDesc,
                          icon: Icons.wifi_rounded,
                          accentColor: AppTheme.dtBlueDark,
                          type: 'internet',
                        ),
                        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                        _buildCategoryCard(
                          context,
                          title: l10n.comboPackages,
                          description: l10n.comboPackagesDesc,
                          icon: Icons.phone_android_rounded,
                          accentColor: AppTheme.dtBlue2,
                          type: 'combo',
                        ),
                        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                        _buildCategoryCard(
                          context,
                          title: l10n.tempoPackages,
                          description: l10n.tempoPackagesDesc,
                          icon: Icons.timer_rounded,
                          accentColor: AppTheme.dtYellow,
                          type: 'tempo',
                          badge: 'Weekend',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar(BuildContext context, String title) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(12),
            vertical: ResponsiveSize.getHeight(12),
          ),
          decoration: BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.dtBlueDark, size: 20),
                ),
              ),
              SizedBox(width: ResponsiveSize.getWidth(16)),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: ResponsiveSize.getFontSize(22),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveSize.getWidth(8)),
              InkWell(
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.getWidth(12),
                    vertical: ResponsiveSize.getHeight(8),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: TextStyle(
                      color: AppTheme.dtBlueDark,
                      fontSize: ResponsiveSize.getFontSize(13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String type, String title) {
    Navigator.push(
      context,
      CustomRouteTransitions.slideRightRoute(
        page: ForfaitsScreen(
          phoneNumber: phoneNumber,
          initialType: type,
          forfaitTitle: title,
          purchaseMode: purchaseMode,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required String type,
    String? badge,
  }) {
    final bool isYellow = accentColor == AppTheme.dtYellow;
    final Color iconColor = isYellow ? AppTheme.dtBlueDark : accentColor;

    return GestureDetector(
      onTap: () => _navigate(context, type, title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withOpacityValue(isYellow ? 1.0 : 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.dtBlueDark.withOpacityValue(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
          vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveSize.getWidth(12)),
              decoration: BoxDecoration(
                color: accentColor.withOpacityValue(isYellow ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: ResponsiveSize.getFontSize(28)),
            ),
            SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(16),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dtBlueDark,
                        ),
                      ),
                      if (badge != null) ...[
                        SizedBox(width: ResponsiveSize.getWidth(8)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.dtYellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: AppTheme.dtBlueDark,
                              fontSize: ResponsiveSize.getFontSize(10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(4)),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(12),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }
}
