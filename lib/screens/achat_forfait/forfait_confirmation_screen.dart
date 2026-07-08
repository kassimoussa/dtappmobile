// lib/screens/forfait_confirmation_screen.dart
import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/widgets/dt_button.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/extensions/color_extensions.dart';
import 'package:dtservices/models/forfait.dart';
import 'package:dtservices/routes/custom_route_transitions.dart';
import 'package:dtservices/services/purchase_offer_service.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:dtservices/services/biometric_auth_service.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/utils/validity_translator.dart';
import 'package:dtservices/enums/purchase_enums.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'forfait_success_screen.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/balance_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/pin_verification_bottom_sheet.dart';

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
  State<ForfaitConfirmationScreen> createState() =>
      _ForfaitConfirmationScreenState();
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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

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

  Future<void> _confirmerAchat() async {
    if (_isLoading) return;

    // Demander l'authentification biométrique avant de procéder
    final authResult = await BiometricAuthService.authenticateForPurchase(
      itemName: widget.forfait.nom,
      amount: widget.forfait.prix.toDouble(),
      currency: 'DJF',
    );

    if (!authResult.success) {
      if (!mounted) return;
      // Authentification biométrique échouée ou annulée
      final authProvider = context.read<AuthProvider>();

      // Si on n'a pas de PIN configuré, on bloque l'achat si l'erreur n'est pas "userCancel"
      if (!authProvider.hasPin) {
        if (authResult.errorType != BiometricAuthErrorType.userCancel) {
          _showErrorMessage(
            authResult.errorMessage ?? AppLocalizations.of(context)!.authFailed,
          );
        }
        return;
      }

      // Fallback: Demander le code PIN
      final phoneNumber = authProvider.phoneNumber;
      if (phoneNumber == null) return;

      final pinVerified = await PinVerificationBottomSheet.show(
        context,
        phoneNumber: phoneNumber,
        title: AppLocalizations.of(context)!.enterPinForPurchase,
      );

      // Si le code PIN n'a pas été validé (BottomSheet fermé ou erreur), on annule l'achat
      if (!pinVerified) {
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      // Appel API selon le type d'achat
      switch (_effectivePurchaseType) {
        case PurchaseType.personal:
          result = await PurchaseOfferService.purchaseOffer(
            widget.forfait.id,
            currentBalance: widget.soldeActuel,
          );
          break;
        case PurchaseType.gift:
          result = await PurchaseOfferService.purchaseOfferGift(
            widget.phoneNumber,
            widget.forfait.id,
            currentBalance: widget.soldeActuel,
          );
          break;
      }

      if (mounted) {
        if (result['succes'] == true) {
          // Succès - rafraîchir le solde et l'historique
          widget.onAchatReussi?.call();
          context.read<BalanceProvider>().refreshBalance();
          context.read<TransactionProvider>().refresh();

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
          _showErrorMessage(
            result['erreur'] ?? AppLocalizations.of(context)!.purchaseError,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(
          '${AppLocalizations.of(context)!.connectionError2}: ${e.toString().replaceAll('Exception: ', '')}',
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
            const Icon(Icons.error_outline, color: Colors.white),
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
          label: AppLocalizations.of(context)!.retry,
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
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            child: Container(
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppTheme.dtBlueO08, Colors.transparent],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                GlassAppBar(title: AppLocalizations.of(context)!.purchaseConfirmationTitle),
                Expanded(
                  child: AnimatedBuilder(
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
                      padding: EdgeInsets.all(
                        ResponsiveSize.getWidth(AppTheme.spacingL),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Entête avec icône animée
                          _buildHeader(),

                          SizedBox(
                            height: ResponsiveSize.getHeight(AppTheme.spacingL),
                          ),

                          // Détails de l'achat
                          _buildDetailsTable(),

                          SizedBox(
                            height: ResponsiveSize.getHeight(AppTheme.spacingL),
                          ),

                          // Boutons d'action
                          _buildActionButtons(),
                        ],
                      ),
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
                padding: EdgeInsets.all(
                  ResponsiveSize.getWidth(AppTheme.spacingL),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.dtBlueO10,
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
                  widget.forfait.type == 'internet'
                      ? Icons.wifi
                      : Icons.phone_android,
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
          AppLocalizations.of(context)!.validFor(
            translateValidity(
              widget.forfait.validite,
              AppLocalizations.of(context)!,
            ),
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTable() {
    final l10n = AppLocalizations.of(context)!;
    final nouveauSolde = widget.soldeActuel - widget.forfait.prix;
    final isLowBalance = nouveauSolde < 1000; // Seuil d'alerte

    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(l10n.recipientLabel, widget.phoneNumber),
          _buildDivider(),
          _buildDetailRow(l10n.priceLabel, '${widget.forfait.prix} DJF'),
          _buildDivider(),

          // Afficher Internet seulement s'il y en a
          if (widget.forfait.data != null) ...[
            _buildDetailRow(l10n.internetLabel, widget.forfait.data!),
            _buildDivider(),
          ],

          if (widget.forfait.type == 'combo' &&
              widget.forfait.minutes != null) ...[
            _buildDetailRow(l10n.callsLabel, '${widget.forfait.minutes} min'),
            _buildDivider(),
          ],

          if (widget.forfait.type == 'tempo' &&
              widget.forfait.minutes != null) ...[
            _buildDetailRow(l10n.minutesLabel, '${widget.forfait.minutes} min'),
            _buildDivider(),
          ],

          if (widget.forfait.type == 'combo' && widget.forfait.sms != null) ...[
            _buildDetailRow(l10n.smsLabel, '${widget.forfait.sms} SMS'),
            _buildDivider(),
          ],

          if (widget.forfait.type == 'tempo') ...[
            _buildDetailRow(l10n.validityLabel, l10n.weekendValidity),
          ] else ...[
            _buildDetailRow(
              l10n.validityLabel,
              translateValidity(widget.forfait.validite, l10n),
            ),
          ],

          _buildDivider(),
          _buildDetailRow(
            l10n.currentBalance,
            '${widget.soldeActuel.toStringAsFixed(0)} DJF',
          ),
          _buildDivider(),
          _buildDetailRow(
            l10n.balanceAfterPurchase,
            '${nouveauSolde.toStringAsFixed(0)} DJF',
            isTotal: true,
            isWarning: isLowBalance,
          ),

          if (isLowBalance) ...[
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.lowBalanceWarning,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(12),
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isWarning = false,
  }) {
    final valueColor = isWarning ? Colors.orange : AppTheme.dtBlue;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveSize.getHeight(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              color: isTotal ? valueColor : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              fontWeight: FontWeight.bold,
              color: valueColor,
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

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        // Bouton Annuler
        Expanded(
          child: DtButton.secondary(
            label: l10n.cancelAction,
            onPressed: _isLoading ? null : () => Navigator.pop(context),
          ),
        ),

        SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),

        // Bouton Payer
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmerAchat,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dtBlue,
              foregroundColor: Colors.white,
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
            child:
                _isLoading
                    ? SizedBox(
                      width: ResponsiveSize.getWidth(20),
                      height: ResponsiveSize.getHeight(20),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payment_rounded,
                          size: ResponsiveSize.getFontSize(18),
                          color: Colors.white,
                        ),
                        SizedBox(width: ResponsiveSize.getWidth(6)),
                        Text(
                          l10n.payAction,
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(16),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
