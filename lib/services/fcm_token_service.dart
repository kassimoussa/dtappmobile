import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'user_session.dart';

/// Service pour gérer les tokens FCM avec le serveur
class FCMTokenService {
  static const String baseUrl = 'http://10.39.230.106/api';
  static const String updateTokenEndpoint = '/mobile/fcm/update-token';
  static const String clearTokenEndpoint = '/mobile/fcm/clear-token';

  /// Récupère le token FCM et l'envoie au serveur
  static Future<bool> updateTokenOnServer() async {
    try {
      // Récupérer le session token
      final sessionToken = await UserSession.getSessionToken();
      if (sessionToken == null || sessionToken.isEmpty) {
        debugPrint('❌ FCM: Pas de session token disponible');
        return false;
      }

      // Récupérer le token FCM
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('❌ FCM: Impossible de récupérer le token FCM');
        return false;
      }

      debugPrint('✅ FCM Token récupéré: ${fcmToken.substring(0, 20)}...');

      // Envoyer au serveur
      return await _sendTokenToServer(sessionToken, fcmToken);
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du token FCM: $e');
      return false;
    }
  }

  /// Envoie le token FCM au serveur
  static Future<bool> _sendTokenToServer(
      String sessionToken, String fcmToken) async {
    try {
      final url = Uri.parse('$baseUrl$updateTokenEndpoint');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'session_token': sessionToken,
          'fcm_token': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Token FCM envoyé avec succès au serveur');
        return true;
      } else {
        debugPrint(
            '❌ Erreur serveur lors de l\'envoi du token FCM: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur réseau lors de l\'envoi du token FCM: $e');
      return false;
    }
  }

  /// Supprime le token FCM du serveur (lors de la déconnexion)
  static Future<bool> clearTokenOnServer() async {
    try {
      // Récupérer le session token
      final sessionToken = await UserSession.getSessionToken();
      if (sessionToken == null || sessionToken.isEmpty) {
        debugPrint('❌ FCM: Pas de session token pour supprimer le token');
        return false;
      }

      final url = Uri.parse('$baseUrl$clearTokenEndpoint');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'session_token': sessionToken,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Token FCM supprimé du serveur avec succès');

        // Supprimer aussi le token local de Firebase
        await FirebaseMessaging.instance.deleteToken();
        debugPrint('✅ Token FCM local supprimé');

        return true;
      } else {
        debugPrint(
            '❌ Erreur serveur lors de la suppression du token FCM: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression du token FCM: $e');
      return false;
    }
  }

  /// Écoute les changements de token FCM et met à jour le serveur
  static void listenToTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 Nouveau token FCM reçu: ${newToken.substring(0, 20)}...');
      updateTokenOnServer();
    });
  }
}
