// lib/screens/topup/topup_subscription_success_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';

import '../../../constants/app_theme.dart';
import '../../../extensions/color_extensions.dart';
import '../../../models/topup_balance.dart';
import '../../../routes/custom_route_transitions.dart';
import '../../../utils/responsive_size.dart';
import '../../main_screen.dart';

class TopUpSubscriptionSuccessScreen extends StatefulWidget {
  final TopUpPackage subscription;
  final String mobileNumber;
  final String fixedNumber;
  final double ancienSolde;
  final String transactionId;

  const TopUpSubscriptionSuccessScreen({
    super.key,
    required this.subscription,
    required this.mobileNumber,
    required this.fixedNumber,
    required this.ancienSolde,
    required this.transactionId,
  });

  @override
  State<TopUpSubscriptionSuccessScreen> createState() => _TopUpSubscriptionSuccessScreenState();
}

class _TopUpSubscriptionSuccessScreenState extends State<TopUpSubscriptionSuccessScreen>
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

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

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
      CustomRouteTransitions.fadeRoute(
        page: const MainScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    final nouveauSolde = widget.ancienSolde - widget.subscription.price;
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.dtBlue,
          title: Text(
            'Souscription réussie',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveSize.getFontSize(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: ResponsiveSize.getHeight(20)),
                  
                  // Icône de succès avec animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
                      decoration: BoxDecoration(
                        color: AppTheme.dtBlue.withOpacityValue(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.dtBlue.withOpacityValue(0.3),
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
                        Icons.subscriptions,
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
                        // Titre
                        Text(
                          'Souscription TopUp réussie !',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(24),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dtBlue,
                          ),
                        ),
                        
                        SizedBox(height: ResponsiveSize.getHeight(16)),
                        
                        // Message de confirmation
                        Text(
                          'La souscription ${widget.subscription.displayName} a été activée avec succès sur votre ligne fixe',
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
                  
                  // Détails de la souscription avec fade
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDetailRow('Souscription', widget.subscription.displayName),
                          _buildDivider(),
                          _buildDetailRow('ID Transaction', widget.transactionId),
                          _buildDivider(),
                          _buildDetailRow('Ligne fixe', widget.fixedNumber),
                          _buildDivider(),
                          _buildDetailRow('Ligne mobile', widget.mobileNumber),
                          _buildDivider(),
                          _buildDetailRow('Prix', widget.subscription.formattedPrice),
                          _buildDivider(),
                          _buildDetailRow('Nouveau solde mobile', '${nouveauSolde.toStringAsFixed(0)} DJF'),
                          
                          if (widget.subscription.isDataPackage) ...[
                            _buildDivider(),
                            _buildDetailRow('Internet', widget.subscription.formattedData),
                          ],
                          
                          if (widget.subscription.isVoicePackage) ...[
                            _buildDivider(),
                            _buildDetailRow('Minutes', widget.subscription.formattedVoice),
                          ],
                          
                          _buildDivider(),
                          _buildDetailRow('Validité', widget.subscription.formattedValidity),
                          
                          if (widget.subscription.voiceFixedUnlimited) ...[
                            _buildDivider(),
                            _buildDetailRow('Appels vers fixes', 'Illimités'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: ResponsiveSize.getHeight(20)),
                  
                  // Bouton pour retourner immédiatement à l'accueil avec fade
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
                              foregroundColor: AppTheme.dtYellow,
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveSize.getWidth(AppTheme.spacingL),
                                vertical: ResponsiveSize.getHeight(16),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                              ),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.home,
                                  size: ResponsiveSize.getFontSize(18),
                                ),
                                SizedBox(width: ResponsiveSize.getWidth(8)),
                                Text(
                                  'Retour à l\'accueil',
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
                        
                        // Compte à rebours
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
                            vertical: ResponsiveSize.getHeight(8),
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.dtBlue.withOpacityValue(0.1),
                            borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(20)),
                            border: Border.all(
                              color: AppTheme.dtBlue.withOpacityValue(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer,
                                color: AppTheme.dtBlue,
                                size: ResponsiveSize.getFontSize(16),
                              ),
                              SizedBox(width: ResponsiveSize.getWidth(6)),
                              Text(
                                'Redirection automatique dans $_remainingSeconds s',
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
                        
                        // Message de confirmation souscription
                        Container(
                          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
                          decoration: BoxDecoration(
                            color: AppTheme.dtYellow.withOpacityValue(0.1),
                            borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                            border: Border.all(
                              color: AppTheme.dtYellow.withOpacityValue(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.subscriptions,
                                color: AppTheme.dtBlue,
                                size: ResponsiveSize.getFontSize(18),
                              ),
                              SizedBox(width: ResponsiveSize.getWidth(8)),
                              Expanded(
                                child: Text(
                                  'La souscription mensuelle a été activée sur votre ligne fixe ${widget.fixedNumber}',
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
                        
                        // Espace pour le safe area
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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
              fontSize: ResponsiveSize.getFontSize(15),
              color: Colors.grey[600],
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(15),
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