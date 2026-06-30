// lib/screens/topup/topup_recharge_success_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../../../constants/app_theme.dart';
import '../../../extensions/color_extensions.dart';
import '../../../routes/custom_route_transitions.dart';
import '../../../utils/responsive_size.dart';
import '../../core/main_screen.dart';
import '../../../generated/l10n/app_localizations.dart';

class TopUpRechargeSuccessScreen extends StatefulWidget {
  final double amount;
  final String mobileNumber;
  final String fixedNumber;
  final String transactionId;
  final Map<String, dynamic>? accountImpact;

  const TopUpRechargeSuccessScreen({
    super.key,
    required this.amount,
    required this.mobileNumber,
    required this.fixedNumber,
    required this.transactionId,
    this.accountImpact,
  });

  @override
  State<TopUpRechargeSuccessScreen> createState() =>
      _TopUpRechargeSuccessScreenState();
}

class _TopUpRechargeSuccessScreenState extends State<TopUpRechargeSuccessScreen>
    with SingleTickerProviderStateMixin {
  late Timer _redirectTimer;
  int _remainingSeconds = 5;
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

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  void _startRedirectTimer() {
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        CustomRouteTransitions.fadeRoute(page: const MainScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _redirectTimer.cancel();
    _animationController.dispose();
    super.dispose();
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
                _buildGlassAppBar(context),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animation d'icône de succès
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: EdgeInsets.all(
                      ResponsiveSize.getWidth(AppTheme.spacingXL),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.dtBlueO10,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.dtBlueO30,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: AppTheme.dtBlue,
                      size: ResponsiveSize.getFontSize(64),
                    ),
                  ),
                ),

                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),

                // Titre de succès
                Text(
                  AppLocalizations.of(context)!.rechargeSuccessTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(28),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dtBlue,
                  ),
                ),

                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),

                Text(
                  AppLocalizations.of(context)!.rechargeSuccessMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    color: Colors.grey[600],
                  ),
                ),

                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),

                // Détails de la recharge
                _buildRechargeDetails(),

                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),

                // Impact sur les comptes
                if (widget.accountImpact != null) _buildAccountImpact(),

                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),

                // Boutons d'action
                _buildActionButtons(),

                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

                // Compte à rebours
                _buildCountdown(),
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

  Widget _buildGlassAppBar(BuildContext context) {
    return Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(12),
            vertical: ResponsiveSize.getHeight(12),
          ),
          decoration: const BoxDecoration(
            color: AppTheme.white95,
            border: Border(bottom: BorderSide(color: AppTheme.dtBlueO10, width: 0.5)),
          ),
          child: Row(
            children: [
              SizedBox(width: ResponsiveSize.getWidth(8)),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.rechargeSuccessTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: ResponsiveSize.getFontSize(22),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildRechargeDetails() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
      decoration: BoxDecoration(
        color: AppTheme.dtYellow.withOpacityValue(0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
        border: Border.all(color: AppTheme.dtYellow.withOpacityValue(0.3)),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            l10n.transferAmount,
            '${widget.amount.toStringAsFixed(0)} DJF',
          ),
          Divider(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          _buildDetailRow(l10n.fromMobileSource, widget.mobileNumber),
          Divider(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          _buildDetailRow(l10n.toFixedDestination, widget.fixedNumber),
          Divider(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          _buildDetailRow(l10n.transactionId, widget.transactionId),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(14),
            color: Colors.grey[600],
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountImpact() {
    final impact = widget.accountImpact!;
    final l10n = AppLocalizations.of(context)!;
    final mobileAfter = impact['mobile_balance_after'] ?? 0.0;
    final fixedAfter = impact['fixed_balance_after'] ?? 0.0;
    final formattedMobileAfter =
        impact['formatted_mobile_after'] ??
        '${mobileAfter.toStringAsFixed(0)} DJF';
    final formattedFixedAfter =
        impact['formatted_fixed_after'] ??
        '${fixedAfter.toStringAsFixed(0)} DJF';

    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
      decoration: BoxDecoration(
        color: AppTheme.dtBlueO10,
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
        border: Border.all(color: AppTheme.dtBlueO30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.accountImpact,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlue,
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          _buildDetailRow(l10n.newMobileBalance, formattedMobileAfter),
          Divider(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          _buildDetailRow(l10n.newFixedBalance, formattedFixedAfter),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _navigateToHome,
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
              l10n.returnHome,
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
            onPressed: () {
              // TODO: Implémenter nouvelle recharge
              _navigateToHome();
            },
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
            ),
            child: Text(
              l10n.newRecharge,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
        vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusS),
        ),
      ),
      child: Text(
        AppLocalizations.of(context)!.autoRedirect(_remainingSeconds),
        style: TextStyle(
          fontSize: ResponsiveSize.getFontSize(12),
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
