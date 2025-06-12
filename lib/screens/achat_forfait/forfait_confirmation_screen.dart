// lib/screens/forfait_confirmation_screen.dart
import 'package:dtapp3/constants/app_theme.dart';
import 'package:dtapp3/extensions/color_extensions.dart';
import 'package:dtapp3/models/forfait.dart';
import 'package:dtapp3/routes/custom_route_transitions.dart';
import 'package:dtapp3/services/purchase_offer_service.dart';
import 'package:dtapp3/services/user_session.dart';
import 'package:dtapp3/utils/responsive_size.dart';
import 'package:dtapp3/widgets/appbar_widget.dart';
import 'package:dtapp3/enums/purchase_enums.dart';
import 'package:flutter/material.dart'; 
import 'forfait_success_screen.dart';

class ForfaitConfirmationScreen extends StatefulWidget {
  final Forfait forfait;
  final String phoneNumber;
  final double soldeActuel;
  final VoidCallback? onAchatReussi;
  final PurchaseType purchaseType;

  const ForfaitConfirmationScreen({
    super.key,
    required this.forfait,
    required this.phoneNumber,
    required this.soldeActuel,
    this.onAchatReussi,
    this.purchaseType = PurchaseType.personal,
  });

  @override
  State<ForfaitConfirmationScreen> createState() => _ForfaitConfirmationScreenState();
}

class _ForfaitConfirmationScreenState extends State<ForfaitConfirmationScreen>
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

  // Détermine automatiquement le type d'achat
  PurchaseType get _effectivePurchaseType {
    if (widget.purchaseType != PurchaseType.personal) {
      return widget.purchaseType;
    }
    
    // Auto-détection basée sur le numéro
    if (_userPhoneNumber != null && widget.phoneNumber != _userPhoneNumber) {
      return PurchaseType.gift;
    }
    
    return PurchaseType.personal;
  }

  String get _purchaseTypeLabel {
    switch (_effectivePurchaseType) {
      case PurchaseType.personal:
        return 'Achat pour mon numéro';
      case PurchaseType.gift:
        return 'Achat cadeau';
    }
  }

  IconData get _purchaseTypeIcon {
    switch (_effectivePurchaseType) {
      case PurchaseType.personal:
        return Icons.person;
      case PurchaseType.gift:
        return Icons.card_giftcard;
    }
  }

  Color get _purchaseTypeColor {
    switch (_effectivePurchaseType) {
      case PurchaseType.personal:
        return AppTheme.dtBlue;
      case PurchaseType.gift:
        return Colors.orange;
    }
  }

  Future<void> _confirmerAchat() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      Map<String, dynamic> result;
      
      // Appel API selon le type d'achat
      switch (_effectivePurchaseType) {
        case PurchaseType.personal:
          result = await PurchaseOfferService.purchaseOffer(widget.forfait.id);
          break;
        case PurchaseType.gift:
          result = await PurchaseOfferService.purchaseOfferGift(
            widget.phoneNumber, 
            widget.forfait.id
          );
          break;
      }
      
      if (mounted) {
        if (result['succes'] == true) {
          // Succès - navigation avec animation
          widget.onAchatReussi?.call();
          
          Navigator.pushReplacement(
            context,
            CustomRouteTransitions.fadeScaleRoute(
              page: ForfaitSuccessScreen(
                forfait: widget.forfait,
                phoneNumber: widget.phoneNumber,
                ancienSolde: widget.soldeActuel,
              ),
            ),
          );
        } else {
          // Erreur depuis l'API
          _showErrorMessage(result['erreur'] ?? 'Erreur lors de l\'achat');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(
          'Erreur de connexion: ${e.toString().replaceAll('Exception: ', '')}'
        );
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
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
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
        duration: const Duration(seconds: 1),
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
        value: widget.soldeActuel,
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
              
              // Détails du forfait
              _buildForfaitDetails(),
              
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              
              // Information sur le solde
              _buildSoldeInfo(),
              
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
                  widget.forfait.type == 'internet' ? Icons.wifi : Icons.phone_android,
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
          widget.forfait.nom,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(24),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),
        
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
        
        Text(
          'Valide pendant ${widget.forfait.validite}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildForfaitDetails() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailRow('Numéro destinataire', widget.phoneNumber),
          _buildDivider(),
          _buildDetailRow('Prix', '${widget.forfait.prix} DJF'),
          _buildDivider(),
          
          // Afficher Internet seulement s'il y en a
          if (widget.forfait.data != null) ...[
            _buildDetailRow('Internet', widget.forfait.data!),
            _buildDivider(),
          ],
          
          if (widget.forfait.type == 'combo' && widget.forfait.minutes != null) ...[
            _buildDetailRow('Appels', '${widget.forfait.minutes} min'),
            _buildDivider(),
          ],
          
          if (widget.forfait.type == 'tempo' && widget.forfait.minutes != null) ...[
            _buildDetailRow('Minutes d\'appels', '${widget.forfait.minutes} min'),
            _buildDivider(),
          ],
          
          if (widget.forfait.type == 'combo' && widget.forfait.sms != null) ...[
            _buildDetailRow('SMS', '${widget.forfait.sms} SMS'),
            _buildDivider(),
          ], 

          if(widget.forfait.type == 'tempo') ... [
            _buildDetailRow('Validité', 'Week-end'),
          ]else ...[
            _buildDetailRow('Validité', widget.forfait.validite),
          ]
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
    final nouveauSolde = widget.soldeActuel - widget.forfait.prix;
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
            onPressed: _isLoading ? null : _confirmerAchat,
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