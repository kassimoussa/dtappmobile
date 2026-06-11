// lib/widgets/recharge_dialog.dart
import 'package:flutter/material.dart';
import 'package:dtservices/widgets/recharge_confirmation_dialog.dart';
import '../generated/l10n/app_localizations.dart';

class RechargeDialog extends StatefulWidget {
  const RechargeDialog({super.key});

  @override
  State<RechargeDialog> createState() => _RechargeDialogState();
}

class _RechargeDialogState extends State<RechargeDialog> {
  final TextEditingController _rechargeAmountController = TextEditingController();
  String _selectedPaymentMethod = 'D-Money';
  final Color djiboutiBlue = const Color(0xFF002555);
  final Color djiboutiYellow = const Color(0xFFF7C700);

  @override
  void dispose() {
    _rechargeAmountController.dispose();
    super.dispose();
  }

  void _showRechargeConfirmation() {
    final amount = _rechargeAmountController.text.trim();
    showDialog(
      context: context,
      builder: (context) => RechargeConfirmationDialog(
        amount: amount,
        paymentMethod: _selectedPaymentMethod,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 20.0,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Text(
                l10n.rechargeYourAccount,
                style: TextStyle(
                  color: djiboutiBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.amountToRecharge,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _rechargeAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: djiboutiBlue, width: 2),
                        ),
                        hintText: 'Ex: 1000',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.attach_money, color: djiboutiBlue),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.paymentMethod,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentOption(
                      title: 'D-Money',
                      subtitle: l10n.dmoneyPaymentDesc,
                      value: 'D-Money',
                      icon: Icons.account_balance_wallet,
                      iconColor: djiboutiBlue,
                      backgroundColor: Colors.blue[50],
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentOption(
                      title: l10n.mobileMainAccount,
                      subtitle: l10n.mobileTransferDesc,
                      value: 'Mobile',
                      icon: Icons.smartphone,
                      iconColor: Colors.green[700],
                      backgroundColor: Colors.green[50],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      backgroundColor: Colors.grey[200],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(l10n.cancel, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: djiboutiYellow,
                      foregroundColor: djiboutiBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_rechargeAmountController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.pleaseEnterRechargeAmount),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      _showRechargeConfirmation();
                    },
                    child: Text(
                      l10n.confirm,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? djiboutiYellow : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? backgroundColor : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              isSelected
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: djiboutiYellow),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    )
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[400]!),
                        color: Colors.white,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
