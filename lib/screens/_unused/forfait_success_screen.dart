// lib/screens/forfait_success_screen.dart
import 'package:dtapp3/models/forfait.dart';
import 'package:dtapp3/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dtapp3/constants/app_theme.dart';
import 'package:dtapp3/extensions/color_extensions.dart';
import 'package:dtapp3/routes/custom_route_transitions.dart'; 
import 'package:dtapp3/utils/responsive_size.dart'; 

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

class _ForfaitSuccessScreenState extends State<ForfaitSuccessScreen> {
  late Timer _redirectTimer;
  int _remainingSeconds = 3; // Compte à rebours de 3 secondes

  @override
  void initState() {
    super.initState();
    
    // Démarrer le compte à rebours pour la redirection
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _redirectTimer.cancel();
          _redirectToHome();
        }
      });
    });
  }

  @override
  void dispose() {
    _redirectTimer.cancel();
    super.dispose();
  }

  void _redirectToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      CustomRouteTransitions.fadeRoute(
        page: HomeScreen(/* phoneNumber: widget.phoneNumber */),
      ),
      (route) => false, // Supprime toutes les routes précédentes
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    final nouveauSolde = widget.ancienSolde - widget.forfait.prix;
    
    return WillPopScope(
      // Empêcher le retour en arrière avec le bouton système
      onWillPop: () async => false,
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
          automaticallyImplyLeading: false, // Pas de bouton retour
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône de succès
                Container(
                  padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacityValue(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: ResponsiveSize.getFontSize(80),
                  ),
                ),
                
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                
                // Titre
                Text(
                  'Achat réussi !',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(28),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dtBlue,
                  ),
                ),
                
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                
                // Message de confirmation
                Text(
                  'Votre forfait ${widget.forfait.nom} a été activé avec succès',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    color: Colors.grey[700],
                  ),
                ),
                
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),
                
                // Détails du forfait
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Forfait', widget.forfait.nom),
                      Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                      _buildDetailRow('Prix', '${widget.forfait.prix} FDJ'),
                      Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                      _buildDetailRow('Nouveau solde', '${nouveauSolde.toStringAsFixed(0)} FDJ'),
                      
                      if (widget.forfait.data != null) ...[
                        Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                        _buildDetailRow('Internet', widget.forfait.data!),
                      ],
                      
                      if (widget.forfait.minutes != null) ...[
                        Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                        _buildDetailRow('Minutes', '${widget.forfait.minutes} min'),
                      ],
                      
                      if (widget.forfait.sms != null) ...[
                        Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                        _buildDetailRow('SMS', widget.forfait.sms!),
                      ],
                      
                      Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                      _buildDetailRow('Validité', widget.forfait.validite),
                    ],
                  ),
                ),
                
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),
                
                // Bouton pour retourner immédiatement à l'accueil
                ElevatedButton(
                  onPressed: _redirectToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dtBlue,
                    foregroundColor: AppTheme.dtYellow,
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveSize.getWidth(AppTheme.spacingXL),
                      vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                    ),
                  ),
                  child: Text(
                    'Retour à l\'accueil ($_remainingSeconds)',
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                
                // Message informant qu'un SMS sera envoyé
                Container(
                  padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
                  decoration: BoxDecoration(
                    color: AppTheme.dtYellow.withOpacityValue(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.message,
                        color: AppTheme.dtYellow,
                        size: ResponsiveSize.getFontSize(20),
                      ),
                      SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
                      Expanded(
                        child: Text(
                          'Un SMS de confirmation a été envoyé à votre numéro',
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(13),
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
            fontSize: ResponsiveSize.getFontSize(15),
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(15),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),
      ],
    );
  }
}