import 'package:flutter/services.dart';

// Une classe simple pour gérer les appels USSD
class UssdService {
  // Définir un canal de communication unique avec le code natif
  static const MethodChannel _channel = MethodChannel('com.example.dtapp2/ussd');

   /// Envoie une requête USSD et tente de récupérer la réponse.
  /// 
  /// Sur Android 8+, cette méthode peut récupérer la réponse. Sur les appareils
  /// plus anciens et iOS, elle peut seulement envoyer la requête.
  /// 
  /// [code] doit être un code USSD valide (par exemple: *123#).
  /// Retourne la réponse ou un message expliquant pourquoi la réponse 
  /// ne peut pas être capturée.
  static Future<String> sendUssdRequest(String code) async {
    try {
      final String response = await _channel.invokeMethod(
        'sendUssdRequest',
        {'code': code},
      );
      return response;
    } on PlatformException catch (e) {
      return 'Erreur USSD: ${e.message}';
    }
  }
  
  /// Vérifie le solde du compte via USSD.
  /// Ceci est une méthode spécifique pour l'application DT Mobile.
  static Future<String> checkBalance() async {
    // Remplacez ce code par le code USSD réel pour vérifier le solde chez Djibouti Telecom
    return sendUssdRequest('*168#');
  }

  /// Vérifie et analyse le solde, retourne un objet structuré
  static Future<Map<String, dynamic>> getBalanceInfo() async {
    final response = await checkBalance();
    return parseBalanceResponse(response);
  }
  
  /// Analyse la réponse de solde et extrait les informations importantes
  static Map<String, dynamic> parseBalanceResponse(String response) {
    final Map<String, dynamic> result = {
      'rawResponse': response,
      'solde': 0.0,
      'bonus': 0.0,
      'dateExpiration': '',
      'success': false,
    };
    
    // Vérifier si la réponse contient une erreur
    if (response.contains('Erreur')) {
      return result;
    }
    
    try {
      // Extraire le solde
      final soldeRegex = RegExp(r'solde actuel est (\d+\.\d+)');
      final soldeMatch = soldeRegex.firstMatch(response);
      if (soldeMatch != null && soldeMatch.groupCount >= 1) {
        result['solde'] = double.parse(soldeMatch.group(1)!);
      }
      
      // Extraire la date d'expiration
      final dateRegex = RegExp(r'expire le (\d{2}-\d{2}-\d{2})');
      final dateMatch = dateRegex.firstMatch(response);
      if (dateMatch != null && dateMatch.groupCount >= 1) {
        result['dateExpiration'] = dateMatch.group(1)!;
      }
      
      // Extraire le bonus
      final bonusRegex = RegExp(r'Credit Bonus: (\d+\.\d+)');
      final bonusMatch = bonusRegex.firstMatch(response);
      if (bonusMatch != null && bonusMatch.groupCount >= 1) {
        result['bonus'] = double.parse(bonusMatch.group(1)!);
      }
      
      // Si au moins un élément a été extrait, la requête est considérée comme réussie
      if (result['solde'] > 0 || result['dateExpiration'].isNotEmpty) {
        result['success'] = true;
      }
      
    } catch (e) {
      print('Erreur lors de l\'analyse de la réponse: $e');
    }
    
    return result;
  }
  
  /// Vérifie les données Internet restantes.
  static Future<String> checkDataBalance() async {
    // Remplacez ce code par le code USSD réel pour Djibouti Telecom
    return sendUssdRequest('*165#');
  }
}