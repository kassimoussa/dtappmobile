import 'dart:ui';
import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/extensions/color_extensions.dart';
import 'package:dtservices/providers/balance_provider.dart';
import 'package:dtservices/screens/transfer_credit/transfer_confirmation_screen.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/utils/phone_number_validator.dart';
import 'package:dtservices/widgets/phone_number_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';

class TransferInputScreen extends StatefulWidget {
  final String phoneNumber;

  const TransferInputScreen({super.key, required this.phoneNumber});

  @override
  State<TransferInputScreen> createState() => _TransferInputScreenState();
}

class _TransferInputScreenState extends State<TransferInputScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _recipientError;
  String? _amountError;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

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
                    AppTheme.dtBlueDark.withOpacityValue(0.08),
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
                _buildGlassAppBar(context, AppLocalizations.of(context)!.transferTitle),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingM),
                    child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Sélecteur de numéro destinataire
              PhoneNumberSelector(
                controller: _recipientController,
                labelText: AppLocalizations.of(context)!.recipientLabel,
                onChanged: (value) {
                  _validateRecipient(value);
                },
              ),

              // Erreur destinataire
              if (_recipientError != null) ...[
                const SizedBox(height: 8),
                _buildErrorMessage(_recipientError!),
              ],

              const SizedBox(height: 24),

              // Champ montant
              _buildAmountField(),

              // Erreur montant
              if (_amountError != null) ...[
                const SizedBox(height: 8),
                _buildErrorMessage(_amountError!),
              ],

              const SizedBox(height: 24),

              // Information importante
              //_buildInfoBox(),
              const SizedBox(height: 32),

              // Bouton de confirmation
              _buildConfirmButton(),

              const SizedBox(height: 24),
            ],
          ),
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(12),
            vertical: ResponsiveSize.getHeight(12),
          ),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
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
        ),
      ),
    );
  }

  // Widget pour le champ montant
  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.amountLabel,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.amountHint,
              suffixText: 'DJF',
              prefixIcon: Icon(Icons.attach_money, color: AppTheme.dtBlue),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              // Validation en temps réel
              _validateAmount(value);
            },
          ),
        ),
      ],
    );
  }

  // Widget pour les messages d'erreur
  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[600], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour la boîte d'information
  Widget _buildInfoBox() {
    final balanceProvider = context.read<BalanceProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dtBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dtBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.dtBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.transferImportantInfo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${AppLocalizations.of(context)!.transferMinAmountParams}\n'
            '${AppLocalizations.of(context)!.transferFeesParams}\n'
            '${AppLocalizations.of(context)!.transferCurrentBalance(balanceProvider.solde.toStringAsFixed(0))}',
            style: TextStyle(color: AppTheme.dtBlue, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Widget pour le bouton de confirmation
  Widget _buildConfirmButton() {
    bool isFormValid =
        _recipientError == null &&
        _amountError == null &&
        _recipientController.text.isNotEmpty &&
        _amountController.text.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isFormValid ? _validateAndSendTransfer : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFormValid ? AppTheme.dtBlue : Colors.grey[400],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          AppLocalizations.of(context)!.confirmTransfer,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Validation du destinataire en temps réel
  void _validateRecipient(String value) {
    final cleanNumber = PhoneNumberValidator.cleanPhoneNumber(value);

    // Tant que l'utilisateur n'a pas fini de saisir les 8 chiffres,
    // on efface l'erreur sans valider pour ne pas le frustrer
    if (cleanNumber.length < 8) {
      if (_recipientError != null) {
        setState(() => _recipientError = null);
      }
      return;
    }

    // Numéro complet → valider le format
    final phoneValidation = PhoneNumberValidator.validatePhoneNumber(cleanNumber);
    if (phoneValidation != null) {
      setState(() => _recipientError = phoneValidation);
      return;
    }

    // Vérifier que ce n'est pas le même numéro
    if (cleanNumber == widget.phoneNumber) {
      setState(() => _recipientError = AppLocalizations.of(context)!.selfTransferError);
      return;
    }

    setState(() => _recipientError = null);
  }

  // Validation du montant en temps réel
  void _validateAmount(String value) {
    final balanceProvider = context.read<BalanceProvider>();

    setState(() {
      if (value.isEmpty) {
        _amountError = null;
        return;
      }

      final amount = double.tryParse(value);
      if (amount == null) {
        _amountError = AppLocalizations.of(context)!.amountInvalid;
        return;
      }

      if (amount <= 0) {
        _amountError = AppLocalizations.of(context)!.amountPositive;
        return;
      }

      if (amount < 50) {
        _amountError = AppLocalizations.of(context)!.amountMinimum;
        return;
      }

      // Calculer le total avec frais (5%)
      final transferFee = amount * 0.05;
      final totalAmount = amount + transferFee;

      if (totalAmount > balanceProvider.solde) {
        _amountError = AppLocalizations.of(
          context,
        )!.insufficientBalance(totalAmount.toStringAsFixed(0));
        return;
      }

      _amountError = null;
    });
  }

  void _validateAndSendTransfer() {
    // Validation finale du destinataire
    final recipient = PhoneNumberValidator.cleanPhoneNumber(
      _recipientController.text,
    );

    if (recipient.isEmpty) {
      setState(() {
        _recipientError = AppLocalizations.of(context)!.recipientRequired;
      });
      return;
    }

    // Validation du numéro
    final phoneValidation = PhoneNumberValidator.validatePhoneNumber(recipient);
    if (phoneValidation != null) {
      setState(() {
        _recipientError = phoneValidation;
      });
      return;
    }

    // Vérifier que ce n'est pas le même numéro
    if (recipient == widget.phoneNumber) {
      setState(() {
        _recipientError = AppLocalizations.of(context)!.selfTransferError;
      });
      return;
    }

    // Validation finale du montant
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _amountError = AppLocalizations.of(context)!.amountInvalid;
      });
      return;
    }

    // Si tout est valide, naviguer vers l'écran de confirmation
    final transferFee = amount * 0.05;
    _navigateToConfirmation(recipient, amount, transferFee);
  }

  void _navigateToConfirmation(
    String recipient,
    double amount,
    double transferFee,
  ) {
    // Navigation vers l'écran de confirmation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TransferConfirmationScreen(
              phoneNumber: widget.phoneNumber,
              recipient: recipient,
              amount: amount,
              transferFee: transferFee,
            ),
      ),
    );
  }
}
