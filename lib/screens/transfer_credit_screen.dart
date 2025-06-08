// lib/screens/transfer_money_screen.dart
import 'package:dtapp3/constants/app_theme.dart';
import 'package:dtapp3/widgets/phone_number_selector.dart';
import 'package:flutter/material.dart';

class TransferCreditScreen extends StatefulWidget {
  const TransferCreditScreen({super.key});

  @override
  State<TransferCreditScreen> createState() => _TransferCreditScreenState();
}

class _TransferCreditScreenState extends State<TransferCreditScreen> {
  final TextEditingController _senderController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _senderController.dispose();
    _receiverController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.dtBlue,
        title: const Text(
          'Transfert d\'argent',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Numéro expéditeur
              PhoneNumberSelector(
                controller: _senderController,
                labelText: 'Numéro expéditeur',
                hintText: '77 XX XX XX',
                validator: DjiboutiPhoneValidator.validatePhoneNumber,
              ),
              
              const SizedBox(height: 24),
              
              // Numéro destinataire
              PhoneNumberSelector(
                controller: _receiverController,
                labelText: 'Numéro destinataire',
                hintText: '77 XX XX XX',
                validator: DjiboutiPhoneValidator.validatePhoneNumber,
                onChanged: (value) {
                  // Vérifier que ce n'est pas le même numéro
                  if (value.isNotEmpty && value == _senderController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Le destinataire ne peut pas être le même que l\'expéditeur'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
              
              const SizedBox(height: 24),
              
              // Montant
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant à transférer',
                  hintText: '1000',
                  suffixText: 'FDJ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un montant';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Veuillez saisir un montant valide';
                  }
                  if (amount < 100) {
                    return 'Le montant minimum est de 100 FDJ';
                  }
                  return null;
                },
              ),
              
              const Spacer(),
              
              // Bouton de transfert
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _processTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dtBlue2,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Effectuer le transfert',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  void _processTransfer() {
    if (_formKey.currentState!.validate()) {
      final senderNumber = DjiboutiPhoneValidator.cleanPhoneNumber(_senderController.text);
      final receiverNumber = DjiboutiPhoneValidator.cleanPhoneNumber(_receiverController.text);
      final amount = double.parse(_amountController.text);
      
      // Vérification finale
      if (senderNumber == receiverNumber) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L\'expéditeur et le destinataire ne peuvent pas être identiques'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Traitement du transfert
      _showConfirmationDialog(senderNumber, receiverNumber, amount);
    }
  }
  
  void _showConfirmationDialog(String sender, String receiver, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le transfert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('De: +253 $sender'),
            Text('Vers: +253 $receiver'),
            Text('Montant: ${amount.toStringAsFixed(0)} FDJ'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Logique de transfert ici
              _performTransfer(sender, receiver, amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dtBlue2,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
  
  void _performTransfer(String sender, String receiver, double amount) {
    // Simulation du transfert
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transfert effectué avec succès !'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Retour à l'écran précédent ou reset du formulaire
    Navigator.pop(context);
  }
}