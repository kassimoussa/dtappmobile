import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/extensions/color_extensions.dart';
import 'package:dtservices/providers/balance_provider.dart';
import 'package:dtservices/screens/transfer_credit/transfer_success_screen.dart';
import 'package:dtservices/services/transfer_credit_service.dart';
import 'package:dtservices/services/biometric_auth_service.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pin_verification_bottom_sheet.dart';

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
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.dtBlueO08,
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildGlassAppBar(context, AppLocalizations.of(context)!.transferConfirmationTitle),
                Expanded(
                  child: SingleChildScrollView(
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
                  color: AppTheme.dtBlueO10,
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
                  Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                  _buildDetailRow(
                    'Solde actuel',
                    '${balanceProvider.solde.toStringAsFixed(0)} DJF',
                  ),
                  Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                  _buildDetailRow(
                    'Solde après transfert',
                    '${(balanceProvider.solde - widget.amount - widget.transferFee).toStringAsFixed(0)} DJF',
                    isTotal: true,
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
                    onPressed: _isLoading ? null : () => Navigator.popUntil(context, (route) => route.isFirst),
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
                              'Confirmer',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar(BuildContext context, String title) {
    return Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(12),
            vertical: ResponsiveSize.getHeight(12),
          ),
          decoration: const BoxDecoration(
            color: AppTheme.white95,
            border: Border(bottom: BorderSide(color: AppTheme.dtBlueO10, width: 0.5)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.white50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.dtBlueDark, size: 20),
                ),
              ),
              SizedBox(width: ResponsiveSize.getWidth(16)),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: ResponsiveSize.getFontSize(22),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
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
      if (!mounted) return;
      // Authentification biométrique échouée ou annulée
      final authProvider = context.read<AuthProvider>();

      // Si on n'a pas de PIN configuré, on bloque le transfert si l'erreur n'est pas "userCancel"
      if (!authProvider.hasPin) {
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

      // Fallback: Demander le code PIN
      final phoneNumber = authProvider.phoneNumber;
      if (phoneNumber == null) return;

      final pinVerified = await PinVerificationBottomSheet.show(
        context,
        phoneNumber: phoneNumber,
        title: AppLocalizations.of(context)!.enterPinForTransfer,
      );

      // Si le code PIN n'a pas été validé (BottomSheet fermé ou erreur), on annule le transfert
      if (!pinVerified) {
        return;
      }
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
