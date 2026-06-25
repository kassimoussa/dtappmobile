// lib/widgets/bill_payment_dialog.dart
import 'package:dtservices/widgets/bill_payment_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../generated/l10n/app_localizations.dart';

class BillPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> bill;

  const BillPaymentDialog({
    super.key,
    required this.bill,
  });

  @override
  State<BillPaymentDialog> createState() => _BillPaymentDialogState();
}

class _BillPaymentDialogState extends State<BillPaymentDialog> {
  String _selectedPaymentMethod = 'D-Money';

  void _showBillPaymentLoading() {
    final l10n = AppLocalizations.of(context)!;
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
            builder: (context) => BillPaymentConfirmationDialog(
              bill: widget.bill,
              paymentMethod: _selectedPaymentMethod,
            ),
          );
        });

        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              CircularProgressIndicator(color: AppTheme.dtYellow, strokeWidth: 6),
              const SizedBox(height: 24),
              Text(
                l10n.processingPayment,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pleaseWaitPayment,
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: size.width > 600 ? 500 : null,
        constraints: BoxConstraints(
          maxHeight: size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.payBill,
                style: TextStyle(
                  color: AppTheme.dtBlue,
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
                              '${l10n.invoiceLabel} ${widget.bill['invoiceNumber']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: isSmallScreen ? 13 : 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.bill['amount']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 20 : 24,
                                color: AppTheme.dtBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.dueDateLabel} ${widget.bill['dueDate']}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.typeLabel} ${widget.bill['type']}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      Text(
                        l10n.choosePaymentMethod,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.dtBlue,
                          fontSize: isSmallScreen ? 14 : 15,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildPaymentOption(
                        title: 'D-Money',
                        subtitle: l10n.dmoneyPaymentDesc,
                        value: 'D-Money',
                        icon: Icons.account_balance_wallet,
                        iconColor: AppTheme.dtBlue,
                        backgroundColor: Colors.blue[50],
                        isSmallScreen: isSmallScreen,
                      ),

                      const SizedBox(height: 8),

                      _buildPaymentOption(
                        title: l10n.mobileMainAccount,
                        subtitle: l10n.mobileLinePayment,
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
                      l10n.cancel,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dtYellow,
                      foregroundColor: AppTheme.dtBlue,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showBillPaymentLoading();
                    },
                    child: Text(
                      l10n.payNow,
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
          color: isSelected ? AppTheme.dtYellow : Colors.transparent,
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
                activeColor: AppTheme.dtYellow,
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
