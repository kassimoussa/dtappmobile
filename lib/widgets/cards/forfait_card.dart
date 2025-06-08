// lib/widgets/cards/forfait_card.dart
import 'package:dtapp3/screens/forfait_confirmation_screen2.dart';
import 'package:dtapp3/services/user_session.dart';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/forfait.dart';
import '../../utils/responsive_size.dart';
import '../../extensions/color_extensions.dart';
import '../../routes/custom_route_transitions.dart';
import '../../screens/forfait_confirmation_screen.dart';

class ForfaitCard extends StatefulWidget {
  final Forfait forfait;
  final double soldeActuel;
  final Function()? onAchatReussi;
  final String? phoneNumber;

  const ForfaitCard({
    super.key,
    required this.forfait,
    required this.soldeActuel,
    this.onAchatReussi,
    this.phoneNumber,
  });

  @override
  State<ForfaitCard> createState() => _ForfaitCardState();
}

class _ForfaitCardState extends State<ForfaitCard> {

  bool _isProcessing = false;
  
  bool _isLoading = false;
  String? userNumber;

  @override
  void initState() {
    super.initState(); 
    _loadPhoneNumber();
  }

  Future<void> _loadPhoneNumber() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final phoneNumber = await UserSession.getPhoneNumber();
      setState(() {
        userNumber = phoneNumber;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement du numéro: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

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

      // Navigation vers l'écran de confirmation
      if (!mounted) return;
      
      if(widget.phoneNumber != userNumber){
        Navigator.push(
          context,
          CustomRouteTransitions.slideRightRoute(
            page: ForfaitConfirmationScreen2(
              forfait: widget.forfait,
              phoneNumber: widget.phoneNumber ?? '77XXXXXX', // Utiliser le numéro fourni ou une valeur par défaut
              soldeActuel: widget.soldeActuel,
              onAchatReussi: widget.onAchatReussi,
            ),
          ),
        );
      } else{
        Navigator.push(
          context,
          CustomRouteTransitions.slideRightRoute(
            page: ForfaitConfirmationScreen(
              forfait: widget.forfait,
              phoneNumber: widget.phoneNumber ?? '77XXXXXX', // Utiliser le numéro fourni ou une valeur par défaut
              soldeActuel: widget.soldeActuel,
              onAchatReussi: widget.onAchatReussi,
            ),
          ),
        );
      }

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

                // Détails du forfait
                widget.forfait.type == 'internet'
                    ? _buildInternetDetails()
                    : _buildComboDetails(),
                    
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

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: ResponsiveSize.getFontSize(16),
          color: Colors.grey[600],
        ),
        SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
        Text(
          text,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(14),
            color: Colors.grey[800],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDetailItem(Icons.wifi, widget.forfait.data!),
          _buildDetailItem(Icons.access_time, widget.forfait.validite),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem(Icons.phone, '${widget.forfait.minutes} min'),
              _buildDetailItem(Icons.message, '${widget.forfait.sms} SMS'),
            ],
          ),
          Divider(
            height: ResponsiveSize.getHeight(AppTheme.spacingM),
            color: Colors.grey[300],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem(Icons.wifi, widget.forfait.data!),
              _buildDetailItem(Icons.access_time, widget.forfait.validite),
            ],
          ),
        ],
      ),
    );
  }
}