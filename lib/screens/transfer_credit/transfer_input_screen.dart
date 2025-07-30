import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/screens/transfer_credit/transfer_confirmation_screen.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/utils/phone_number_validator.dart';
import 'package:dtservices/widgets/appbar_widget.dart';
import 'package:dtservices/widgets/phone_number_selector.dart';
import 'package:flutter/material.dart';

class TransferInputScreen extends StatefulWidget {
  final String phoneNumber;
  final double soldeActuel;
  final VoidCallback? onRefreshSolde;

  const TransferInputScreen({
    super.key,
    required this.phoneNumber,
    required this.soldeActuel,
    this.onRefreshSolde,
  });

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: "Transfert de crédit", 
        showAction: true, 
        value: widget.soldeActuel
      ),
      body: Padding(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              
              // Sélecteur de numéro destinataire
              PhoneNumberSelector(
                controller: _recipientController,
                labelText: 'Numéro destinataire',
                onChanged: (value) {
                  // Effacer l'erreur en temps réel et valider
                  setState(() {
                    _recipientError = null;
                  });
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
              
              const SizedBox(height: 32),
              
              // Bouton de confirmation
              _buildConfirmButton(),
              
              const SizedBox(height: 24),
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
          'Montant à transférer',
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
              hintText: 'Ex: 1000',
              suffixText: 'DJF',
              prefixIcon: Icon(
                Icons.attach_money,
                color: AppTheme.dtBlue,
              ),
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
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour la boîte d'information
  Widget _buildInfoBox() {
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
                'Informations importantes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Montant minimum : 50 DJF\n'
            '• Frais de transfert : 5% du montant\n'
            '• Votre solde actuel : ${widget.soldeActuel.toStringAsFixed(0)} DJF',
            style: TextStyle(
              color: AppTheme.dtBlue,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour le bouton de confirmation
  Widget _buildConfirmButton() {
    bool isFormValid = _recipientError == null && 
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
          'Confirmer le transfert',
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
    if (value.isEmpty) {
      setState(() {
        _recipientError = null;
      });
      return;
    }

    final cleanNumber = PhoneNumberValidator.cleanPhoneNumber(value);
    
    // Validation du format
    final phoneValidation = PhoneNumberValidator.validatePhoneNumber(cleanNumber);
    if (phoneValidation != null) {
      setState(() {
        _recipientError = phoneValidation;
      });
      return;
    }

    // Vérifier que ce n'est pas le même numéro
    if (cleanNumber == widget.phoneNumber) {
      setState(() {
        _recipientError = 'Vous ne pouvez pas vous transférer de l\'argent';
      });
      return;
    }

    setState(() {
      _recipientError = null;
    });
  }

  // Validation du montant en temps réel
  void _validateAmount(String value) {
    setState(() {
      if (value.isEmpty) {
        _amountError = null;
        return;
      }

      final amount = double.tryParse(value);
      if (amount == null) {
        _amountError = 'Montant invalide';
        return;
      }

      if (amount <= 0) {
        _amountError = 'Le montant doit être supérieur à 0';
        return;
      }

      if (amount < 50) {
        _amountError = 'Montant minimum : 50 DJF';
        return;
      }

      // Calculer le total avec frais (5%)
      final transferFee = amount * 0.05;
      final totalAmount = amount + transferFee;

      if (totalAmount > widget.soldeActuel) {
        _amountError = 'Solde insuffisant (total avec frais: ${totalAmount.toStringAsFixed(0)} DJF)';
        return;
      }

      _amountError = null;
    });
  }

  void _validateAndSendTransfer() {
    // Validation finale du destinataire
    final recipient = PhoneNumberValidator.cleanPhoneNumber(_recipientController.text);
    
    if (recipient.isEmpty) {
      setState(() {
        _recipientError = 'Veuillez entrer un numéro de destinataire';
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
        _recipientError = 'Vous ne pouvez pas vous transférer de l\'argent';
      });
      return;
    }

    // Validation finale du montant
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _amountError = 'Montant invalide';
      });
      return;
    }

    // Si tout est valide, naviguer vers l'écran de confirmation
    final transferFee = amount * 0.05;
    _navigateToConfirmation(recipient, amount, transferFee);
  }

  void _navigateToConfirmation(String recipient, double amount, double transferFee) {
    // Navigation vers l'écran de confirmation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransferConfirmationScreen(
          phoneNumber: widget.phoneNumber,
          recipient: recipient,
          amount: amount,
          transferFee: transferFee,
          soldeActuel: widget.soldeActuel,
          onRefreshSolde: widget.onRefreshSolde,
        ),
      ),
    );
  }
}