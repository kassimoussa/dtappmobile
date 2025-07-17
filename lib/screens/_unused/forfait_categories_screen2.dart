// lib/screens/forfait_categories_screen.dart
import 'package:dtapp3/constants/app_theme.dart';
import 'package:dtapp3/extensions/color_extensions.dart';
import 'package:dtapp3/routes/custom_route_transitions.dart';
import 'package:dtapp3/screens/_unused/forfaits_screen2.dart'; 
import 'package:dtapp3/utils/responsive_size.dart';
import 'package:dtapp3/widgets/appbar_widget.dart'; 
import 'package:flutter/material.dart';

class ForfaitCategoriesScreen2 extends StatelessWidget {
  final String? phoneNumber;
   final String? secondPhoneNumber;
  final double soldeActuel;
  final VoidCallback? onRefreshSolde;

  const ForfaitCategoriesScreen2({
    super.key,
    this.phoneNumber,
    required this.soldeActuel,
    this.onRefreshSolde, 
    this.secondPhoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(title: 'Achat de forfait', showAction: false, value: soldeActuel),
      body: ListView(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        children: [
          _buildCategoryCard(
            context,
            title: 'Internet Classique',
            icon: Icons.wifi,
            iconColor: AppTheme.dtBlue2,
            type: 'internet',
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),

          _buildCategoryCard(
            context,
            title: 'Forfaits Combo',
            icon: Icons.phone_android,
            iconColor: AppTheme.dtBlue2,
            type: 'combo',
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),

          _buildCategoryCard(
            context,
            title: 'Tempo',
            icon: Icons.timer,
            iconColor: AppTheme.dtBlue2,
            type: 'pulse',
          ),
           
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required String type,
  }) {
    return Card(
      elevation: 1,
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
                width: ResponsiveSize.getWidth(44),
                height: ResponsiveSize.getHeight(44),
                decoration: BoxDecoration(
                  color: iconColor.withOpacityValue(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: ResponsiveSize.getFontSize(24),
                ),
              ),

              SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingL)),

              // Titre
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
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
    // Si le type est internet ou combo, nous pouvons naviguer vers votre écran de forfaits existant
    if (type == 'internet' || type == 'combo') {
      Navigator.push(
        context,
        CustomRouteTransitions.slideRightRoute(
          page: ForfaitsScreen2(
            initialType: type,
            forfaitTitle: title,
            soldeActuel: soldeActuel,
            onRefreshSolde: onRefreshSolde,
            phoneNumber: phoneNumber, 
          ),
        ),
      );
    } else {
      // Pour les autres types, nous montrons un message "Bientôt disponible"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Les forfaits "$title" seront bientôt disponibles.'),
          backgroundColor: AppTheme.dtBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
