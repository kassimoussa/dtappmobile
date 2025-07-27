import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class RefillApiTest extends StatefulWidget {
  const RefillApiTest({super.key});

  @override
  _RefillApiTestState createState() => _RefillApiTestState();
}

class _RefillApiTestState extends State<RefillApiTest> {
  final String baseUrl = 'http://10.39.230.106/api/air'; // Remplacez par votre URL
  
  // Contrôleurs pour les champs de saisie
  final TextEditingController msisdnController = TextEditingController();
  final TextEditingController voucherCodeController = TextEditingController();
  final TextEditingController refillTypeController = TextEditingController(text: '2');
  final TextEditingController selectedOptionController = TextEditingController(text: '1');
  
  String result = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test API Rechargement'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Champ MSISDN
            TextField(
              controller: msisdnController,
              decoration: InputDecoration(
                labelText: 'MSISDN',
                hintText: '77001011 ou 25377001011',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            
            // Champ Code Voucher
            TextField(
              controller: voucherCodeController,
              decoration: InputDecoration(
                labelText: 'Code Voucher (12 chiffres)',
                hintText: '637869512723',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 12,
            ),
            SizedBox(height: 16),
            
            // Champs optionnels
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: refillTypeController,
                    decoration: InputDecoration(
                      labelText: 'Refill Type',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: selectedOptionController,
                    decoration: InputDecoration(
                      labelText: 'Selected Option',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Boutons de test
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isLoading ? null : () => testRefillVoucher(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('Recharger'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () => testCheckVoucher(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: Text('Vérifier Voucher'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () => testGetTypes(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text('Types Refill'),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Indicateur de chargement
            if (isLoading)
              CircularProgressIndicator(),
            
            // Résultats
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    result.isEmpty ? 'Les résultats apparaîtront ici...' : result,
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Test de rechargement par voucher
  Future<void> testRefillVoucher() async {
    if (!_validateInputs()) return;
    
    setState(() {
      isLoading = true;
      result = 'Envoi de la requête de rechargement...\n';
    });

    try {
      final url = Uri.parse('$baseUrl/refill/voucher');
      
      final requestBody = {
        'msisdn': msisdnController.text.trim(),
        'voucher_code': voucherCodeController.text.trim(),
        'refill_type': int.parse(refillTypeController.text),
        'selected_option': int.parse(selectedOptionController.text),
        'request_details': true,
        'request_account_before': true,
        'request_account_after': true,
      };

      print('🚀 Envoi de la requête POST à: $url');
      print('📦 Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      setState(() {
        result = _formatResponse(response);
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        result = '❌ Erreur: $e';
        isLoading = false;
      });
    }
  }

  // Test de vérification de voucher
  Future<void> testCheckVoucher() async {
    if (!_validateInputs()) return;
    
    setState(() {
      isLoading = true;
      result = 'Vérification du statut du voucher...\n';
    });

    try {
      final msisdn = msisdnController.text.trim();
      final url = Uri.parse('$baseUrl/refill/voucher/check/$msisdn');
      
      final requestBody = {
        'voucher_code': voucherCodeController.text.trim(),
      };

      print('🔍 Envoi de la requête POST à: $url');
      print('📦 Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      setState(() {
        result = _formatResponse(response);
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        result = '❌ Erreur: $e';
        isLoading = false;
      });
    }
  }

  // Test pour récupérer les types de rechargement
  Future<void> testGetTypes() async {
    setState(() {
      isLoading = true;
      result = 'Récupération des types de rechargement...\n';
    });

    try {
      final url = Uri.parse('$baseUrl/refill/types');
      
      print('📋 Envoi de la requête GET à: $url');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      print('📥 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      setState(() {
        result = _formatResponse(response);
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        result = '❌ Erreur: $e';
        isLoading = false;
      });
    }
  }

  // Validation des entrées
  bool _validateInputs() {
    final msisdn = msisdnController.text.trim();
    final voucherCode = voucherCodeController.text.trim();

    if (msisdn.isEmpty) {
      _showError('Le MSISDN est obligatoire');
      return false;
    }

    if (!RegExp(r'^(77\d{6}|25377\d{6})$').hasMatch(msisdn)) {
      _showError('MSISDN invalide. Format: 77XXXXXX ou 25377XXXXXX');
      return false;
    }

    if (voucherCode.isEmpty) {
      _showError('Le code voucher est obligatoire');
      return false;
    }

    if (!RegExp(r'^\d{12}$').hasMatch(voucherCode)) {
      _showError('Le code voucher doit contenir exactement 12 chiffres');
      return false;
    }

    return true;
  }

  // Affichage des erreurs
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Formatage de la réponse pour l'affichage
  String _formatResponse(http.Response response) {
    final buffer = StringBuffer();
    
    buffer.writeln('🌐 Status Code: ${response.statusCode}');
    buffer.writeln('📊 Status: ${_getStatusText(response.statusCode)}');
    buffer.writeln('⏰ Timestamp: ${DateTime.now().toIso8601String()}');
    buffer.writeln('='*50);
    
    try {
      // Tenter de parser le JSON pour un affichage formaté
      final jsonData = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        buffer.writeln('✅ SUCCÈS');
        
        if (jsonData['code_reponse'] != null) {
          buffer.writeln('📋 Code Réponse: ${jsonData['code_reponse']}');
          buffer.writeln('💬 Message: ${jsonData['message_reponse']}');
        }
        
        if (jsonData['transaction_id'] != null) {
          buffer.writeln('🆔 Transaction ID: ${jsonData['transaction_id']}');
        }
        
        if (jsonData['voucher_info'] != null) {
          final voucher = jsonData['voucher_info'];
          buffer.writeln('🎫 Voucher Info:');
          buffer.writeln('   • Serial: ${voucher['serial_number']}');
          buffer.writeln('   • Group: ${voucher['group']}');
          buffer.writeln('   • Agent: ${voucher['agent']}');
        }
        
        if (jsonData['balance_evolution'] != null) {
          final balance = jsonData['balance_evolution'];
          buffer.writeln('💰 Évolution Solde:');
          buffer.writeln('   • Avant: ${balance['before']} centimes');
          buffer.writeln('   • Après: ${balance['after']} centimes');
          buffer.writeln('   • Augmentation: ${balance['increase_formatted']}');
        }
        
        if (jsonData['refill_info'] != null) {
          final refill = jsonData['refill_info'];
          buffer.writeln('📈 Info Rechargement:');
          buffer.writeln('   • Montant: ${refill['amount_formatted']}');
          buffer.writeln('   • Jours supervision: ${refill['supervision_days_extended']}');
          buffer.writeln('   • Jours service fee: ${refill['service_fee_days_extended']}');
        }
        
      } else {
        buffer.writeln('❌ ERREUR');
        
        if (jsonData['code_reponse'] != null) {
          buffer.writeln('📋 Code Erreur: ${jsonData['code_reponse']}');
          buffer.writeln('💬 Message: ${jsonData['message_reponse']}');
        }
        
        if (jsonData['erreur'] != null) {
          buffer.writeln('🚨 Erreur: ${jsonData['erreur']}');
        }
        
        if (jsonData['errors'] != null) {
          buffer.writeln('📝 Erreurs de validation:');
          jsonData['errors'].forEach((field, messages) {
            buffer.writeln('   • $field: ${messages.join(', ')}');
          });
        }
      }
      
      buffer.writeln('='*50);
      buffer.writeln('📄 Réponse JSON complète:');
      buffer.writeln(JsonEncoder.withIndent('  ').convert(jsonData));
      
    } catch (e) {
      buffer.writeln('❌ Erreur de parsing JSON: $e');
      buffer.writeln('📄 Réponse brute:');
      buffer.writeln(response.body);
    }
    
    return buffer.toString();
  }

  String _getStatusText(int statusCode) {
    switch (statusCode) {
      case 200: return 'OK - Succès';
      case 409: return 'Conflict - Voucher déjà utilisé';
      case 422: return 'Unprocessable Entity - Erreur de validation';
      case 404: return 'Not Found - Abonné non trouvé';
      case 403: return 'Forbidden - Opération non autorisée';
      case 500: return 'Internal Server Error - Erreur serveur';
      default: return 'Status inconnu';
    }
  }

  @override
  void dispose() {
    msisdnController.dispose();
    voucherCodeController.dispose();
    refillTypeController.dispose();
    selectedOptionController.dispose();
    super.dispose();
  }
}

// Exemples de données de test
class TestData {
  static const Map<String, dynamic> validRequest = {
    'msisdn': '77001011',
    'voucher_code': '637869512723',
    'refill_type': 2,
    'selected_option': 1,
  };

  static const Map<String, dynamic> invalidVoucher = {
    'msisdn': '77001011',
    'voucher_code': '123456789012', // Voucher invalide
    'refill_type': 2,
    'selected_option': 1,
  };

  static const Map<String, dynamic> usedVoucher = {
    'msisdn': '77001011',
    'voucher_code': '637869512723', // Déjà utilisé
    'refill_type': 2,
    'selected_option': 1,
  };
}