import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/widgets/dt_button.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
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
  final FocusNode _amountFocusNode = FocusNode();
  String? _recipientError;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    // Validation complete du montant seulement quand le champ perd le focus
    _amountFocusNode.addListener(() {
      if (mounted && !_amountFocusNode.hasFocus) {
        _validateAmount(_amountController.text, complete: true);
      }
    });
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
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
              decoration: const BoxDecoration(
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
                GlassAppBar(title: AppLocalizations.of(context)!.transferTitle),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
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
              _buildInfoBox(),

              const SizedBox(height: 24),
            ],
          ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveSize.getWidth(AppTheme.spacingM),
                    0,
                    ResponsiveSize.getWidth(AppTheme.spacingM),
                    ResponsiveSize.getHeight(AppTheme.spacingL),
                  ),
                  child: _buildConfirmButton(),
                ),
              ],
            ),
          ),
        ],
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
            focusNode: _amountFocusNode,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.amountHint,
              suffixText: 'DJF',
              prefixIcon: const Icon(Icons.attach_money, color: AppTheme.dtBlue),
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
    final l10n = AppLocalizations.of(context)!;
    final solde = context.watch<BalanceProvider>().solde;

    final lines = [
      l10n.transferMinAmountParams,
      l10n.transferCurrentBalance(solde.toStringAsFixed(0)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dtBlueO10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dtBlueO30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.dtBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.transferImportantInfo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Une ligne par regle, avec indentation suspendue sous la puce
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(color: AppTheme.dtBlue, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line.replaceFirst(RegExp(r'^•\s*'), ''),
                      style: const TextStyle(
                        color: AppTheme.dtBlue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

    return DtButton.primary(
      label: AppLocalizations.of(context)!.confirmTransfer,
      onPressed: isFormValid ? _validateAndSendTransfer : null,
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

  // Validation du montant.
  // Pendant la saisie (complete = false), on n'affiche pas les erreurs que
  // l'utilisateur est justement en train de corriger en tapant les chiffres
  // suivants (montant minimum, montant nul) : elles ne sont verifiees que
  // lorsque le champ perd le focus ou a la confirmation.
  void _validateAmount(String value, {bool complete = false}) {
    final error = _amountErrorFor(value, complete: complete);
    if (error != _amountError) {
      setState(() => _amountError = error);
    }
  }

  String? _amountErrorFor(String value, {required bool complete}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final amount = double.tryParse(trimmed);
    if (amount == null) {
      return AppLocalizations.of(context)!.amountInvalid;
    }

    if (complete) {
      if (amount <= 0) {
        return AppLocalizations.of(context)!.amountPositive;
      }

      if (amount < 50) {
        return AppLocalizations.of(context)!.amountMinimum;
      }
    }

    // Le solde insuffisant ne peut pas se corriger en tapant d'autres
    // chiffres (le montant ne fait qu'augmenter) : on l'affiche des la saisie.
    final totalAmount = amount + amount * 0.05;
    if (totalAmount > context.read<BalanceProvider>().solde) {
      return AppLocalizations.of(
        context,
      )!.insufficientBalance(totalAmount.toStringAsFixed(0));
    }

    return null;
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

    // Validation finale du montant (minimum, solde, format)
    final amountText = _amountController.text.trim();
    final amountError = _amountErrorFor(amountText, complete: true);
    if (amountError != null) {
      setState(() {
        _amountError = amountError;
      });
      return;
    }

    final amount = double.parse(amountText);

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
