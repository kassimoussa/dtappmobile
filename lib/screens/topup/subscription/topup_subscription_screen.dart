// lib/screens/topup/topup_subscription_screen.dart
import 'package:flutter/material.dart';

import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/appbar_widget.dart';
import '../../../routes/custom_route_transitions.dart';
import '../../../models/topup_balance.dart';
import '../../../services/topup_api_service.dart';
import '../packages/topup_package_list_screen.dart';

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
  TopUpBalanceResponse? _balanceResponse;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await TopUpApi.instance.getBalances(
        msisdn: widget.mobileNumber,
        isdn: widget.fixedNumber,
        useCache: false,
      );

      setState(() {
        _balanceResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('TopUp Subscription - Erreur chargement soldes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _hasActiveSubscription(String type) {
    if (_balanceResponse == null) return false;

    // Chercher une souscription active du type demandé (données ou voix)
    for (final balance in _balanceResponse!.balances) {
      if ((type == 'data' && balance.isDataType) || 
          (type == 'voice' && balance.isVoiceType)) {
        // Vérifier si la souscription n'expire pas bientôt (plus de 3 jours)
        if (balance.isActive && !balance.isExpiringSoon) {
          return true;
        }
      }
    }
    return false;
  }

  String _getExpirationInfo(String type) {
    if (_balanceResponse == null) return '';

    for (final balance in _balanceResponse!.balances) {
      if ((type == 'data' && balance.isDataType) || 
          (type == 'voice' && balance.isVoiceType)) {
        if (balance.isActive && !balance.isExpiringSoon) {
          return balance.expireDateFormatted;
        }
      }
    }
    return '';
  }

  void _showActiveSubscriptionDialog(String type, VoidCallback onContinue) {
    final subscriptionType = type == 'data' ? 'données' : 'voix';
    final expirationDate = _getExpirationInfo(type);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              SizedBox(width: ResponsiveSize.getWidth(8)),
              Expanded(
                child: Text(
                  'Souscription active',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vous avez déjà une souscription $subscriptionType active qui expire le $expirationDate.',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(16)),
              Container(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(12)),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(8)),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: ResponsiveSize.getWidth(8)),
                    Expanded(
                      child: Text(
                        'Acheter une nouvelle souscription remplacera l\'actuelle. Voulez-vous continuer ?',
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(14),
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onContinue();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: AppTheme.dtYellow,
              ),
              child: Text(
                'Continuer',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSubscriptionList(int packageType, String typeLabel, String type) {
    void proceedToNavigation() {
      Navigator.push(
        context,
        CustomRouteTransitions.slideRightRoute(
          page: TopUpPackageListScreen(
            fixedNumber: widget.fixedNumber,
            mobileNumber: widget.mobileNumber,
            packageType: packageType,
            typeLabel: typeLabel,
            soldeActuel: widget.soldeActuel,
          ),
        ),
      );
    }

    if (_hasActiveSubscription(type)) {
      _showActiveSubscriptionDialog(type, proceedToNavigation);
    } else {
      proceedToNavigation();
    }
  }

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

                  // Indicateur de chargement
                  if (_isLoading) ...[
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: AppTheme.dtBlue),
                          SizedBox(height: ResponsiveSize.getHeight(16)),
                          Text(
                            'Vérification des souscriptions actives...',
                            style: TextStyle(
                              fontSize: ResponsiveSize.getFontSize(14),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
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
                            _navigateToSubscriptionList(
                              2, // Type 2 = données souscription
                              'Souscriptions Données',
                              'data',
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
                            _navigateToSubscriptionList(
                              1, // Type 1 = voix souscription
                              'Souscriptions Voix',
                              'voice',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  ], // Fermeture du else
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