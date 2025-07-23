// lib/screens/topup/topup_subscription_screen.dart
import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../widgets/appbar_widget.dart';
import '../../routes/custom_route_transitions.dart';
import 'topup_package_list_screen.dart';

class TopUpSubscriptionScreen extends StatefulWidget {
  final String fixedNumber;
  final String mobileNumber;
  final double soldeActuel;

  const TopUpSubscriptionScreen({
    super.key,
    required this.fixedNumber,
    required this.mobileNumber,
    required this.soldeActuel,
  });

  @override
  State<TopUpSubscriptionScreen> createState() => _TopUpSubscriptionScreenState();
}

class _TopUpSubscriptionScreenState extends State<TopUpSubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: 'Acheter une souscription', 
        showAction: false,
        showCancelToHome: true,
      ),
      body: Column(
        children: [
          // Contenu principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Titre principal
                  Text(
                    'Choisir le type de souscription',
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(20),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(24)),

                  // Options de souscriptions
                  Row(
                    children: [
                      Expanded(
                        child: _buildOptionCard(
                          context,
                          'Données',
                          AppTheme.dtBlue2,
                          Icons.data_usage,
                          onTap: () {
                            Navigator.push(
                              context,
                              CustomRouteTransitions.slideRightRoute(
                                page: TopUpPackageListScreen(
                                  fixedNumber: widget.fixedNumber,
                                  mobileNumber: widget.mobileNumber,
                                  packageType: 2, // Type 2 = données souscription
                                  typeLabel: 'Souscriptions Données',
                                  soldeActuel: widget.soldeActuel,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: ResponsiveSize.getWidth(16)),
                      Expanded(
                        child: _buildOptionCard(
                          context,
                          'Voix',
                          AppTheme.dtBlue2,
                          Icons.phone_in_talk,
                          onTap: () {
                            Navigator.push(
                              context,
                              CustomRouteTransitions.slideRightRoute(
                                page: TopUpPackageListScreen(
                                  fixedNumber: widget.fixedNumber,
                                  mobileNumber: widget.mobileNumber,
                                  packageType: 1, // Type 1 = voix souscription
                                  typeLabel: 'Souscriptions Voix',
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
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: ResponsiveSize.getWidth(60),
                  height: ResponsiveSize.getHeight(60),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: AppTheme.dtYellow),
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(10),
                    ),
                  ),
                  child: Icon(
                    cardIcon,
                    size: ResponsiveSize.getFontSize(30),
                    color: AppTheme.dtBlue2,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.getHeight(16)),
            Text(
              'Souscription',
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
}