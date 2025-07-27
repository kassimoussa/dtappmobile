// lib/screens/forfait_confirmation_screen.dart
import 'package:dtapp3/constants/app_theme.dart';
import 'package:dtapp3/extensions/color_extensions.dart';
import 'package:dtapp3/models/forfait.dart';
import 'package:dtapp3/routes/custom_route_transitions.dart';
import 'package:dtapp3/screens/achat_forfait/forfait_success_screen.dart';
import 'package:dtapp3/services/purchase_offer_service.dart'; 
import 'package:dtapp3/utils/responsive_size.dart';
import 'package:dtapp3/widgets/appbar_widget.dart'; 
import 'package:flutter/material.dart';

class ForfaitConfirmationScreen2 extends StatefulWidget {
  final Forfait forfait;
  final String phoneNumber;
  final double soldeActuel;
  final VoidCallback? onAchatReussi;

  const ForfaitConfirmationScreen2({
    super.key,
    required this.forfait,
    required this.phoneNumber,
    required this.soldeActuel,
    this.onAchatReussi,
  });

  @override
  State<ForfaitConfirmationScreen2> createState() => _ForfaitConfirmationScreen2State();
}

class _ForfaitConfirmationScreen2State extends State<ForfaitConfirmationScreen2> {
  bool _isLoading = false;

  Future<void> _confirmerAchat() async {
  if (_isLoading) return;
  
  setState(() {
    _isLoading = true;
  });
  
  try {
    // Appel à l'API d'achat d'offre
    final result = await PurchaseOfferService.purchaseOfferGift(widget.phoneNumber, widget.forfait.id);
    
    if (mounted) {
      // L'API retourne 'succes' : true en cas de succès
      if (result['succes'] == true) {
        // Appeler le callback de rafraîchissement du solde si fourni
        widget.onAchatReussi?.call();
        
        // Navigation vers l'écran de succès
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
        // Afficher l'erreur retournée par l'API
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['erreur'] ?? 'Erreur lors de l\'achat'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      // Afficher l'erreur de connexion ou autre
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(title: "Confirmation d'achat", showAction: true, value: widget.soldeActuel),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Entête
            Center(
              child: Container(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
                decoration: BoxDecoration(
                  color: AppTheme.dtBlue.withOpacityValue(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.forfait.type == 'internet' ? Icons.wifi : Icons.phone_android,
                  color: AppTheme.dtBlue,
                  size: ResponsiveSize.getFontSize(60),
                ),
              ),
            ),
            
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
            
            // Titre et sous-titre
            Center(
              child: Text(
                widget.forfait.nom,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(24),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
            ),
            
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
            
            Center(
              child: Text(
                'Valide pendant ${widget.forfait.validite}',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  color: Colors.grey[600],
                ),
              ),
            ),
            
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),
            
            // Détails du forfait
            Container(
              padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildConfirmationDetailRow('Numéro', widget.phoneNumber),
                  Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                  _buildConfirmationDetailRow('Prix', '${widget.forfait.prix} FDJ'),
                  Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                  _buildConfirmationDetailRow('Internet', widget.forfait.data!),
                  
                  if (widget.forfait.type == 'combo' && widget.forfait.minutes != null) ...[
                    Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                    _buildConfirmationDetailRow('Appels', '${widget.forfait.minutes} min'),
                  ],
                  
                  if (widget.forfait.type == 'combo' && widget.forfait.sms != null) ...[
                    Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                    _buildConfirmationDetailRow('SMS', '${widget.forfait.sms} SMS'),
                  ],
                  
                  Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                  _buildConfirmationDetailRow('Validité', widget.forfait.validite),
                ],
              ),
            ),
            
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
            
            // Information sur le solde après achat
            Container(
              padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
              decoration: BoxDecoration(
                color: AppTheme.dtYellow.withOpacityValue(0.1),
                borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                border: Border.all(color: AppTheme.dtYellow.withOpacityValue(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.dtYellow,
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
                          'Solde après achat: ${(widget.soldeActuel - widget.forfait.prix).toStringAsFixed(0)} FDJ',
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(16),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dtBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.dtBlue),
                      padding: EdgeInsets.symmetric(vertical: ResponsiveSize.getHeight(16)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
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
                      padding: EdgeInsets.symmetric(vertical: ResponsiveSize.getHeight(16)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                      ),
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
                        : Text(
                            'Confirmer l\'achat',
                            style: TextStyle(
                              fontSize: ResponsiveSize.getFontSize(16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConfirmationDetailRow(String label, String value) {
    return Row(
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
    );
  }
}