// lib/screens/topup/topup_success_screen.dart
import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'dart:async';

import '../../../constants/app_theme.dart';
import '../../../extensions/color_extensions.dart';
import '../../../models/topup_balance.dart';
import '../../../routes/custom_route_transitions.dart';
import '../../../utils/responsive_size.dart';
import '../../core/main_screen.dart';
import '../../../generated/l10n/app_localizations.dart';

class TopUpSuccessScreen extends StatefulWidget {
  final TopUpPackage package;
  final String mobileNumber;
  final String fixedNumber;
  final double ancienSolde;
  final String transactionId;

  const TopUpSuccessScreen({
    super.key,
    required this.package,
    required this.mobileNumber,
    required this.fixedNumber,
    required this.ancienSolde,
    required this.transactionId,
  });

  @override
  State<TopUpSuccessScreen> createState() => _TopUpSuccessScreenState();
}

class _TopUpSuccessScreenState extends State<TopUpSuccessScreen>
    with SingleTickerProviderStateMixin {
  late Timer _redirectTimer;
  int _remainingSeconds = 5; // Compte à rebours de 5 secondes
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startRedirectTimer();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  void _startRedirectTimer() {
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _redirectTimer.cancel();
            _redirectToHome();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _redirectTimer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _redirectToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      CustomRouteTransitions.fadeRoute(page: const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    final nouveauSolde = widget.ancienSolde - widget.package.price;

    return PopScope(
      canPop: false,
      child: Scaffold(
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
                    colors: [
                      AppTheme.dtBlueO08,
                      Colors.transparent,
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  GlassAppBar(title: AppLocalizations.of(context)!.purchaseSuccessTitle, showBack: false,
                  ),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.all(
                            ResponsiveSize.getWidth(AppTheme.spacingL),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: ResponsiveSize.getHeight(20)),

                              // Icône de succès avec animation
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  padding: EdgeInsets.all(
                                    ResponsiveSize.getWidth(AppTheme.spacingL),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dtBlueO10,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.dtBlueO30,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.dtBlue.withOpacityValue(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: AppTheme.dtBlue,
                                    size: ResponsiveSize.getFontSize(60),
                                  ),
                                ),
                              ),
                              // Container fixe pour les textes
                              Container(
                                width: double.infinity,
                                margin: EdgeInsets.symmetric(
                                  vertical: ResponsiveSize.getHeight(32),
                                  horizontal: ResponsiveSize.getWidth(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.topupPurchaseSuccess,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: ResponsiveSize.getFontSize(24),
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.dtBlue,
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveSize.getHeight(16)),
                                    Text(
                                      AppLocalizations.of(context)!.packageActivatedMessage(
                                        widget.package.displayName,
                                      ),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: ResponsiveSize.getFontSize(14),
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Détails du package avec fade
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(
                                    ResponsiveSize.getWidth(AppTheme.spacingM),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveSize.getWidth(AppTheme.radiusM),
                                    ),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildDetailRow(
                                        AppLocalizations.of(context)!.packageLabel,
                                        widget.package.displayName,
                                      ),
                                      // Le n° de transaction n'est pas affiché ici :
                                      // la réponse d'achat porte `transaction_id`
                                      // (référence de requête « dtapp… »), alors que
                                      // l'historique affiche `transaction_no`, le
                                      // numéro connu de l'opérateur. Montrer le
                                      // premier donnait au client une référence
                                      // introuvable par le service client.
                                      _buildDivider(),
                                      _buildDetailRow(
                                        AppLocalizations.of(context)!.fixedLineLabel,
                                        widget.fixedNumber,
                                      ),
                                      _buildDivider(),
                                      _buildDetailRow(
                                        AppLocalizations.of(context)!.mobileLineLabel,
                                        widget.mobileNumber,
                                      ),
                                      _buildDivider(),
                                      _buildDetailRow(
                                        AppLocalizations.of(context)!.price,
                                        widget.package.formattedPrice,
                                      ),
                                      _buildDivider(),
                                      _buildDetailRow(
                                        AppLocalizations.of(context)!.newMobileBalance,
                                        '${nouveauSolde.toStringAsFixed(0)} DJF',
                                      ),
                                      if (widget.package.isDataPackage) ...[
                                        _buildDivider(),
                                        _buildDetailRow(
                                          AppLocalizations.of(context)!.internetLabel,
                                          widget.package.formattedData,
                                        ),
                                      ],
                                      if (widget.package.isVoicePackage) ...[
                                        _buildDivider(),
                                        _buildDetailRow(
                                          AppLocalizations.of(context)!.minutesLabel,
                                          widget.package.formattedVoice,
                                        ),
                                      ],
                                      _buildDivider(),
                                      _buildDetailRow(
                                        AppLocalizations.of(context)!.validityLabel,
                                        widget.package.formattedValidity,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: ResponsiveSize.getHeight(20)),
                              // Bouton retour accueil avec fade
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _redirectToHome,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.dtBlue,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: ResponsiveSize.getWidth(AppTheme.spacingL),
                                            vertical: ResponsiveSize.getHeight(16),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              ResponsiveSize.getWidth(AppTheme.radiusM),
                                            ),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.home, size: ResponsiveSize.getFontSize(18)),
                                            SizedBox(width: ResponsiveSize.getWidth(8)),
                                            Text(
                                              AppLocalizations.of(context)!.returnHome,
                                              style: TextStyle(
                                                fontSize: ResponsiveSize.getFontSize(16),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveSize.getHeight(16)),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
                                        vertical: ResponsiveSize.getHeight(8),
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.dtBlueO10,
                                        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(20)),
                                        border: Border.all(color: AppTheme.dtBlueO30),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.timer, color: AppTheme.dtBlue, size: ResponsiveSize.getFontSize(16)),
                                          SizedBox(width: ResponsiveSize.getWidth(6)),
                                          Text(
                                            AppLocalizations.of(context)!.autoRedirect(_remainingSeconds),
                                            style: TextStyle(
                                              fontSize: ResponsiveSize.getFontSize(12),
                                              color: AppTheme.dtBlue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveSize.getHeight(24)),
                                    Container(
                                      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
                                      decoration: BoxDecoration(
                                        color: AppTheme.dtYellow.withOpacityValue(0.1),
                                        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                                        border: Border.all(color: AppTheme.dtYellow.withOpacityValue(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.phone, color: AppTheme.dtBlue, size: ResponsiveSize.getFontSize(18)),
                                          SizedBox(width: ResponsiveSize.getWidth(8)),
                                          Expanded(
                                            child: Text(
                                              AppLocalizations.of(context)!.packageActivatedFixed(widget.fixedNumber),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: ResponsiveSize.getFontSize(12),
                                                color: AppTheme.dtBlue,
                                                fontWeight: FontWeight.w500,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            label,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(13),
              color: Colors.grey[600],
            ),
          ),
          // Sans cet écart, une valeur longue (le n° de transaction) vient
          // coller son libellé.
          SizedBox(width: ResponsiveSize.getWidth(12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtBlue,
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
}
