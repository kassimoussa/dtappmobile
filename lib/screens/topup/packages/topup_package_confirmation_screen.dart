// lib/screens/topup/topup_package_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:dtservices/widgets/dt_button.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../models/topup_balance.dart';
import '../../../services/topup_api_service.dart';
import '../../../routes/custom_route_transitions.dart';
import '../../../extensions/color_extensions.dart';
import '../../../exceptions/topup_exception.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../providers/balance_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../services/payment_auth_guard.dart';
import 'topup_success_screen.dart';
import '../subscription/topup_subscription_success_screen.dart';

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
  State<TopUpPackageConfirmationScreen> createState() =>
      _TopUpPackageConfirmationScreenState();
}

class _TopUpPackageConfirmationScreenState
    extends State<TopUpPackageConfirmationScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

bool _isSubscription() {
    return widget.packageType == 1 || widget.packageType == 2;
  }

  /// Duree de validite en jours : `validity_days` quand l'API le renseigne,
  /// sinon les chiffres extraits de `formatted_validity`, qui peut valoir
  /// "Non specifiee".
  int get _validityDays {
    if (widget.package.validityDays > 0) return widget.package.validityDays;
    final digits = widget.package.formattedValidity.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    return int.tryParse(digits) ?? 0;
  }

  Future<void> _confirmerAchat() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;

    // Vérifier le solde avant de procéder
    if (widget.package.price > widget.soldeActuel) {
      _showErrorMessage(l10n.insufficientBalanceError);
      return;
    }

    // Authentification exigée avant tout débit, selon « Paramètres de paiement ».
    final authorized = await PaymentAuthGuard.authorize(
      context,
      itemName: widget.package.displayName,
      amount: widget.package.price.toDouble(),
      currency: 'DJF',
      pinTitle: l10n.enterPinForPurchase,
    );
    if (!authorized || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint(
        'TopUp - Début souscription package: ${widget.package.packageCode}',
      );

      // Appel à l'API pour souscrire au package TopUp (le statut a déjà été vérifié)
      final response = await TopUpApi.instance.subscribePackage(
        msisdn: widget.mobileNumber,
        isdn: widget.fixedNumber,
        packageCode: widget.package.packageCode,
        currentBalance: widget.soldeActuel,
        packagePrice: widget.package.price,
        packageName: widget.package.displayName,
        packageData: widget.package.isDataPackage ? widget.package.formattedData : null,
        packageVoice: widget.package.isVoicePackage ? widget.package.formattedVoice : null,
        packageValidity: widget.package.validityDays > 0 ? widget.package.validityDays : null,
      );

      debugPrint(
        'TopUp - Réponse API: success=${response.success}, transaction=${response.transactionId}',
      );
      debugPrint('TopUp - commandExecuted=${response.commandExecuted}');
      debugPrint('TopUp - message=${response.message}');

      if (mounted) {
        if (response.success) {
          debugPrint('TopUp - Navigation vers success screen...');
          // Succès - rafraîchir le solde et l'historique
          context.read<BalanceProvider>().refreshBalance();
          context.read<TransactionProvider>().refresh();

          // naviguer vers l'écran de succès approprié
          final isSubscription = _isSubscription();

          Navigator.pushReplacement(
            context,
            CustomRouteTransitions.fadeRoute(
              page:
                  isSubscription
                      ? TopUpSubscriptionSuccessScreen(
                        subscription: widget.package,
                        mobileNumber: widget.mobileNumber,
                        fixedNumber: widget.fixedNumber,
                        ancienSolde:
                            response.accountImpact?.balanceBefore ??
                            widget.soldeActuel,
                        transactionId: response.transactionId,
                      )
                      : TopUpSuccessScreen(
                        package: widget.package,
                        mobileNumber: widget.mobileNumber,
                        fixedNumber: widget.fixedNumber,
                        ancienSolde:
                            response.accountImpact?.balanceBefore ??
                            widget.soldeActuel,
                        transactionId: response.transactionId,
                      ),
            ),
          );
        } else {
          // Échec - afficher le message d'erreur de l'API
          debugPrint(
            'TopUp - Échec: success=${response.success}, commandExecuted=${response.commandExecuted}',
          );
          final errorMessage =
              response.message.isNotEmpty
                  ? response.message
                  : l10n.subscriptionError;
          _showErrorMessage(errorMessage);
        }
      }
    } catch (e) {
      debugPrint('TopUp - Erreur souscription: $e');

      if (mounted) {
        String errorMessage = l10n.connectionError;

        if (e is TopUpException) {
          errorMessage = e.message;
        } else {
          errorMessage =
              '${l10n.unexpectedError}: ${e.toString().replaceAll('Exception: ', '')}';
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
                GlassAppBar(title: AppLocalizations.of(context)!.confirmPurchaseTitle, actions: [GlassAppBarAction(icon: Icons.close, onTap: () => Navigator.of(context).popUntil((route) => route.isFirst))],
                ),
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
                          _buildHeader(),
                          SizedBox(
                            height: ResponsiveSize.getHeight(AppTheme.spacingL),
                          ),
                          _buildDetailsTable(),
                          SizedBox(
                            height: ResponsiveSize.getHeight(AppTheme.spacingL),
                          ),
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
                  iconData,
                  color: AppTheme.dtBlue,
                  size: ResponsiveSize.getFontSize(40),
                ),
              ),
            );
          },
        ),

        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

        // Titre : le detail du package est porte par le tableau ci-dessous
        Text(
          widget.package.packageCode,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(24),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),

      ],
    );
  }

  Widget _buildDetailsTable() {
    final l10n = AppLocalizations.of(context)!;
    final nouveauSolde = widget.soldeActuel - widget.package.price;
    final isLowBalance = nouveauSolde < 1000; // Seuil d'alerte

    // Un package combo porte a la fois de la data et de la voix : les deux
    // lignes doivent s'afficher, pas seulement la premiere.
    final data = widget.package.formattedData;
    final voice = widget.package.formattedVoice;
    final showData =
        (widget.package.isDataPackage || widget.package.dataUnlimited) &&
        data.isNotEmpty;
    final showVoice =
        (widget.package.isVoicePackage || widget.package.voiceFixedUnlimited) &&
        voice.isNotEmpty;
    final validityDays = _validityDays;

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
          // Le code du package est deja affiche en entete, on ne le repete pas
          // ici (meme structure que l'achat de forfait mobile).
          _buildDetailRow(l10n.price, widget.package.formattedPrice),

          if (showData) ...[
            _buildDivider(),
            _buildDetailRow(l10n.dataType, data),
          ],

          if (showVoice) ...[
            _buildDivider(),
            _buildDetailRow(l10n.voiceType, voice),
          ],

          if (!showData && !showVoice) ...[
            _buildDivider(),
            _buildDetailRow(l10n.content, widget.package.mainFeature),
          ],

          if (validityDays > 0) ...[
            _buildDivider(),
            _buildDetailRow(l10n.validity, l10n.validityDays(validityDays)),
          ],

          _buildDivider(),
          _buildDetailRow(l10n.fixedLineLabel, widget.fixedNumber),
          _buildDivider(),
          _buildDetailRow(l10n.mobileLineLabel, widget.mobileNumber),

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
    // Libelle et valeur partagent la largeur disponible : un libelle traduit
    // trop long ou une valeur trop longue est tronque au lieu de deborder.
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveSize.getHeight(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                color: isTotal ? valueColor : Colors.grey[600],
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
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
        Expanded(
          child: DtButton.secondary(
            label: l10n.cancel,
            onPressed: _isLoading ? null : () => Navigator.pop(context),
          ),
        ),

        SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),

        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed:
                (_isLoading || widget.package.price > widget.soldeActuel)
                    ? null
                    : _confirmerAchat,
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.dtYellow,
                        ),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: ResponsiveSize.getFontSize(18),
                        ),
                        SizedBox(width: ResponsiveSize.getWidth(6)),
                        Flexible(
                          child: Text(
                            l10n.confirmPurchaseAction,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: ResponsiveSize.getFontSize(16),
                              fontWeight: FontWeight.bold,
                            ),
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
