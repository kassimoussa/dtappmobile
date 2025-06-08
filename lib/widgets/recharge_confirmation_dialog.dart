// lib/widgets/recharge_confirmation_dialog.dart
import 'package:flutter/material.dart';

class RechargeConfirmationDialog extends StatelessWidget {
  final String amount;
  final String paymentMethod;

  const RechargeConfirmationDialog({
    super.key,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final Color djiboutiBlue = const Color(0xFF002555);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      backgroundColor: Colors.grey[50],
      child: Container(
        padding: const EdgeInsets.all(24.0),
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Demande envoyée',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: djiboutiBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              paymentMethod == 'D-Money'
                  ? 'Votre demande de rechargement de $amount DJF via D-Money a été envoyée. Veuillez suivre les instructions sur votre téléphone pour finaliser la transaction.'
                  : 'Votre demande de transfert de $amount DJF depuis votre compte principal mobile a été traitée avec succès. Le montant a été ajouté à votre solde fixe.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: djiboutiBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}