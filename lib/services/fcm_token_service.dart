import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'user_session.dart';

/// Service pour gérer les tokens FCM avec le serveur
///
/// IMPORTANT: Les tokens FCM sont associés au numéro de téléphone (pas à la session)
/// Cela permet aux utilisateurs de recevoir des notifications même déconnectés
class FCMTokenService {
  static const String baseUrl = 'http://10.39.230.106/api';
  static const String registerTokenEndpoint = '/mobile/fcm/register-token';
  static const String updateTokenEndpoint = '/mobile/fcm/update-token';

  /// Enregistre le token FCM avec un numéro de téléphone
  /// Appelé dès que l'utilisateur entre son numéro (avant même la vérification OTP)
  /// Permet de recevoir des notifications même sans être connecté
  static Future<bool> registerTokenWithPhone(String phoneNumber) async {
    try {
      if (!await FirebaseMessaging.instance.isSupported()) {
        debugPrint('⚠️ FCM: non supporté sur cet appareil');
        return false;
      }

      // Formater le numéro de téléphone
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
      if (!formattedPhone.startsWith('253')) {
        formattedPhone = '253$formattedPhone';
      }

      // Récupérer le token FCM
      final fcmToken = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ FCM: Token indisponible (service non accessible)');
        return false;
      }

      debugPrint('📱 FCM: Enregistrement pour $formattedPhone');
      debugPrint('🔑 FCM Token: ${fcmToken.substring(0, 20)}...');

      final url = Uri.parse('$baseUrl$registerTokenEndpoint');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'phone_number': formattedPhone,
          'fcm_token': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Token FCM enregistré pour $formattedPhone');
        // Sauvegarder le numéro localement pour les mises à jour futures
        await UserSession.setLastUsedPhoneForFCM(formattedPhone);
        return true;
      } else {
        debugPrint('❌ Erreur enregistrement FCM: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'enregistrement FCM: $e');
      return false;
    }
  }

  /// Met à jour le token FCM sur le serveur (utilisateur connecté)
  /// Utilise le session_token pour l'authentification
  static Future<bool> updateTokenOnServer() async {
    try {
      // Récupérer le session token
      final sessionToken = await UserSession.getSessionToken();
      if (sessionToken == null || sessionToken.isEmpty) {
        // Si pas de session, essayer avec le dernier numéro utilisé
        final lastPhone = await UserSession.getLastUsedPhoneForFCM();
        if (lastPhone != null && lastPhone.isNotEmpty) {
          debugPrint('ℹ️ FCM: Pas de session, utilisation du numéro enregistré');
          return await registerTokenWithPhone(lastPhone);
        }
        debugPrint('❌ FCM: Pas de session ni de numéro enregistré');
        return false;
      }

      if (!await FirebaseMessaging.instance.isSupported()) {
        debugPrint('⚠️ FCM: non supporté sur cet appareil');
        return false;
      }

      // Récupérer le token FCM
      final fcmToken = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ FCM: Token indisponible (service non accessible)');
        return false;
      }

      debugPrint('✅ FCM Token récupéré: ${fcmToken.substring(0, 20)}...');

      // Envoyer au serveur avec session token
      return await _sendTokenToServer(sessionToken, fcmToken);
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du token FCM: $e');
      return false;
    }
  }

  /// Envoie le token FCM au serveur (avec session)
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
        debugPrint('✅ Token FCM mis à jour avec succès');
        return true;
      } else {
        debugPrint(
            '❌ Erreur serveur lors de la mise à jour FCM: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur réseau lors de la mise à jour FCM: $e');
      return false;
    }
  }

  /// Écoute les changements de token FCM et met à jour le serveur
  /// Fonctionne même si l'utilisateur n'est pas connecté
  static void listenToTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 Nouveau token FCM reçu: ${newToken.substring(0, 20)}...');

      // Essayer d'abord avec la session
      final sessionToken = await UserSession.getSessionToken();
      if (sessionToken != null && sessionToken.isNotEmpty) {
        await _sendTokenToServer(sessionToken, newToken);
        return;
      }

      // Sinon utiliser le dernier numéro enregistré
      final lastPhone = await UserSession.getLastUsedPhoneForFCM();
      if (lastPhone != null && lastPhone.isNotEmpty) {
        await registerTokenWithPhone(lastPhone);
      }
    });
  }
}
