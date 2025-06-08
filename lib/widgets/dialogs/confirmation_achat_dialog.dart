import 'package:flutter/material.dart';

import '../../models/forfait.dart';

class ConfirmationAchatDialog extends StatelessWidget {
  final Forfait forfait;
  final double soldeActuel;

  const ConfirmationAchatDialog({
    super.key,
    required this.forfait,
    required this.soldeActuel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Confirmation d\'achat',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF002464),
        ),
      ),
      content: _buildDialogContent(),
      actions: _buildDialogActions(context),
    );
  }

  Widget _buildDialogContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Voulez-vous acheter le ${forfait.nom} ?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        _buildDetailsCard(),
        const SizedBox(height: 16),
        Text(
          'Solde après achat: ${soldeActuel - forfait.prix} FDJ',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Prix:', '${forfait.prix} FDJ'),
          if (forfait.data != null) _buildDetailRow('Data:', forfait.data!),
          if (forfait.minutes != null)
            _buildDetailRow('Minutes:', '${forfait.minutes} min'),
          if (forfait.sms != null) _buildDetailRow('SMS:', forfait.sms!),
          _buildDetailRow('Validité:', forfait.validite),
        ],
      ),
    );
  }

  List<Widget> _buildDialogActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text(
          'Annuler',
          style: TextStyle(color: Colors.grey),
        ),
      ),
      ElevatedButton(
        onPressed: () => Navigator.of(context).pop(true),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF002464),
          foregroundColor: const Color(0xFFF8C02C),
        ),
        child: const Text('Confirmer'),
      ),
    ];
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}