import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/providers/balance_provider.dart';
import 'package:dtservices/screens/transfer_credit/transfer_success_screen.dart';
import 'package:dtservices/services/transfer_credit_service.dart';
import 'package:dtservices/services/biometric_auth_service.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';

class TransferConfirmationScreen extends StatefulWidget {
  final String phoneNumber;
  final String recipient;
  final double amount;
  final double transferFee;

  const TransferConfirmationScreen({
    super.key,
    required this.phoneNumber,
    required this.recipient,
    required this.amount,
    required this.transferFee,
  });

  @override
  State<TransferConfirmationScreen> createState() =>
      _TransferConfirmationScreenState();
}

class _TransferConfirmationScreenState
    extends State<TransferConfirmationScreen> {
  bool _isLoading = false;
  final TransferService _transferService = TransferService();

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final balanceProvider = context.watch<BalanceProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: AppLocalizations.of(context)!.transferConfirmationTitle,
        showAction: true,
        value: balanceProvider.solde,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Entête avec icône
            Center(
              child: Container(
                padding: EdgeInsets.all(
                  ResponsiveSize.getWidth(AppTheme.spacingL),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.dtBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: AppTheme.dtBlue,
                  size: ResponsiveSize.getFontSize(60),
                ),
              ),
            ),

            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

            // Titre
            Center(
              child: Text(
                AppLocalizations.of(context)!.transferTitle,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(24),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
            ),

            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),

            Center(
              child: Text(
                AppLocalizations.of(context)!.checkTransferDetails,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  color: Colors.grey[600],
                ),
              ),
            ),

            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),

            // Détails du transfert
            Container(
              padding: EdgeInsets.all(
                ResponsiveSize.getWidth(AppTheme.spacingM),
              ),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.getWidth(AppTheme.radiusM),
                ),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    AppLocalizations.of(context)!.fromLabel,
                    '+253 ${widget.phoneNumber}',
                  ),
                  Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                  _buildDetailRow(
                    AppLocalizations.of(context)!.toLabel,
                    '+253 ${widget.recipient}',
                  ),
                  Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                  _buildDetailRow(
                    AppLocalizations.of(context)!.amountKey,
                    '${widget.amount.toStringAsFixed(0)} DJF',
                  ),
                  Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                  _buildDetailRow(
                    AppLocalizations.of(context)!.feesKey,
                    '${widget.transferFee.toStringAsFixed(0)} DJF',
                  ),
                  Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                  _buildDetailRow(
                    AppLocalizations.of(context)!.totalDebit,
                    '${(widget.amount + widget.transferFee).toStringAsFixed(0)} DJF',
                    isTotal: true,
                  ),
                  Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                  _buildDetailRow(
                    AppLocalizations.of(context)!.dateKey,
                    _getCurrentDate(),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

            // Information sur le solde après transfert
            Container(
              padding: EdgeInsets.all(
                ResponsiveSize.getWidth(AppTheme.spacingM),
              ),
              decoration: BoxDecoration(
                color: AppTheme.dtYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.getWidth(AppTheme.radiusM),
                ),
                border: Border.all(color: AppTheme.dtYellow.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.dtYellow,
                    size: ResponsiveSize.getFontSize(24),
                  ),
                  SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.currentBalance(
                            balanceProvider.solde.toStringAsFixed(0),
                          ),
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(14),
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveSize.getHeight(AppTheme.spacingXS),
                        ),
                        Text(
                          AppLocalizations.of(context)!.balanceAfterTransfer(
                            (balanceProvider.solde -
                                    widget.amount -
                                    widget.transferFee)
                                .toStringAsFixed(0),
                          ),
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(16),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dtBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),

            // Note importante
            Container(
              padding: EdgeInsets.all(
                ResponsiveSize.getWidth(AppTheme.spacingM),
              ),
              decoration: BoxDecoration(
                color: AppTheme.dtBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.getWidth(AppTheme.radiusM),
                ),
                border: Border.all(color: AppTheme.dtBlue.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.dtBlue,
                    size: ResponsiveSize.getFontSize(20),
                  ),
                  SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.transferWarning,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(14),
                        color: AppTheme.dtBlue,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.dtBlue),
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveSize.getHeight(16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveSize.getWidth(AppTheme.radiusM),
                        ),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.cancelAction,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(16),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dtBlue,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),

                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _processTransfer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dtBlue,
                      foregroundColor: AppTheme.dtYellow,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveSize.getHeight(16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveSize.getWidth(AppTheme.radiusM),
                        ),
                      ),
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              width: ResponsiveSize.getWidth(20),
                              height: ResponsiveSize.getHeight(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.dtYellow,
                                ),
                              ),
                            )
                            : Text(
                              AppLocalizations.of(context)!.confirmTransfer,
                              style: TextStyle(
                                fontSize: ResponsiveSize.getFontSize(16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            color: isTotal ? AppTheme.dtBlue : Colors.grey[600],
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            fontWeight: FontWeight.bold,
            color: isTotal ? AppTheme.dtBlue : AppTheme.dtBlue,
          ),
        ),
      ],
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  void _processTransfer() async {
    if (_isLoading) return;

    // Demander l'authentification biométrique avant de procéder
    final authResult = await BiometricAuthService.authenticateForTransfer(
      amount: widget.amount,
      currency: 'DJF',
      recipient: widget.recipient,
    );

    if (!authResult.success) {
      // Authentification échouée
      if (authResult.errorType != BiometricAuthErrorType.userCancel) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authResult.errorMessage ??
                  AppLocalizations.of(context)!.authFailed,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Remplacer la simulation par l'appel API réel
      final result = await _transferService.transferCredit(
        senderMsisdn: widget.phoneNumber,
        receiverMsisdn: widget.recipient,
        amount: widget.amount,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Transfert réussi - Rafraîchir le solde
          final balanceProvider = context.read<BalanceProvider>();
          await balanceProvider.refreshBalance();

          // Vérifier que le widget est toujours monté avant navigation
          if (!mounted) return;

          // Navigation vers l'écran de succès
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => TransferSuccessScreen(
                    phoneNumber: widget.phoneNumber,
                    recipient: widget.recipient,
                    amount: widget.amount,
                    ancienSolde: balanceProvider.solde,
                    transferFee: widget.transferFee,
                  ),
            ),
          );
        } else {
          // Transfert échoué - Afficher l'erreur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${result['error']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.transferError(e.toString()),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
