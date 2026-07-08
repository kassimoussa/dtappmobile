import 'package:flutter/material.dart';
import 'package:dtservices/constants/app_theme.dart';

import '../../models/forfait.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../utils/validity_translator.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        l10n.purchaseConfirmationTitle,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.dtBlue,
        ),
      ),
      content: _buildDialogContent(l10n),
      actions: _buildDialogActions(context, l10n),
    );
  }

  Widget _buildDialogContent(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.purchaseConfirmQuestion(forfait.nom),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        _buildDetailsCard(l10n),
        const SizedBox(height: 16),
        Text(
          l10n.balanceAfterPurchaseAmount('${soldeActuel - forfait.prix}'),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(AppLocalizations l10n) {
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
          _buildDetailRow(l10n.priceRow, '${forfait.prix} FDJ'),
          if (forfait.data != null) _buildDetailRow(l10n.dataRow, forfait.data!),
          if (forfait.minutes != null)
            _buildDetailRow(l10n.minutesRow, '${forfait.minutes} min'),
          if (forfait.sms != null) _buildDetailRow('SMS:', forfait.sms!),
          _buildDetailRow(l10n.validityRow, translateValidity(forfait.validite, l10n)),
        ],
      ),
    );
  }

  List<Widget> _buildDialogActions(BuildContext context, AppLocalizations l10n) {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text(
          l10n.cancel,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
      ElevatedButton(
        onPressed: () => Navigator.of(context).pop(true),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.dtBlue,
          foregroundColor: Colors.white,
        ),
        child: Text(l10n.confirm),
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
