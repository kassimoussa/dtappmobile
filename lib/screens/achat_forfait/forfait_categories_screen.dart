// lib/screens/forfait_categories_screen.dart
import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/extensions/color_extensions.dart';
import 'package:dtservices/routes/custom_route_transitions.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/widgets/appbar_widget.dart';
import 'package:dtservices/enums/purchase_enums.dart';
import 'package:flutter/material.dart'; 
import 'forfaits_screen.dart';

class ForfaitCategoriesScreen extends StatelessWidget {
  final String? phoneNumber;
  final double soldeActuel;
  final VoidCallback? onRefreshSolde;
  final PurchaseMode purchaseMode;

  const ForfaitCategoriesScreen({
    super.key,
    this.phoneNumber,
    required this.soldeActuel,
    this.onRefreshSolde,
    this.purchaseMode = PurchaseMode.personal,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: 'Achat de forfait', 
        showAction: false, 
        value: soldeActuel,
        showCancelToHome: true,
        ),
      body: ListView(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        children: [
          _buildCategoryCard(
            context,
            title: 'Internet Classique',
            description: 'Forfaits data pour naviguer',
            icon: Icons.wifi,
            iconColor: AppTheme.dtBlue2,
            type: 'internet',
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),

          _buildCategoryCard(
            context,
            title: 'Forfaits Combo',
            description: 'Appels, SMS et Internet',
            icon: Icons.phone_android,
            iconColor: AppTheme.dtBlue2,
            type: 'combo',
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),

          _buildCategoryCard(
            context,
            title: 'Tempo',
            description: 'Minutes d\'appels week-end',
            icon: Icons.timer,
            iconColor: AppTheme.dtBlue2,
            type: 'tempo',
            isNew: false,
          ),
        ],
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder( 
        side: BorderSide(
          color: AppTheme.dtYellow,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToForfaits(context, type, title),
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
            vertical: ResponsiveSize.getHeight(AppTheme.spacingL),
          ),
          child: Row(
            children: [
              // Icône avec cercle de couleur
              Container(
                width: ResponsiveSize.getWidth(50),
                height: ResponsiveSize.getHeight(50),
                decoration: BoxDecoration(
                  color: iconColor.withOpacityValue(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: ResponsiveSize.getFontSize(26),
                ),
              ),

              SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingL)),

              // Titre et description
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
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        if (isNew) ...[
                          SizedBox(width: ResponsiveSize.getWidth(8)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveSize.getWidth(6),
                              vertical: ResponsiveSize.getHeight(2),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(8)),
                            ),
                            child: Text(
                              'NOUVEAU',
                              style: TextStyle(
                                fontSize: ResponsiveSize.getFontSize(10),
                                color: Colors.white,
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

              // Flèche droite
              Icon(
                Icons.chevron_right,
                color: AppTheme.dtBlue2,
                size: ResponsiveSize.getFontSize(24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToForfaits(BuildContext context, String type, String title) {
    // Navigation vers l'écran de forfaits unifié
    Navigator.push(
      context,
      CustomRouteTransitions.slideRightRoute(
        page: ForfaitsScreen(
          initialType: type,
          forfaitTitle: title,
          soldeActuel: soldeActuel,
          onRefreshSolde: onRefreshSolde,
          phoneNumber: phoneNumber,
          purchaseMode: purchaseMode, // Transmettre le mode d'achat
        ),
      ),
    );
  }
}