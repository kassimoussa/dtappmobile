// lib/screens/achat_forfait/forfait_success_screen.dart
import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/extensions/color_extensions.dart';
import 'package:dtservices/models/forfait.dart';
import 'package:dtservices/routes/custom_route_transitions.dart';
import 'package:dtservices/screens/core/main_screen.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../generated/l10n/app_localizations.dart';
import '../../utils/validity_translator.dart';

class ForfaitSuccessScreen extends StatefulWidget {
  final Forfait forfait;
  final String phoneNumber;
  final double ancienSolde;

  const ForfaitSuccessScreen({
    super.key,
    required this.forfait,
    required this.phoneNumber,
    required this.ancienSolde,
  });

  @override
  State<ForfaitSuccessScreen> createState() => _ForfaitSuccessScreenState();
}

class _ForfaitSuccessScreenState extends State<ForfaitSuccessScreen>
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
          if (_remainingSeconds > 1) {
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
    final nouveauSolde = widget.ancienSolde - widget.forfait.prix;
    final l10n = AppLocalizations.of(context)!;

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
                  _buildGlassAppBar(context, l10n.purchaseSuccessTitle),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
                          child: Column(
                            children: [
                              SizedBox(height: ResponsiveSize.getHeight(20)),
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
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
                              Container(
                                width: double.infinity,
                                margin: EdgeInsets.symmetric(
                                  vertical: ResponsiveSize.getHeight(32),
                                  horizontal: ResponsiveSize.getWidth(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      l10n.purchaseSuccessTitle,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: ResponsiveSize.getFontSize(24),
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.dtBlue,
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveSize.getHeight(16)),
                                    Text(
                                      l10n.purchaseSuccessMessage(widget.forfait.nom),
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
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                                    border: Border.all(color: Colors.grey[100]!),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      _buildDetailRow(l10n.packageLabel, widget.forfait.nom),
                                      _buildDivider(),
                                      _buildDetailRow(l10n.recipientLabel, widget.phoneNumber),
                                      _buildDivider(),
                                      _buildDetailRow(l10n.priceLabel, '${widget.forfait.prix} FDJ'),
                                      _buildDivider(),
                                      _buildDetailRow(l10n.newBalance, '${nouveauSolde.toStringAsFixed(0)} DJF'),
                                      if (widget.forfait.data != null) ...[
                                        _buildDivider(),
                                        _buildDetailRow(l10n.internetLabel, widget.forfait.data!),
                                      ],
                                      _buildDivider(),
                                      _buildDetailRow(l10n.validityLabel, translateValidity(widget.forfait.validite, l10n)),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: ResponsiveSize.getHeight(30)),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _redirectToHome,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.dtBlueDark,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: ResponsiveSize.getHeight(16)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(12)),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.home_rounded),
                                            SizedBox(width: ResponsiveSize.getWidth(8)),
                                            Text(
                                              l10n.homeAction,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveSize.getHeight(16)),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ResponsiveSize.getWidth(16),
                                        vertical: ResponsiveSize.getHeight(8),
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.dtBlueDark.withOpacityValue(0.05),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.timer_outlined, size: 16, color: AppTheme.dtBlueDark.withOpacityValue(0.6)),
                                          SizedBox(width: 8),
                                          Text(
                                            l10n.autoRedirect(_remainingSeconds),
                                            style: TextStyle(
                                              fontSize: ResponsiveSize.getFontSize(12),
                                              color: AppTheme.dtBlueDark.withOpacityValue(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
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

  Widget _buildGlassAppBar(BuildContext context, String title) {
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
                  title,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveSize.getHeight(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlueDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey[100]);
  }
}
