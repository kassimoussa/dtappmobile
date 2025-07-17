// lib/services/refill_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:dtapp3/models/refill_models.dart';

class RefillService {
  static const String _baseUrl = 'http://10.39.230.106/api/air/refill/voucher';
  static const Duration _timeout = Duration(seconds: 30);

  /// Effectue une recharge avec un code voucher
  /// 
  /// [phoneNumber] : Le numéro de téléphone (format: 77XXXXXX ou 25377XXXXXX)
  /// [voucherCode] : Le code de recharge à 12 chiffres
  /// 
  /// Returns [RefillResponse] si succès
  /// Throws [RefillException] si erreur
  static Future<RefillResponse> processRefillCode({
    required String phoneNumber,
    required String voucherCode,
  }) async {
    try {
      // Nettoyer le numéro et le code
      final cleanPhoneNumber = _cleanPhoneNumber(phoneNumber);
      final cleanVoucherCode = _cleanVoucherCode(voucherCode);

      // Validation des paramètres
      _validateInputs(cleanPhoneNumber, cleanVoucherCode);

      // Debug des paramètres
      print('=== PARAMETRES REQUETE ===');
      print('Numéro original: $phoneNumber');
      print('Numéro nettoyé: $cleanPhoneNumber');
      print('Code voucher: $cleanVoucherCode');
      print('==========================');

      // Construire l'URL
      final uri = Uri.parse(_baseUrl);
      
      print('URL de la requête: $_baseUrl');

      // Préparer le body de la requête comme dans le fichier de test
      final Map<String, dynamic> requestBody = {
        'msisdn': cleanPhoneNumber,
        'voucher_code': cleanVoucherCode,
        'request_details': true,
        'request_account_before': true,
        'request_account_after': true,
      };

      print('Body de la requête: ${jsonEncode(requestBody)}');

      // Faire la requête HTTP POST
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      print('Status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      // Vérifier le status code
      if (response.statusCode == 404) {
        throw RefillException(
          code: -404,
          message: 'Route API non trouvée',
        );
      }

      if (response.statusCode != 200) {
        // Essayer de parser le body pour avoir plus d'infos sur l'erreur
        String errorMessage = 'Erreur HTTP: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorData.containsKey('message_reponse')) {
            errorMessage = errorData['message_reponse'];
          } else if (errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          } else if (errorData.containsKey('errors')) {
            errorMessage = 'Erreurs de validation: ${errorData['errors']}';
          }
        } catch (e) {
          // Si on ne peut pas parser le JSON d'erreur, on garde le message basique
          errorMessage = 'Erreur ${response.statusCode}: ${response.body}';
        }
        
        throw RefillException(
          code: response.statusCode,
          message: errorMessage,
        );
      }

      // Parser la réponse
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Debug: afficher la réponse brute
      print('=== REPONSE API BRUTE ===');
      print(jsonEncode(responseData));
      print('=========================');
      
      final refillResponse = RefillResponse.fromJson(responseData);

      // Vérifier si la requête a réussi
      if (refillResponse.isSuccess) {
        return refillResponse;
      } else {
        throw RefillException(
          code: refillResponse.codeReponse,
          message: refillResponse.messageReponse,
          transactionId: refillResponse.transactionId,
        );
      }
    } on RefillException {
      // Re-lancer les exceptions de recharge
      rethrow;
    } on SocketException catch (e) {
      print('SocketException: ${e.message}');
      throw RefillException(
        code: -1,
        message: 'Impossible de se connecter au serveur',
      );
    } on TimeoutException catch (e) {
      print('TimeoutException: ${e.message}');
      throw RefillException(
        code: -1,
        message: 'Délai d\'attente dépassé',
      );
    } on http.ClientException catch (e) {
      print('ClientException: ${e.message}');
      throw RefillException(
        code: -1,
        message: 'Erreur de connexion: ${e.message}',
      );
    } on FormatException catch (e) {
      print('FormatException: ${e.message}');
      throw RefillException(
        code: -2,
        message: 'Erreur de format de réponse',
      );
    } catch (e, stackTrace) {
      print('Exception générale: $e');
      print('StackTrace: $stackTrace');
      throw RefillException(
        code: -3,
        message: 'Erreur inattendue: $e',
      );
    }
  }

  /// Nettoie le numéro de téléphone pour le format API
  static String _cleanPhoneNumber(String phoneNumber) {
    // Enlever tous les espaces, tirets, parenthèses
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Selon le fichier de test, l'API accepte 77XXXXXX et 25377XXXXXX
    // Si le numéro commence par 77, le garder tel quel
    if (cleaned.startsWith('77') && cleaned.length == 8) {
      return cleaned;
    }
    // Si le numéro commence par 002537, enlever les "00"
    else if (cleaned.startsWith('002537')) {
      return cleaned.substring(2); // 002537XXXXXX -> 25377XXXXXX
    }
    // Si le numéro commence par 25377, le garder tel quel
    else if (cleaned.startsWith('25377')) {
      return cleaned;
    }
    
    return cleaned;
  }

  /// Nettoie le code voucher
  static String _cleanVoucherCode(String voucherCode) {
    return voucherCode.replaceAll(RegExp(r'[\s\-]'), '');
  }

  /// Valide les paramètres d'entrée
  static void _validateInputs(String phoneNumber, String voucherCode) {
    // Validation du numéro de téléphone
    if (phoneNumber.isEmpty) {
      throw RefillException(
        code: -100,
        message: 'Numéro de téléphone requis',
      );
    }

    // Accepter les formats 77XXXXXX et 25377XXXXXX comme dans le fichier de test
    if (!RegExp(r'^(77\d{6}|25377\d{6})$').hasMatch(phoneNumber)) {
      throw RefillException(
        code: -101,
        message: 'Format de numéro invalide. Utilisez 77XXXXXX ou 25377XXXXXX',
      );
    }

    // Validation du code voucher
    if (voucherCode.isEmpty) {
      throw RefillException(
        code: -102,
        message: 'Code de recharge requis',
      );
    }

    if (!RegExp(r'^\d{12}$').hasMatch(voucherCode)) {
      throw RefillException(
        code: -103,
        message: 'Le code de recharge doit contenir exactement 12 chiffres',
      );
    }
  }

  /// Teste si le serveur API est accessible
  static Future<void> testApiServer() async {
    try {
      print('=== TEST SERVEUR API ===');
      
      final response = await http.get(
        Uri.parse('http://10.39.230.106/api/air/refill/types'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 10));
      
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      
    } catch (e) {
      print('Erreur test serveur: $e');
    }
  }

  /// Méthode utilitaire pour obtenir le nouveau solde depuis la réponse
  static double? getNewBalanceFromResponse(RefillResponse response) {
    if (response.accountAfter?.balance != null) {
      try {
        return double.parse(response.accountAfter!.balance!) / 100;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Méthode utilitaire pour obtenir le montant rechargé depuis la réponse
  static double? getRefillAmountFromResponse(RefillResponse response) {
    if (response.balanceEvolution?.increase != null) {
      try {
        return response.balanceEvolution!.increase! / 100;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}