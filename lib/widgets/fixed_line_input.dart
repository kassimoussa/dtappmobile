// lib/widgets/fixed_line_input.dart
import 'package:flutter/material.dart';

class FixedLineInput extends StatefulWidget {
  final Function(String) onSubmit;

  const FixedLineInput({super.key, required this.onSubmit});

  @override
  State<FixedLineInput> createState() => _FixedLineInputState();
}

class _FixedLineInputState extends State<FixedLineInput> {
  final TextEditingController _fixedLineController = TextEditingController();
  final Color djiboutiBlue = const Color(0xFF002555);

  @override
  void dispose() {
    _fixedLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Consulter votre ligne fixe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: djiboutiBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Veuillez entrer votre numéro de ligne fixe pour consulter son statut et ses informations',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _fixedLineController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Numéro de ligne fixe',
                  prefixIcon: Icon(Icons.phone, color: djiboutiBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: djiboutiBlue, width: 2),
                  ),
                  hintText: 'Ex: 21XXXXXX',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: djiboutiBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Vérifier et traiter le numéro de ligne fixe
                    String inputNumber = _fixedLineController.text.trim();
                    if (inputNumber.isNotEmpty) {
                      widget.onSubmit(inputNumber);
                    }
                  },
                  child: const Text(
                    'Consulter',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}