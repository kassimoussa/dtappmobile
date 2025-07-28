// lib/services/logout_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'user_session.dart';

class LogoutService {
  static const String logoutUrl = 'http://10.39.230.106/api/mobile/logout';

  /// Effectue la déconnexion complète (API + local)
  static Future<bool> logout() async {
    try {
      // Récupérer le session token
      final sessionToken = await UserSession.getSessionToken();
      
      if (sessionToken == null) {
        debugPrint('Logout: Aucun session token trouvé');
        // Nettoyer quand même localement
        await UserSession.clearSession();
        return true;
      }

      debugPrint('Logout: Appel API avec token: ${sessionToken.substring(0, 10)}...');

      // Appeler l'API logout
      final response = await http.post(
        Uri.parse(logoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'session_token': sessionToken,
        }),
      );

      debugPrint('Logout API: ${response.statusCode} - ${response.body}');

      // Nettoyer la session locale dans tous les cas
      await UserSession.clearSession();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Logout réussi: ${responseData['message']}');
        return true;
      } else {
        debugPrint('Logout API failed: ${response.statusCode}');
        // Même en cas d'erreur API, on considère le logout local comme réussi
        return true;
      }
    } catch (e) {
      debugPrint('Erreur lors du logout: $e');
      
      // En cas d'erreur, nettoyer quand même localement
      try {
        await UserSession.clearSession();
      } catch (clearError) {
        debugPrint('Erreur nettoyage session: $clearError');
      }
      
      // Retourner true pour permettre la navigation même en cas d'erreur
      return true;
    }
  }
}