import 'package:dtservices/config/app_config.dart';
// lib/services/mobile_status_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Service pour vérifier le statut d'un numéro mobile
/// Utilise l'endpoint /api/mobile/check-status
class MobileStatusService {
  static const String baseUrl = AppConfig.baseUrl;
  static const String checkStatusEndpoint = '/mobile/check-status';

  /// Vérifie le statut complet d'un numéro mobile
  ///
  /// Retourne un Map avec les informations suivantes :
  /// - success: bool - Succès de la requête
  /// - exists_in_air: bool - Numéro existe dans le système AIR
  /// - exists_in_database: bool - Numéro enregistré dans la BDD
  /// - has_pin: bool - Utilisateur a configuré un PIN
  /// - account_type: String - Type de compte (prepaid/postpaid)
  /// - user_info: Map - Informations supplémentaires sur l'utilisateur
  static Future<Map<String, dynamic>> checkStatus(String phoneNumber) async {
    try {
      // Nettoyer le numéro de téléphone
      String cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

      // Si le numéro commence par 253, on le garde (format international accepté)
      // Sinon, c'est le format local 8 chiffres
      if (cleanPhoneNumber.startsWith('253')) {
        // Format international : 25377123456 (11 chiffres)
        if (cleanPhoneNumber.length != 11) {
          return {
            'success': false,
            'message': 'Format de numéro invalide (international doit être 11 chiffres)',
          };
        }
      } else {
        // Format local : 77123456 (8 chiffres)
        if (cleanPhoneNumber.length != 8) {
          return {
            'success': false,
            'message': 'Format de numéro invalide (local doit être 8 chiffres)',
          };
        }
      }

      debugPrint('MobileStatusService: Vérification du statut pour $cleanPhoneNumber');

      final response = await http.post(
        Uri.parse('$baseUrl$checkStatusEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'msisdn': cleanPhoneNumber,
        }),
      );

      debugPrint('MobileStatusService: Response ${response.statusCode} - ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Succès - Numéro trouvé
        return {
          'success': true,
          'message': responseData['message'] ?? 'Numéro trouvé',
          'exists_in_air': responseData['data']['exists_in_air'] ?? false,
          'exists_in_database': responseData['data']['exists_in_database'] ?? false,
          'has_pin': responseData['data']['has_pin'] ?? false,
          'account_type': responseData['data']['account_type'] ?? 'prepaid',
          'user_info': responseData['data']['user_info'] ?? {},
          'msisdn': responseData['data']['msisdn'] ?? cleanPhoneNumber,
        };
      } else if (response.statusCode == 404) {
        // Numéro non trouvé dans AIR
        return {
          'success': false,
          'message': responseData['message'] ?? 'Numéro non trouvé dans le système',
          'exists_in_air': false,
          'exists_in_database': false,
          'has_pin': false,
          'msisdn': responseData['data']?['msisdn'] ?? cleanPhoneNumber,
          'error_code': responseData['data']?['code_reponse'],
          'error_message': responseData['data']?['message_air'],
        };
      } else if (response.statusCode == 422) {
        // Erreur de validation
        return {
          'success': false,
          'message': 'Format de numéro invalide',
          'errors': responseData['errors'],
        };
      } else {
        // Autre erreur
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la vérification',
        };
      }
    } catch (e) {
      debugPrint('❌ MobileStatusService: Erreur lors de la vérification: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
        'error': e.toString(),
      };
    }
  }

  /// Détermine si un utilisateur doit être redirigé vers le login PIN
  ///
  /// Retourne true si :
  /// - Le numéro existe dans AIR
  /// - Le numéro est enregistré dans la BDD
  /// - L'utilisateur a configuré un PIN
  static bool shouldUsePinLogin(Map<String, dynamic> statusData) {
    return statusData['success'] == true &&
        statusData['exists_in_air'] == true &&
        statusData['exists_in_database'] == true &&
        statusData['has_pin'] == true;
  }

  /// Détermine si un utilisateur est nouveau (première connexion)
  ///
  /// Retourne true si :
  /// - Le numéro existe dans AIR
  /// - Le numéro n'est pas encore enregistré dans la BDD
  static bool isNewUser(Map<String, dynamic> statusData) {
    return statusData['success'] == true &&
        statusData['exists_in_air'] == true &&
        statusData['exists_in_database'] == false;
  }

  /// Vérifie si le numéro est valide (existe dans AIR)
  static bool isValidNumber(Map<String, dynamic> statusData) {
    return statusData['success'] == true &&
        statusData['exists_in_air'] == true;
  }
}
