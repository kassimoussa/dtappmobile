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
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
                    children: [
                      _buildCategoryCard(
                        context,
                        title: l10n.internetClassique,
                        description: l10n.internetClassiqueDesc,
                        icon: Icons.wifi_rounded,
                        iconColor: AppTheme.dtBlueDark,
                        type: 'internet',
                      ),
                      SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                      _buildCategoryCard(
                        context,
                        title: l10n.comboPackages,
                        description: l10n.comboPackagesDesc,
                        icon: Icons.phone_android_rounded,
                        iconColor: AppTheme.dtBlueDark,
                        type: 'combo',
                      ),
                      SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                      _buildCategoryCard(
                        context,
                        title: l10n.tempoPackages,
                        description: l10n.tempoPackagesDesc,
                        icon: Icons.timer_rounded,
                        iconColor: AppTheme.dtBlueDark,
                        type: 'tempo',
                        isNew: false,
                      ),
                    ],
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
                    color: Colors.white.withOpacity(0.5),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String type,
    bool isNew = false,
  }) {
    return InkWell(
      onTap: () {
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
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.dtBlueDark.withOpacityValue(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
              decoration: BoxDecoration(
                color: iconColor.withOpacityValue(0.1),
                borderRadius: BorderRadius.circular(16),
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
                      if (isNew) ...[
                        SizedBox(width: ResponsiveSize.getWidth(8)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
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
