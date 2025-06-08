// lib/widgets/package_payment_dialog.dart
import 'package:dtapp3/widgets/package_confirmation_dialog.dart';
import 'package:flutter/material.dart';

class PackagePaymentDialog extends StatefulWidget {
  final Map<String, dynamic> packageDetails;

  const PackagePaymentDialog({
    super.key,
    required this.packageDetails,
  });

  @override
  State<PackagePaymentDialog> createState() => _PackagePaymentDialogState();
}

class _PackagePaymentDialogState extends State<PackagePaymentDialog> {
  String _selectedPaymentMethod = 'D-Money';
  final Color djiboutiBlue = const Color(0xFF002555);
  final Color djiboutiYellow = const Color(0xFFF7C700);

  void _showPurchaseProcessing(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Pour simuler un traitement
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);

          // Afficher la confirmation finale
          showDialog(
            context: context,
            builder: (context) => PackageConfirmationDialog(
              packageDetails: widget.packageDetails,
              paymentMethod: _selectedPaymentMethod,
            ),
          );
        });

        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              CircularProgressIndicator(color: djiboutiYellow, strokeWidth: 6),
              const SizedBox(height: 24),
              Text(
                'Traitement en cours...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: djiboutiBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Veuillez patienter pendant que nous traitons votre demande.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir la taille de l'écran pour la responsivité
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: size.width > 600 ? 500 : null,
        constraints: BoxConstraints(
          maxHeight: size.height * 0.7, // Limite la hauteur à 70% de l'écran
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Méthode de paiement',
                style: TextStyle(
                  color: djiboutiBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 18 : 20,
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.packageDetails['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 14 : 16,
                                color: djiboutiBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Prix: ${widget.packageDetails['price']} DJF - Validité: ${widget.packageDetails['validity']}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.packageDetails['description'],
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      Text(
                        'Choisissez comment payer:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: djiboutiBlue,
                          fontSize: isSmallScreen ? 13 : 15,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Option D-Money
                      _buildPaymentOption(
                        title: 'D-Money',
                        subtitle: 'Paiement via votre compte D-Money',
                        value: 'D-Money',
                        icon: Icons.account_balance_wallet,
                        iconColor: djiboutiBlue,
                        backgroundColor: Colors.blue[50],
                        isSmallScreen: isSmallScreen,
                      ),

                      const SizedBox(height: 8),

                      // Option Mobile Account
                      _buildPaymentOption(
                        title: 'Compte principal mobile',
                        subtitle: 'Transfert depuis votre compte mobile',
                        value: 'Mobile',
                        icon: Icons.smartphone,
                        iconColor: Colors.green[700],
                        backgroundColor: Colors.green[50],
                        isSmallScreen: isSmallScreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Retour',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: djiboutiYellow,
                      foregroundColor: djiboutiBlue,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                    ),
                    onPressed: () {
                      // Finaliser l'achat
                      Navigator.pop(context);
                      _showPurchaseProcessing(context);
                    },
                    child: Text(
                      'Payer maintenant',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
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

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color? iconColor,
    required Color? backgroundColor,
    required bool isSmallScreen,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return Card(
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? djiboutiYellow : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: isSmallScreen ? 8 : 12,
          ),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: _selectedPaymentMethod,
                activeColor: djiboutiYellow,
                onChanged: (newValue) {
                  setState(() {
                    _selectedPaymentMethod = newValue!;
                  });
                },
              ),
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 13 : 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}