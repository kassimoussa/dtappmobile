// lib/widgets/cards/forfait_card.dart 
import 'package:dtapp3/constants/app_theme.dart';
import 'package:dtapp3/enums/purchase_enums.dart';
import 'package:dtapp3/extensions/color_extensions.dart';
import 'package:dtapp3/models/forfait.dart';
import 'package:dtapp3/routes/custom_route_transitions.dart';
import 'package:dtapp3/screens/achat_forfait/forfait_confirmation_screen.dart';
import 'package:dtapp3/utils/responsive_size.dart';
import 'package:flutter/material.dart'; 

class ForfaitCard extends StatefulWidget {
  final Forfait forfait;
  final double soldeActuel;
  final Function()? onAchatReussi;
  final String? phoneNumber;
  final PurchaseMode purchaseMode;

  const ForfaitCard({
    super.key,
    required this.forfait,
    required this.soldeActuel,
    this.onAchatReussi,
    this.phoneNumber,
    this.purchaseMode = PurchaseMode.personal,
  });

  @override
  State<ForfaitCard> createState() => _ForfaitCardState();
}

class _ForfaitCardState extends State<ForfaitCard> {
  bool _isProcessing = false;

  Future<void> _handleAchat(BuildContext context) async {
    if (_isProcessing) return; // Éviter les clics multiples

    try {
      setState(() {
        _isProcessing = true;
      });

      // Vérification du solde
      if (widget.forfait.prix > widget.soldeActuel) {
        _showMessage(
          context,
          'Solde insuffisant pour cet achat.',
          isError: true,
        );
        return;
      }

      // Navigation vers l'écran de confirmation unifié
      if (!mounted) return;
      
      Navigator.push(
        context,
        CustomRouteTransitions.slideRightRoute(
          page: ForfaitConfirmationScreen(
            forfait: widget.forfait,
            phoneNumber: widget.phoneNumber ?? '77XXXXXX',
            soldeActuel: widget.soldeActuel,
            onAchatReussi: widget.onAchatReussi,
            purchaseType: widget.purchaseMode == PurchaseMode.gift 
                ? PurchaseType.gift 
                : PurchaseType.personal,
          ),
        ),
      );

    } catch (e) {
      _showMessage(
        context,
        'Une erreur est survenue. Veuillez réessayer.',
        isError: true,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(14),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        side: widget.forfait.isPopulaire
            ? BorderSide(color: AppTheme.dtYellow, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // Section principale
          Padding(
            padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.forfait.nom,
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(18),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dtBlue,
                        ),
                      ),
                    ),
                    if (widget.forfait.isPopulaire)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveSize.getWidth(AppTheme.spacingS),
                          vertical: ResponsiveSize.getHeight(AppTheme.spacingXS),
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.dtYellow.withOpacityValue(0.2),
                          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: ResponsiveSize.getFontSize(16),
                              color: AppTheme.dtYellow,
                            ),
                            SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
                            Text(
                              'Populaire',
                              style: TextStyle(
                                color: AppTheme.dtBlue,
                                fontSize: ResponsiveSize.getFontSize(12),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),

                // Détails du forfait selon le type
                _buildForfaitDetails(),
                    
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                
                // Prix et bouton d'achat
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.forfait.prix} FDJ',
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(20),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dtBlue,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: widget.forfait.prix > widget.soldeActuel 
                          ? null 
                          : () => _handleAchat(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dtBlue,
                        foregroundColor: AppTheme.dtYellow,
                        disabledBackgroundColor: Colors.grey[400],
                        disabledForegroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveSize.getWidth(AppTheme.spacingL),
                          vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                        ),
                      ),
                      child: _isProcessing
                          ? SizedBox(
                              width: ResponsiveSize.getWidth(20),
                              height: ResponsiveSize.getHeight(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtYellow),
                              ),
                            )
                          : widget.forfait.prix > widget.soldeActuel
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: ResponsiveSize.getFontSize(16),
                                    ),
                                    SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
                                    Text(
                                      'Solde insuffisant',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: ResponsiveSize.getFontSize(14),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Acheter',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveSize.getFontSize(16),
                                  ),
                                ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForfaitDetails() {
    switch (widget.forfait.type) {
      case 'internet':
        return _buildInternetDetails();
      case 'combo':
        return _buildComboDetails();
      case 'tempo':
        return _buildTempoDetails();
      default:
        return _buildInternetDetails();
    }
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: ResponsiveSize.getFontSize(16),
          color: Colors.grey[600],
        ),
        SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInternetDetails() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildDetailItem(Icons.wifi, widget.forfait.data ?? 'Aucune data')),
          SizedBox(width: ResponsiveSize.getWidth(8)),
          Expanded(child: _buildDetailItem(Icons.access_time, widget.forfait.validite)),
        ],
      ),
    );
  }

  Widget _buildComboDetails() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDetailItem(Icons.phone, '${widget.forfait.minutes} min')),
              SizedBox(width: ResponsiveSize.getWidth(8)),
              Expanded(child: _buildDetailItem(Icons.message, '${widget.forfait.sms} SMS')),
            ],
          ),
          Divider(
            height: ResponsiveSize.getHeight(AppTheme.spacingM),
            color: Colors.grey[300],
          ),
          Row(
            children: [
              Expanded(child: _buildDetailItem(Icons.wifi, widget.forfait.data ?? 'Aucune data')),
              SizedBox(width: ResponsiveSize.getWidth(8)),
              Expanded(child: _buildDetailItem(Icons.access_time, widget.forfait.validite)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempoDetails() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildDetailItem(Icons.phone, '${widget.forfait.minutes} min')),
              SizedBox(width: ResponsiveSize.getWidth(8)),
              Expanded(child: _buildDetailItem(Icons.weekend, 'Week-end')),
            ],
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
          _buildDetailItem(Icons.schedule, widget.forfait.validite),
        ],
      ),
    );
  }
}