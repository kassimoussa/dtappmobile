import 'package:dtservices/config/api_client.dart';
import 'package:dtservices/config/app_config.dart';
// lib/services/profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'user_session.dart';

class ProfileService {
  static const String profileUrl = '${AppConfig.baseUrl}/mobile/profile';
  static const String updateProfileUrl = '${AppConfig.baseUrl}/mobile/update-profile';

  /// Cache en mémoire du dernier profil chargé, pour éviter d'afficher
  /// l'écran de chargement à chaque ouverture de l'écran profil.
  static Map<String, dynamic>? cachedProfile;

  /// Récupère le profil utilisateur complet
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      // Vérifier l'authentification
      final sessionToken = await UserSession.getSessionToken();
      if (sessionToken == null) {
        debugPrint('Profile Service: Aucun session token');
        return null;
      }

      debugPrint('Profile Service: Récupération profil avec token: ${sessionToken.substring(0, 10)}...');

      // Appeler l'API
      final response = await http.post(
        Uri.parse(profileUrl),
        headers: await ApiClient.authHeaders(),
        body: jsonEncode({
          'session_token': sessionToken,
        }),
      );

      debugPrint('Profile API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'success') {
          cachedProfile = responseData['data'];
          return cachedProfile;
        } else {
          debugPrint('Profile API: Échec - ${responseData['message']}');
          return null;
        }
      } else {
        debugPrint('Profile API: Erreur HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur Profile Service: $e');
      return null;
    }
  }

  /// Met à jour le profil utilisateur
  static Future<bool> updateUserProfile({
    required String name,
    required String email,
  }) async {
    try {
      // Vérifier l'authentification
      final sessionToken = await UserSession.getSessionToken();
      if (sessionToken == null) {
        debugPrint('Update Profile: Aucun session token');
        return false;
      }

      debugPrint('Update Profile: Mise à jour avec token: ${sessionToken.substring(0, 10)}...');

      // Préparer les données
      final payload = {
        'session_token': sessionToken,
      };

      // Ajouter seulement les champs non vides
      if (name.isNotEmpty) {
        payload['name'] = name;
      }
      if (email.isNotEmpty) {
        payload['email'] = email;
      }

      debugPrint('Update Profile payload: ${jsonEncode(payload)}');

      // Appeler l'API
      final response = await http.post(
        Uri.parse(updateProfileUrl),
        headers: await ApiClient.authHeaders(),
        body: jsonEncode(payload),
      );

      debugPrint('Update Profile API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          debugPrint('Profil mis à jour avec succès');
          return true;
        }
        final msg = responseData['message'] as String? ?? '';
        throw Exception(msg.isNotEmpty ? msg : 'Échec de la mise à jour');
      } else if (response.statusCode == 422) {
        // Erreur de validation — extraire le premier message du champ errors
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final errors = responseData['errors'] as Map<String, dynamic>?;
        String msg = responseData['message'] as String? ?? '';
        if (errors != null && errors.isNotEmpty) {
          final firstField = errors.values.first;
          if (firstField is List && firstField.isNotEmpty) {
            msg = firstField.first as String;
          }
        }
        throw Exception(msg.isNotEmpty ? msg : 'Données invalides');
      } else {
        debugPrint('Update Profile: Erreur HTTP ${response.statusCode}');
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Erreur Update Profile: $e');
      return false;
    }
  }
}