import 'package:dtservices/config/api_client.dart';
import 'package:dtservices/config/app_config.dart';
// lib/services/pin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Service pour gérer l'authentification par PIN
/// Fournit les méthodes pour login, configuration, modification et réinitialisation du PIN
class PinService {
  static const String baseUrl = AppConfig.baseUrl;

  /// Connexion avec PIN
  ///
  /// Rate limit: 5 requêtes/minute par IP
  ///
  /// Retourne un Map avec:
  /// - status: 'success' ou 'error'
  /// - message: message descriptif
  /// - data: {session_token, expires_at, user} si succès
  /// - data: {remaining_attempts, locked_until, remaining_seconds} si erreur
  static Future<Map<String, dynamic>> loginWithPin({
    required String phoneNumber,
    required String pin,
    String? deviceType,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      debugPrint('PinService: Login avec PIN pour $phoneNumber');

      // Formater le numéro (ajouter 253 si nécessaire)
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (formattedPhone.length == 8 && !formattedPhone.startsWith('253')) {
        formattedPhone = '253$formattedPhone';
      }

      final Map<String, dynamic> body = {
        'phone_number': formattedPhone,
        'pin': pin,
        'device_type': deviceType ?? 'android',
      };

      // Ajouter device_info si fourni
      if (deviceInfo != null) {
        body['device_info'] = deviceInfo;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/mobile/login-pin'),
        headers: await ApiClient.authHeaders(),
        body: jsonEncode(body),
      );

      debugPrint(
        'PinService: Response ${response.statusCode} - ${response.body}',
      );

      final responseData = jsonDecode(response.body);

      // Gérer les différents codes de statut
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return {
          'status': 'success',
          'message': responseData['message'] ?? 'Connexion réussie',
          'data': responseData['data'],
        };
      } else if (response.statusCode == 401) {
        // PIN incorrect
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Code PIN incorrect',
          'error_code': 'invalid_pin',
          'data': responseData['data'], // {remaining_attempts}
        };
      } else if (response.statusCode == 429) {
        // Compte verrouillé
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Compte verrouillé',
          'error_code': 'account_locked',
          'data': responseData['data'], // {locked_until, remaining_seconds}
        };
      } else if (response.statusCode == 400) {
        // PIN non configuré ou validation échouée
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Requête invalide',
          'error_code': 'bad_request',
        };
      } else if (response.statusCode == 403) {
        // Compte désactivé
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Compte désactivé',
          'error_code': 'account_inactive',
        };
      } else if (response.statusCode == 404) {
        // Utilisateur introuvable
        return {
          'status': 'error',
          'message':
              responseData['message'] ?? 'Numéro de téléphone non trouvé',
          'error_code': 'user_not_found',
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Erreur lors de la connexion',
          'error_code': 'unknown_error',
        };
      }
    } catch (e) {
      debugPrint('❌ PinService: Erreur login PIN: $e');
      return {
        'status': 'error',
        'message': 'Erreur de connexion au serveur',
        'error_code': 'network_error',
      };
    }
  }

  /// Configure le PIN pour la première fois
  ///
  /// Nécessite une session active (après connexion OTP)
  /// Le PIN doit être exactement 4 chiffres numériques
  static Future<Map<String, dynamic>> setPin({
    required String sessionToken,
    required String pin,
    required String pinConfirmation,
  }) async {
    try {
      debugPrint('PinService: Configuration du PIN');

      final response = await http.post(
        Uri.parse('$baseUrl/mobile/set-pin'),
        headers: await ApiClient.authHeaders(),
        body: jsonEncode({
          'session_token': sessionToken,
          'pin': pin,
          'pin_confirmation': pinConfirmation,
        }),
      );

      debugPrint(
        'PinService: Response ${response.statusCode} - ${response.body}',
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return {
          'status': 'success',
          'message':
              responseData['message'] ?? 'Code PIN configuré avec succès',
          'data': responseData['data'],
        };
      } else if (response.statusCode == 401) {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Session non valide',
          'error_code': 'invalid_session',
        };
      } else if (response.statusCode == 400) {
        return {
          'status': 'error',
          'message':
              responseData['message'] ?? 'Un code PIN est déjà configuré',
          'error_code': 'pin_already_exists',
        };
      } else if (response.statusCode == 422) {
        // Erreurs de validation
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Validation échouée',
          'error_code': 'validation_error',
          'errors': responseData['errors'],
        };
      } else {
        return {
          'status': 'error',
          'message':
              responseData['message'] ??
              'Erreur lors de la configuration du PIN',
          'error_code': 'unknown_error',
        };
      }
    } catch (e) {
      debugPrint('❌ PinService: Erreur configuration PIN: $e');
      return {
        'status': 'error',
        'message': 'Erreur de connexion au serveur',
        'error_code': 'network_error',
      };
    }
  }

  /// Modifie le PIN existant
  ///
  /// Nécessite l'ancien PIN pour validation
  /// Le nouveau PIN doit être différent de l'ancien
  static Future<Map<String, dynamic>> changePin({
    required String sessionToken,
    required String oldPin,
    required String newPin,
    required String newPinConfirmation,
  }) async {
    try {
      debugPrint('PinService: Modification du PIN');

      final response = await http.post(
        Uri.parse('$baseUrl/mobile/change-pin'),
        headers: await ApiClient.authHeaders(),
        body: jsonEncode({
          'session_token': sessionToken,
          'old_pin': oldPin,
          'new_pin': newPin,
          'new_pin_confirmation': newPinConfirmation,
        }),
      );

      debugPrint(
        'PinService: Response ${response.statusCode} - ${response.body}',
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return {
          'status': 'success',
          'message': responseData['message'] ?? 'Code PIN modifié avec succès',
          'data': responseData['data'],
        };
      } else if (response.statusCode == 401) {
        return {
          'status': 'error',
          'message':
              responseData['message'] ?? 'L\'ancien code PIN est incorrect',
          'error_code': 'invalid_old_pin',
        };
      } else if (response.statusCode == 422) {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Validation échouée',
          'error_code': 'validation_error',
          'errors': responseData['errors'],
        };
      } else {
        return {
          'status': 'error',
          'message':
              responseData['message'] ??
              'Erreur lors de la modification du PIN',
          'error_code': 'unknown_error',
        };
      }
    } catch (e) {
      debugPrint('❌ PinService: Erreur modification PIN: $e');
      return {
        'status': 'error',
        'message': 'Erreur de connexion au serveur',
        'error_code': 'network_error',
      };
    }
  }

  /// Réinitialise le PIN
  ///
  /// Efface automatiquement le verrouillage du compte
  /// L'OTP doit être vérifié au préalable via /verify
  static Future<Map<String, dynamic>> resetPin({
    required String phoneNumber,
    required String newPin,
    required String newPinConfirmation,
  }) async {
    try {
      debugPrint('PinService: Réinitialisation du PIN pour $phoneNumber');

      // Formater le numéro (OTP attend 8 chiffres)
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (formattedPhone.startsWith('253')) {
        formattedPhone = formattedPhone.substring(3);
      }

      final body = {
        'phone_number': formattedPhone,
        'new_pin': newPin,
        'new_pin_confirmation': newPinConfirmation,
      };

      debugPrint('PinService: Sending Reset PIN Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/mobile/reset-pin'),
        headers: await ApiClient.authHeaders(),
        body: jsonEncode(body),
      );

      debugPrint(
        'PinService: Response ${response.statusCode} - ${response.body}',
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return {
          'status': 'success',
          'message':
              responseData['message'] ?? 'Code PIN réinitialisé avec succès',
          'data': responseData['data'],
        };
      } else if (response.statusCode == 401) {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Code OTP invalide ou expiré',
          'error_code': 'invalid_otp',
        };
      } else if (response.statusCode == 422) {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Validation échouée',
          'error_code': 'validation_error',
          'errors': responseData['errors'],
        };
      } else {
        return {
          'status': 'error',
          'message':
              responseData['message'] ??
              'Erreur lors de la réinitialisation du PIN',
          'error_code': 'unknown_error',
        };
      }
    } catch (e) {
      debugPrint('❌ PinService: Erreur réinitialisation PIN: $e');
      return {
        'status': 'error',
        'message': 'Erreur de connexion au serveur',
        'error_code': 'network_error',
      };
    }
  }

  /// Valide le format d'un PIN (côté client)
  ///
  /// Retourne true si le PIN est valide:
  /// - Exactement 4 caractères
  /// - Tous des chiffres
  static bool isValidPinFormat(String pin) {
    return pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin);
  }

  /// Vérifie si un PIN est considéré comme faible
  ///
  /// Retourne true pour les PINs faibles communs:
  /// - 0000, 1111, 2222, etc.
  /// - 1234, 4321
  /// - 0123, 9876
  static bool isWeakPin(String pin) {
    if (pin.length != 4) return false;

    // PINs avec tous les mêmes chiffres
    if (RegExp(r'^(\d)\1{3}$').hasMatch(pin)) return true;

    // Séquences communes
    const weakPins = [
      '1234',
      '4321',
      '0123',
      '3210',
      '1111',
      '2222',
      '3333',
      '4444',
      '5555',
      '6666',
      '7777',
      '8888',
      '9999',
      '0000',
    ];

    return weakPins.contains(pin);
  }

  /// Retourne un message d'avertissement si le PIN est faible
  static String? getWeakPinWarning(String pin) {
    if (isWeakPin(pin)) {
      return 'Ce code PIN est trop simple. Choisissez un code plus sécurisé.';
    }
    return null;
  }
}
