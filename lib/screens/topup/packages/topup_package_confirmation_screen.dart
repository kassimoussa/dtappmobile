// lib/screens/topup/topup_package_confirmation_screen.dart
import 'package:flutter/material.dart';

import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../models/topup_balance.dart';
import '../../../services/user_session.dart';
import '../../../services/topup_api_service.dart';
import '../../../routes/custom_route_transitions.dart';
import '../../../extensions/color_extensions.dart';
import '../../../exceptions/topup_exception.dart';
import '../../../generated/l10n/app_localizations.dart';
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

bool _isSubscription() {
    return widget.packageType == 1 || widget.packageType == 2;
  }

  String _getPackageSubTitle() {
    final l10n = AppLocalizations.of(context)!;
    if (widget.package.description.isNotEmpty) {
      return widget.package.description;
    }

    final isDataPackage = widget.package.isDataPackage;
    if (_isSubscription()) {
      return isDataPackage ? l10n.dataSubscription : l10n.voiceSubscription;
    } else {
      return isDataPackage ? l10n.dataPackageAddon : l10n.voicePackageAddon;
    }
  }

  Future<void> _confirmerAchat() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;

    // Vérifier le solde avant de procéder
    if (widget.package.price > widget.soldeActuel) {
      _showErrorMessage(l10n.insufficientBalanceError);
      return;
    }

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
      );

      debugPrint(
        'TopUp - Réponse API: success=${response.success}, transaction=${response.transactionId}',
      );
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
              decoration: BoxDecoration(
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
                _buildGlassAppBar(
                  context,
                  AppLocalizations.of(context)!.confirmPurchaseTitle,
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

  Widget _buildGlassAppBar(BuildContext context, String title) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(12),
        vertical: ResponsiveSize.getHeight(12),
      ),
      decoration: const BoxDecoration(
        color: AppTheme.white95,
        border: Border(
          bottom: BorderSide(color: AppTheme.dtBlueO10, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.white50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.dtBlueDark,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: ResponsiveSize.getWidth(16)),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.headingStyle.copyWith(
                fontSize: ResponsiveSize.getFontSize(22),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: ResponsiveSize.getWidth(8)),
          InkWell(
            onTap:
                () => Navigator.of(context).popUntil((route) => route.isFirst),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSize.getWidth(12),
                vertical: ResponsiveSize.getHeight(8),
              ),
              decoration: BoxDecoration(
                color: AppTheme.white50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white),
              ),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  color: AppTheme.dtBlueDark,
                  fontSize: ResponsiveSize.getFontSize(13),
                  fontWeight: FontWeight.w600,
                ),
              ),
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

  Widget _buildDetailsTable() {
    final l10n = AppLocalizations.of(context)!;
    final nouveauSolde = widget.soldeActuel - widget.package.price;
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
          _buildDetailRow(l10n.packageCode, widget.package.packageCode),
          _buildDivider(),
          _buildDetailRow(l10n.price, widget.package.formattedPrice),
          _buildDivider(),

          // Afficher les détails selon le type
          if (widget.package.isDataPackage) ...[
            _buildDetailRow(l10n.dataType, widget.package.formattedData),
            if (_isSubscription() &&
                widget.package.formattedValidity.isNotEmpty) ...[
              _buildDivider(),
              _buildDetailRow(
                l10n.validity,
                '${widget.package.formattedValidity} ${l10n.days}',
              ),
            ],
          ] else if (widget.package.isVoicePackage) ...[
            _buildDetailRow(l10n.voiceType, widget.package.formattedVoice),
            if (_isSubscription() &&
                widget.package.formattedValidity.isNotEmpty) ...[
              _buildDivider(),
              _buildDetailRow(
                l10n.validity,
                '${widget.package.formattedValidity} ${l10n.days}',
              ),
            ],
          ] else ...[
            _buildDetailRow(l10n.content, widget.package.mainFeature),
          ],

          _buildDivider(),
          _buildDetailRow(l10n.fixedLineRecipient, widget.fixedNumber),
          _buildDivider(),
          _buildDetailRow(l10n.fromMobile, widget.mobileNumber),

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
              l10n.cancel,
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
            onPressed:
                (_isLoading || widget.package.price > widget.soldeActuel)
                    ? null
                    : _confirmerAchat,
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
            child:
                _isLoading
                    ? SizedBox(
                      width: ResponsiveSize.getWidth(20),
                      height: ResponsiveSize.getHeight(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.dtYellow,
                        ),
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
