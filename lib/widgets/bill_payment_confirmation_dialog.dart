// lib/widgets/bill_payment_confirmation_dialog.dart
import 'package:flutter/material.dart';

class BillPaymentConfirmationDialog extends StatelessWidget {
  final Map<String, dynamic> bill;
  final String paymentMethod;

  const BillPaymentConfirmationDialog({
    super.key,
    required this.bill,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final Color djiboutiBlue = const Color(0xFF002555);
    
    // Générer un numéro de transaction unique
    final String transactionId = 'PAIE-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final String currentDate = '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    final String currentTime = '${DateTime.now().hour}:${DateTime.now().minute}';

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
          maxHeight: size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: isSmallScreen ? 30 : 40,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paiement réussi !',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Votre facture a été payée avec succès',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 15),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Détails du reçu',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: djiboutiBlue,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Payé',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 10 : 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              'Facture:',
                              bill['invoiceNumber'],
                              isSmallScreen,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Type:',
                              bill['type'],
                              isSmallScreen,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Montant:',
                              bill['amount'],
                              isSmallScreen,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Méthode:',
                              paymentMethod == 'D-Money'
                                  ? 'D-Money'
                                  : 'Compte principal mobile',
                              isSmallScreen,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Date de paiement:',
                              '$currentDate à $currentTime',
                              isSmallScreen,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'N° Transaction:',
                              transactionId,
                              isSmallScreen,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 15),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: djiboutiBlue,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Votre facture a été payée avec succès. Vous pouvez consulter l\'historique de vos paiements dans la section "Historique".',
                                style: TextStyle(
                                  color: djiboutiBlue,
                                  fontSize: isSmallScreen ? 12 : 14,
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
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(
                      Icons.share_outlined,
                      size: isSmallScreen ? 16 : 18,
                    ),
                    label: Text(
                      'Partager',
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                    ),
                    onPressed: () {
                      // Logique pour partager le reçu
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: djiboutiBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: djiboutiBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Terminer',
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

  Widget _buildInfoRow(String label, String value, bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.grey[700],
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12 : 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}