// lib/widgets/bills_section.dart
import 'package:dtservices/widgets/bill_payment_dialog.dart';
import 'package:flutter/material.dart'; 

class BillsSection extends StatelessWidget {
  const BillsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final Color djiboutiBlue = const Color(0xFF002555);
    final Color djiboutiYellow = const Color(0xFFF7C700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Factures - Ligne fixe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: djiboutiBlue,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Afficher toutes les factures dans une nouvelle page
                },
                icon: Icon(
                  Icons.arrow_forward,
                  color: djiboutiYellow,
                  size: 16,
                ),
                label: Text(
                  'Voir tout',
                  style: TextStyle(color: djiboutiYellow),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildBillsList(context, djiboutiBlue, djiboutiYellow),
      ],
    );
  }

  Widget _buildBillsList(BuildContext context, Color djiboutiBlue, Color djiboutiYellow) {
    // Données d'exemple pour l'historique des factures (limitées à 2 pour l'affichage compact)
    final billsHistory = [
      {
        'type': 'Facture Internet',
        'amount': '3,500 DJF',
        'date': '20 Avr 2025',
        'dueDate': '30 Avr 2025',
        'status': 'Non payée',
        'isPaid': false,
        'invoiceNumber': 'FACT-82539-2025',
      },
      {
        'type': 'Facture Téléphone',
        'amount': '1,200 DJF',
        'date': '15 Avr 2025',
        'dueDate': '25 Avr 2025',
        'status': 'Payée',
        'isPaid': true,
        'invoiceNumber': 'FACT-79845-2025',
      },
    ];

    return billsHistory.isEmpty
        ? _buildEmptyState('Aucune facture disponible')
        : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: billsHistory.length,
          itemBuilder: (context, index) {
            final bill = billsHistory[index];
            final isPaid = bill['isPaid'] as bool;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bill['type'].toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: djiboutiBlue,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPaid ? Colors.green[100] : Colors.amber[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bill['status'].toString(),
                            style: TextStyle(
                              color: isPaid ? Colors.green[800] : Colors.amber[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Ajout du numéro de facture
                    Text(
                      'N° ${bill['invoiceNumber']}',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date d\'émission',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bill['date'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date d\'échéance',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bill['dueDate'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Montant', style: TextStyle(fontSize: 14)),
                        Text(
                          bill['amount'].toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: djiboutiBlue,
                          ),
                        ),
                      ],
                    ),
                    if (!isPaid) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: djiboutiYellow,
                            foregroundColor: djiboutiBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // Action pour payer la facture
                            showDialog(
                              context: context,
                              builder: (context) => BillPaymentDialog(bill: bill),
                            );
                          },
                          child: const Text(
                            'Payer maintenant',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}