// lib/screens/test_forfait_success_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../extensions/color_extensions.dart';

class TestForfaitSuccessScreen extends StatefulWidget {
  const TestForfaitSuccessScreen({super.key});

  @override
  State<TestForfaitSuccessScreen> createState() => _TestForfaitSuccessScreenState();
}

class _TestForfaitSuccessScreenState extends State<TestForfaitSuccessScreen>
    with SingleTickerProviderStateMixin {
  late Timer _redirectTimer;
  int _remainingSeconds = 5;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Données statiques pour test
  final String forfaitNom = 'Forfait Sensation';
  final String phoneNumber = '77123456';
  final int prix = 500;
  final double ancienSolde = 2200.0;
  final String minutes = '60';
  final String validite = 'Utilisable du vendredi 07h00 au dimanche 07h00';

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

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    final nouveauSolde = ancienSolde - prix;
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.dtBlue,
          title: Text(
            'Achat réussi',
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
                        // Titre
                        Text(
                          'Achat réussi !',
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
                          'Votre forfait $forfaitNom a été activé avec succès',
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
                  
                  // Détails du forfait avec fade
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
                          _buildDetailRow('Forfait', forfaitNom),
                          _buildDivider(),
                          _buildDetailRow('Destinataire', phoneNumber),
                          _buildDivider(),
                          _buildDetailRow('Prix', '$prix FDJ'),
                          _buildDivider(),
                          _buildDetailRow('Nouveau solde', '${nouveauSolde.toStringAsFixed(0)} FDJ'),
                          _buildDivider(),
                          _buildDetailRow('Minutes', '$minutes min'),
                          _buildDivider(),
                          _buildDetailRow('Validité', validite),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: ResponsiveSize.getHeight(32)),
                  
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
                        
                        // Message SMS avec fade
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
                                Icons.message_outlined,
                                color: AppTheme.dtBlue,
                                size: ResponsiveSize.getFontSize(18),
                              ),
                              SizedBox(width: ResponsiveSize.getWidth(8)),
                              Expanded(
                                child: Text(
                                  'Un SMS de confirmation a été envoyé à votre numéro',
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
      height: ResponsiveSize.getHeight(AppTheme.spacingL),
      color: Colors.grey[300],
    );
  }
}