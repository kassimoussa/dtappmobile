// lib/services/profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'user_session.dart';

class ProfileService {
  static const String profileUrl = 'http://10.39.230.106/api/mobile/profile';
  static const String updateProfileUrl = 'http://10.39.230.106/api/mobile/update-profile';

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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'session_token': sessionToken,
        }),
      );

      debugPrint('Profile API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'success') {
          return responseData['data'];
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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint('Update Profile API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'success') {
          debugPrint('Profil mis à jour avec succès');
          return true;
        } else {
          debugPrint('Update Profile: Échec - ${responseData['message']}');
          return false;
        }
      } else {
        debugPrint('Update Profile: Erreur HTTP ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Erreur Update Profile: $e');
      return false;
    }
  }
}