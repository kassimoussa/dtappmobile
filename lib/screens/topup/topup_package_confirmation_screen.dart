// lib/screens/topup/topup_package_confirmation_screen.dart
import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../widgets/appbar_widget.dart';
import '../../models/topup_balance.dart';
import '../../services/user_session.dart';
import '../../services/topup_api_service.dart';
import '../../routes/custom_route_transitions.dart';
import '../../extensions/color_extensions.dart';
import '../../exceptions/topup_exception.dart';
import 'topup_success_screen.dart';
import 'topup_subscription_success_screen.dart';

class TopUpPackageConfirmationScreen extends StatefulWidget {
  final TopUpPackage package;
  final String fixedNumber;
  final String mobileNumber;
  final double soldeActuel;
  final int packageType;

  const TopUpPackageConfirmationScreen({
    super.key,
    required this.package,
    required this.fixedNumber,
    required this.mobileNumber,
    required this.soldeActuel,
    required this.packageType,
  });

  @override
  State<TopUpPackageConfirmationScreen> createState() => _TopUpPackageConfirmationScreenState();
}

class _TopUpPackageConfirmationScreenState extends State<TopUpPackageConfirmationScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _userPhoneNumber;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserPhoneNumber();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  Future<void> _loadUserPhoneNumber() async {
    try {
      final phoneNumber = await UserSession.getPhoneNumber();
      setState(() {
        _userPhoneNumber = phoneNumber;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement du numéro utilisateur: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _purchaseTypeLabel {
    bool isSubscription = widget.packageType == 1 || widget.packageType == 2;
    return isSubscription ? 'Achat de souscription TopUp' : 'Achat de package TopUp';
  }

  IconData get _purchaseTypeIcon => Icons.add_shopping_cart;

  Color get _purchaseTypeColor => AppTheme.dtBlue;

  bool _isSubscription() {
    return widget.packageType == 1 || widget.packageType == 2;
  }

  String _getPackageSubTitle() {
    if (widget.package.description.isNotEmpty) {
      return widget.package.description;
    }
    
    final isDataPackage = widget.package.isDataPackage;
    if (_isSubscription()) {
      return 'Souscription ${isDataPackage ? 'données' : 'voix'}';
    } else {
      return 'Package ${isDataPackage ? 'données' : 'voix'} additionnel';
    }
  }

  Future<void> _confirmerAchat() async {
    if (_isLoading) return;
    
    // Vérifier le solde avant de procéder
    if (widget.package.price > widget.soldeActuel) {
      _showErrorMessage('Solde insuffisant pour cet achat.');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      debugPrint('TopUp - Début souscription package: ${widget.package.packageCode}');
      
      // Appel à l'API pour souscrire au package TopUp (le statut a déjà été vérifié)
      final response = await TopUpApi.instance.subscribePackage(
        msisdn: widget.mobileNumber,
        isdn: widget.fixedNumber,
        packageCode: widget.package.packageCode,
      );
      
      debugPrint('TopUp - Réponse API: success=${response.success}, transaction=${response.transactionId}');
      debugPrint('TopUp - commandExecuted=${response.commandExecuted}');
      debugPrint('TopUp - message=${response.message}');
      
      if (mounted) {
        if (response.success) {
          debugPrint('TopUp - Navigation vers success screen...');
          // Succès - naviguer vers l'écran de succès approprié
          final isSubscription = _isSubscription();
          
          Navigator.pushReplacement(
            context,
            CustomRouteTransitions.fadeRoute(
              page: isSubscription 
                ? TopUpSubscriptionSuccessScreen(
                    subscription: widget.package,
                    mobileNumber: widget.mobileNumber,
                    fixedNumber: widget.fixedNumber,
                    ancienSolde: response.accountImpact?.balanceBefore ?? widget.soldeActuel,
                    transactionId: response.transactionId,
                  )
                : TopUpSuccessScreen(
                    package: widget.package,
                    mobileNumber: widget.mobileNumber,
                    fixedNumber: widget.fixedNumber,
                    ancienSolde: response.accountImpact?.balanceBefore ?? widget.soldeActuel,
                    transactionId: response.transactionId,
                  ),
            ),
          );
        } else {
          // Échec - afficher le message d'erreur de l'API
          debugPrint('TopUp - Échec: success=${response.success}, commandExecuted=${response.commandExecuted}');
          final errorMessage = response.message.isNotEmpty 
              ? response.message 
              : 'Erreur lors de la souscription au package';
          _showErrorMessage(errorMessage);
        }
      }
    } catch (e) {
      debugPrint('TopUp - Erreur souscription: $e');
      
      if (mounted) {
        String errorMessage = 'Erreur de connexion';
        
        if (e is TopUpException) {
          errorMessage = e.message;
        } else {
          errorMessage = 'Erreur inattendue: ${e.toString().replaceAll('Exception: ', '')}';
        }
        
        _showErrorMessage(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: ResponsiveSize.getWidth(8)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(8)),
        ),
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: _confirmerAchat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: "Confirmation d'achat",
        showAction: false,
        showCancelToHome: true,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type d'achat avec badge
              _buildPurchaseTypeBadge(),
              
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              
              // Entête avec icône animée
              _buildHeader(),
              
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              
              // Détails du package
              _buildPackageDetails(),
              
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              
              // Information sur le solde
              _buildSoldeInfo(),
              
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              
              // Information sur la ligne
              _buildLineInfo(),
              
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              
              // Boutons d'action
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseTypeBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
        vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
      ),
      decoration: BoxDecoration(
        color: _purchaseTypeColor.withOpacityValue(0.1),
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusL)),
        border: Border.all(
          color: _purchaseTypeColor.withOpacityValue(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _purchaseTypeIcon,
            color: _purchaseTypeColor,
            size: ResponsiveSize.getFontSize(18),
          ),
          SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
          Text(
            _purchaseTypeLabel,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              fontWeight: FontWeight.w600,
              color: _purchaseTypeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDataPackage = widget.package.isDataPackage;
    final iconData = isDataPackage ? Icons.data_usage : Icons.phone_in_talk;
    
    return Column(
      children: [
        // Icône principale avec animation
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
                decoration: BoxDecoration(
                  color: AppTheme.dtBlue.withOpacityValue(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.dtBlue.withOpacityValue(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  iconData,
                  color: AppTheme.dtBlue,
                  size: ResponsiveSize.getFontSize(40),
                ),
              ),
            );
          },
        ),
        
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
        
        // Titre et sous-titre
        Text(
          widget.package.packageCode,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(24),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),
        
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
        
        Text(
          _getPackageSubTitle(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageDetails() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailRow('Code du package', widget.package.packageCode),
          _buildDivider(),
          _buildDetailRow('Prix', widget.package.formattedPrice),
          _buildDivider(),
          
          // Afficher les détails selon le type
          if (widget.package.isDataPackage) ...[
            _buildDetailRow('Données', widget.package.formattedData),
            if (_isSubscription() && widget.package.formattedValidity.isNotEmpty) ...[
              _buildDivider(),
              _buildDetailRow('Validité', '${widget.package.formattedValidity} jours'),
            ],
          ] else if (widget.package.isVoicePackage) ...[
            _buildDetailRow('Minutes', widget.package.formattedVoice),
            if (_isSubscription() && widget.package.formattedValidity.isNotEmpty) ...[
              _buildDivider(),
              _buildDetailRow('Validité', '${widget.package.formattedValidity} jours'),
            ],
          ] else ...[
            _buildDetailRow('Contenu', widget.package.mainFeature),
          ],
        ],
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
            label,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: ResponsiveSize.getHeight(AppTheme.spacingS),
      color: Colors.grey[300],
    );
  }

  Widget _buildSoldeInfo() {
    final nouveauSolde = widget.soldeActuel - widget.package.price;
    final isLowBalance = nouveauSolde < 1000; // Seuil d'alerte
    
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      decoration: BoxDecoration(
        color: isLowBalance 
            ? Colors.orange.withOpacityValue(0.1)
            : AppTheme.dtYellow.withOpacityValue(0.1),
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        border: Border.all(
          color: isLowBalance 
              ? Colors.orange.withOpacityValue(0.3)
              : AppTheme.dtYellow.withOpacityValue(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLowBalance ? Icons.warning_amber : Icons.account_balance_wallet,
            color: isLowBalance ? Colors.orange : AppTheme.dtYellow,
            size: ResponsiveSize.getFontSize(24),
          ),
          SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solde actuel: ${widget.soldeActuel.toStringAsFixed(0)} FDJ',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(14),
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
                Text(
                  'Solde après achat: ${nouveauSolde.toStringAsFixed(0)} FDJ',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: isLowBalance ? Colors.orange : AppTheme.dtBlue,
                  ),
                ),
                if (isLowBalance) ...[
                  SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
                  Text(
                    'Solde faible après achat',
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(12),
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineInfo() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      decoration: BoxDecoration(
        color: AppTheme.dtYellow.withOpacityValue(0.1),
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        border: Border.all(
          color: AppTheme.dtYellow.withOpacityValue(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.phone,
            color: AppTheme.dtYellow,
            size: ResponsiveSize.getFontSize(24),
          ),
          SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ligne fixe destinataire',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(14),
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
                Text(
                  widget.fixedNumber,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dtBlue,
                  ),
                ),
                Text(
                  'Depuis votre mobile: ${widget.mobileNumber}',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(12),
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.dtBlue),
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveSize.getHeight(16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.getWidth(AppTheme.radiusM),
                ),
              ),
            ),
            child: Text(
              'Annuler',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtBlue,
              ),
            ),
          ),
        ),
        
        SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
        
        Expanded(
          child: ElevatedButton(
            onPressed: (_isLoading || widget.package.price > widget.soldeActuel) ? null : _confirmerAchat,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dtBlue,
              foregroundColor: AppTheme.dtYellow,
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveSize.getHeight(16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.getWidth(AppTheme.radiusM),
                ),
              ),
              elevation: _isLoading ? 0 : 2,
            ),
            child: _isLoading
                ? SizedBox(
                    width: ResponsiveSize.getWidth(20),
                    height: ResponsiveSize.getHeight(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtYellow),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: ResponsiveSize.getFontSize(18),
                      ),
                      SizedBox(width: ResponsiveSize.getWidth(8)),
                      Text(
                        'Confirmer l\'achat',
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}