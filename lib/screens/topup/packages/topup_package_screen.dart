// lib/screens/topup/topup_package_screen.dart
import 'package:flutter/material.dart';

import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/appbar_widget.dart';
import '../../../routes/custom_route_transitions.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'topup_package_list_screen.dart';

class TopUpPackageScreen extends StatefulWidget {
  final String fixedNumber;
  final String mobileNumber;
  final double soldeActuel;
  final bool hasUnlimitedData;

  const TopUpPackageScreen({
    super.key,
    required this.fixedNumber,
    required this.mobileNumber,
    required this.soldeActuel,
    this.hasUnlimitedData = false,
  });

  @override
  State<TopUpPackageScreen> createState() => _TopUpPackageScreenState();
}

class _TopUpPackageScreenState extends State<TopUpPackageScreen> {
  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: l10n.buyPackagesTitle,
        showAction: false,
        showCancelToHome: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.choosePackageType,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(20),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(24)),

                  Row(
                    children: [
                      Expanded(
                        child: _buildOptionCard(
                          context,
                          l10n.additionalDataPackage,
                          AppTheme.dtBlue2,
                          Icons.data_usage,
                          onTap: () {
                            if (widget.hasUnlimitedData) {
                              _showUnlimitedDataDialog();
                            } else {
                              Navigator.push(
                                context,
                                CustomRouteTransitions.slideRightRoute(
                                  page: TopUpPackageListScreen(
                                    fixedNumber: widget.fixedNumber,
                                    mobileNumber: widget.mobileNumber,
                                    packageType: 4,
                                    typeLabel: l10n.dataPackageAddon,
                                    soldeActuel: widget.soldeActuel,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(width: ResponsiveSize.getWidth(16)),
                      Expanded(
                        child: _buildOptionCard(
                          context,
                          l10n.additionalVoicePackage,
                          AppTheme.dtBlue2,
                          Icons.phone_in_talk,
                          onTap: () {
                            Navigator.push(
                              context,
                              CustomRouteTransitions.slideRightRoute(
                                page: TopUpPackageListScreen(
                                  fixedNumber: widget.fixedNumber,
                                  mobileNumber: widget.mobileNumber,
                                  packageType: 6,
                                  typeLabel: l10n.voicePackageAddon,
                                  soldeActuel: widget.soldeActuel,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    Color iconColor,
    IconData cardIcon, {
    required VoidCallback onTap,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(12)),
      child: Container(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(20)),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dtYellow),
          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: ResponsiveSize.getWidth(60),
              height: ResponsiveSize.getHeight(60),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: AppTheme.dtYellow),
                borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(10)),
              ),
              child: Icon(
                cardIcon,
                size: ResponsiveSize.getFontSize(30),
                color: AppTheme.dtBlue2,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(16)),
            Text(
              l10n.packageCardLabel,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(4)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlimitedDataDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        ),
        title: Row(
          children: [
            Icon(Icons.data_usage, color: AppTheme.dtBlue, size: 24),
            SizedBox(width: ResponsiveSize.getWidth(8)),
            Text(
              l10n.unlimitedDataTitle,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtBlue,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.unlimitedDataMessage,
          style: TextStyle(fontSize: ResponsiveSize.getFontSize(15)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: AppTheme.dtBlue,
                fontSize: ResponsiveSize.getFontSize(16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String packageType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          packageType,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(18),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),
        content: Text(
          'Cette fonctionnalité sera bientôt disponible.',
          style: TextStyle(fontSize: ResponsiveSize.getFontSize(16)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: AppTheme.dtBlue,
                fontSize: ResponsiveSize.getFontSize(16),
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveSize.getWidth(AppTheme.radiusM),
          ),
        ),
      ),
    );
  }
}