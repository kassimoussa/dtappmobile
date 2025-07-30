// lib/screens/autre_numero_screen.dart
import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/routes/custom_route_transitions.dart';
import 'package:dtservices/screens/_unused/forfait_categories_screen2.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/widgets/phone_number_selector.dart';
import 'package:flutter/material.dart';

class ForfaitAutreNumeroScreen extends StatefulWidget {
  final String? phoneNumber;
  final double soldeActuel; 
  
  const ForfaitAutreNumeroScreen({
    super.key, 
    this.phoneNumber, 
    required this.soldeActuel
  });

  @override
  State<ForfaitAutreNumeroScreen> createState() => _ForfaitAutreNumeroScreenState();
}

class _ForfaitAutreNumeroScreenState extends State<ForfaitAutreNumeroScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
     
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.dtBlue,
        title: Text(
          'Achat pour autre numéro',
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveSize.getFontSize(16),
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
              
              // Widget sélecteur de numéro réutilisable
              PhoneNumberSelector(
                controller: _phoneController,
                labelText: 'Entrez le numéro de téléphone',
                hintText: '77 XX XX XX',
                validator: DjiboutiPhoneValidator.validatePhoneNumber,
                onChanged: (value) {
                  // Optionnel : actions à effectuer lors du changement
                  setState(() {});
                },
              ),
              
              const SizedBox(height: 24),
              Text(
                'Le numéro doit être un numéro mobile valide à Djibouti',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              
              const Spacer(),
              
              // Bouton de continuation
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _validateAndContinue,
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
                    'Continuer',
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
  
  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      // Nettoyer le numéro (enlever les espaces)
      final cleanPhoneNumber = DjiboutiPhoneValidator.cleanPhoneNumber(
        _phoneController.text.trim()
      );
      
      // Navigation vers l'écran suivant
      Navigator.push(
        context,
        CustomRouteTransitions.slideRightRoute(
          page: ForfaitCategoriesScreen2(
            phoneNumber: cleanPhoneNumber,
            soldeActuel: widget.soldeActuel, 
          ),
        ),
      );
    }
  }
}