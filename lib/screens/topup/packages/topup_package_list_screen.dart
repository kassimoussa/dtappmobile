// lib/screens/topup/topup_package_list_screen.dart
import 'package:flutter/material.dart';

import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/appbar_widget.dart';
import '../../../models/topup_balance.dart';
import '../../../services/topup_api_service.dart';
import '../../../exceptions/topup_exception.dart';
import '../../../routes/custom_route_transitions.dart';
import 'topup_package_confirmation_screen.dart';

class TopUpPackageListScreen extends StatefulWidget {
  final String fixedNumber;
  final String mobileNumber;
  final int packageType; // 4 = données, 6 = voix
  final String typeLabel;
  final double soldeActuel;

  const TopUpPackageListScreen({
    super.key,
    required this.fixedNumber,
    required this.mobileNumber,
    required this.packageType,
    required this.typeLabel,
    required this.soldeActuel,
  });

  @override
  State<TopUpPackageListScreen> createState() => _TopUpPackageListScreenState();
}

class _TopUpPackageListScreenState extends State<TopUpPackageListScreen> {
  TopUpPackageResponse? _packageResponse;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await TopUpApi.instance.getPackages(
        msisdn: widget.mobileNumber,
        isdn: widget.fixedNumber,
        type: widget.packageType,
        useCache: true,
      );

      setState(() {
        _packageResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e is TopUpException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = 'Une erreur inattendue est survenue';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: widget.typeLabel,
        showAction: false,
        value: widget.soldeActuel,
        showCancelToHome: true,
      ),
      body: Column(
        children: [
          // Contenu principal
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildPackageList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlue),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          Text(
            'Chargement des packages...',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveSize.getFontSize(64),
              color: Colors.red,
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(20),
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
            ElevatedButton.icon(
              onPressed: _loadPackages,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageList() {
    final response = _packageResponse!;
    
    if (response.packages.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getPackageIcon(),
                size: ResponsiveSize.getFontSize(80),
                color: AppTheme.dtBlue.withOpacity(0.6),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              Text(
                'Aucun package disponible',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              Text(
                'Les packages ${widget.typeLabel.toLowerCase()} seront bientôt disponibles pour cette ligne.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(14),
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // En-tête explicatif (style forfait)
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
          decoration: BoxDecoration(
            color: AppTheme.dtBlue.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.dtBlue.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisissez votre package',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(18),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
              Text(
                '${response.totalPackages} package(s) ${widget.typeLabel.toLowerCase()} disponible(s) pour votre ligne fixe.',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(14),
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),

        // Liste des packages
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: response.packages.length,
              separatorBuilder: (context, index) => SizedBox(
                height: ResponsiveSize.getHeight(AppTheme.spacingM),
              ),
              itemBuilder: (context, index) {
                final package = response.packages[index];
                return _buildPackageCard(package);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(TopUpPackage package) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
      ),
      child: Column(
        children: [
          // Section principale
          Padding(
            padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre (package_code)
                Text(
                  package.packageCode,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dtBlue,
                  ),
                ),
                
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),

                // Détails du package selon le type
                _buildPackageDetails(package),
                    
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                
                // Prix et bouton d'achat
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      package.formattedPrice,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(20),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dtBlue,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: package.price > widget.soldeActuel 
                          ? null 
                          : () => _navigateToConfirmation(package),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dtBlue,
                        foregroundColor: AppTheme.dtYellow,
                        disabledBackgroundColor: Colors.grey[400],
                        disabledForegroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveSize.getWidth(AppTheme.spacingL),
                          vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                        ),
                      ),
                      child: package.price > widget.soldeActuel
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: ResponsiveSize.getFontSize(16),
                                ),
                                SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
                                Text(
                                  'Solde insuffisant',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveSize.getFontSize(14),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Acheter',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveSize.getFontSize(16),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageDetails(TopUpPackage package) {
    // Déterminer si c'est une souscription (types 1 et 2) ou un package additionnel (types 4 et 6)
    bool isSubscription = _isSubscriptionType();
    
    if (package.isDataPackage) {
      return _buildDataPackageDetails(package, isSubscription);
    } else if (package.isVoicePackage) {
      return _buildVoicePackageDetails(package, isSubscription);
    } else {
      return _buildGenericPackageDetails(package);
    }
  }

  bool _isSubscriptionType() {
    return widget.packageType == 1 || widget.packageType == 2;
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: ResponsiveSize.getFontSize(16),
          color: Colors.grey[600],
        ),
        SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDataPackageDetails(TopUpPackage package, bool isSubscription) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDetailItem(Icons.data_usage, package.formattedData),
          ),
          if (isSubscription && package.formattedValidity.isNotEmpty && package.formattedValidity != 'Non spécifiée') ...[ 
            SizedBox(width: ResponsiveSize.getWidth(8)),
            Expanded(
              child: _buildDetailItem(Icons.schedule, '${package.formattedValidity} jours'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoicePackageDetails(TopUpPackage package, bool isSubscription) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDetailItem(Icons.phone, package.formattedVoice),
          ),
          if (isSubscription && package.formattedValidity.isNotEmpty && package.formattedValidity != 'Non spécifiée') ...[ 
            SizedBox(width: ResponsiveSize.getWidth(8)),
            Expanded(
              child: _buildDetailItem(Icons.schedule, '${package.formattedValidity} jours'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenericPackageDetails(TopUpPackage package) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
      ),
      child: _buildDetailItem(Icons.card_giftcard, package.mainFeature),
    );
  }

  IconData _getPackageIcon() {
    switch (widget.packageType) {
      case 1: // Souscription voix
      case 6: // Package voix additionnel
        return Icons.phone_in_talk;
      case 2: // Souscription données
      case 4: // Package données additionnel
        return Icons.data_usage;
      default:
        return Icons.help_outline;
    }
  }

  void _navigateToConfirmation(TopUpPackage package) {
    Navigator.push(
      context,
      CustomRouteTransitions.slideRightRoute(
        page: TopUpPackageConfirmationScreen(
          package: package,
          fixedNumber: widget.fixedNumber,
          mobileNumber: widget.mobileNumber,
          soldeActuel: widget.soldeActuel,
          packageType: widget.packageType,
        ),
      ),
    );
  }

  void _showPackageDetails(TopUpPackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          package.displayName,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(18),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Prix', package.formattedPrice),
            if (package.isDataPackage)
              _buildDetailRow('Données', package.formattedData),
            if (package.isVoicePackage)
              _buildDetailRow('Minutes', package.formattedVoice),
            if (package.formattedValidity.isNotEmpty && package.formattedValidity != 'Non spécifiée')
              _buildDetailRow('Validité', package.formattedValidity),
            _buildDetailRow('Disponibilité', package.price <= widget.soldeActuel ? 'Disponible' : 'Solde insuffisant'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: TextStyle(color: AppTheme.dtBlue),
            ),
          ),
          if (package.price <= widget.soldeActuel)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToConfirmation(package);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Souscrire'),
            ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveSize.getHeight(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          feature,
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
          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        ),
      ),
    );
  }
}