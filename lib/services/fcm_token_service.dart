import 'package:dtservices/config/app_config.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_session.dart';

class FCMTokenService {
  static const String _baseUrl = AppConfig.baseUrl;
  static const String _registerEndpoint = '/mobile/fcm/register-token';
  static const String _updateEndpoint = '/mobile/fcm/update-token';
  static const String _clearEndpoint = '/mobile/fcm/clear-token';

  // Clé pour ne pas ré-enregistrer un token déjà connu du serveur
  static const String _registeredTokenKey = 'fcm_last_registered_token';

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static String _formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    return cleaned.startsWith('253') ? cleaned : '253$cleaned';
  }

  static Future<String?> _getFcmToken() async {
    if (!await FirebaseMessaging.instance.isSupported()) {
      debugPrint('⚠️ FCM: non supporté sur cet appareil');
      return null;
    }
    final token = await FirebaseMessaging.instance.getToken().timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
    if (token == null || token.isEmpty) {
      debugPrint('⚠️ FCM: token Firebase indisponible');
      return null;
    }
    return token;
  }

  static Future<String?> _getPhoneForRegistration() async {
    final sessionPhone = await UserSession.getPhoneNumber();
    if (sessionPhone != null && sessionPhone.isNotEmpty) {
      return _formatPhone(sessionPhone);
    }
    return await UserSession.getLastUsedPhoneForFCM();
  }

  /// Retourne true si ce token FCM est déjà enregistré sur le serveur
  static Future<bool> _isAlreadyRegistered(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_registeredTokenKey) == fcmToken;
  }

  static Future<void> _markTokenRegistered(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registeredTokenKey, fcmToken);
  }

  static Future<void> _clearRegisteredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_registeredTokenKey);
  }

  // ─── Appels API ──────────────────────────────────────────────────────────────

  static Future<bool> _callRegisterToken(
      String formattedPhone, String fcmToken) async {
    try {
      debugPrint('📱 FCM: register-token pour $formattedPhone');

      final response = await http.post(
        Uri.parse('$_baseUrl$_registerEndpoint'),
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
        debugPrint('✅ FCM: register-token OK pour $formattedPhone');
        await UserSession.setLastUsedPhoneForFCM(formattedPhone);
        await _markTokenRegistered(fcmToken);
        return true;
      }
      debugPrint(
          '❌ FCM: register-token ${response.statusCode} — ${response.body}');
      return false;
    } catch (e) {
      debugPrint('❌ FCM: register-token erreur réseau — $e');
      return false;
    }
  }

  static Future<bool> _callUpdateToken(
      String sessionToken, String fcmToken) async {
    try {
      debugPrint('🔄 FCM: update-token');

      final response = await http.post(
        Uri.parse('$_baseUrl$_updateEndpoint'),
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
        debugPrint('✅ FCM: update-token OK');
        await _markTokenRegistered(fcmToken);
        return true;
      }
      debugPrint(
          '⚠️ FCM: update-token ${response.statusCode} — ${response.body}');
      return false;
    } catch (e) {
      debugPrint('⚠️ FCM: update-token erreur réseau — $e');
      return false;
    }
  }

  // ─── API publique ─────────────────────────────────────────────────────────────

  /// Enregistre le token FCM avec un numéro de téléphone (avant connexion)
  static Future<bool> registerTokenWithPhone(String phoneNumber) async {
    final fcmToken = await _getFcmToken();
    if (fcmToken == null) return false;

    final formatted = _formatPhone(phoneNumber);

    // Éviter un double enregistrement si le token est déjà connu
    if (await _isAlreadyRegistered(fcmToken)) {
      debugPrint('✅ FCM: token déjà enregistré, skip register-token');
      return true;
    }

    return await _callRegisterToken(formatted, fcmToken);
  }

  /// Met à jour le token FCM après connexion.
  ///
  /// Stratégie :
  /// 1. Tente update-token (avec session_token)
  /// 2. Si échec ET token non encore enregistré → fallback register-token
  /// 3. Si le token est déjà connu du serveur, on considère que c'est OK
  static Future<bool> updateTokenOnServer() async {
    final fcmToken = await _getFcmToken();
    if (fcmToken == null) return false;

    final sessionToken = await UserSession.getSessionToken();
    if (sessionToken != null && sessionToken.isNotEmpty) {
      final ok = await _callUpdateToken(sessionToken, fcmToken);
      if (ok) return true;
    }

    // update-token a échoué (ou pas de session)
    // Si le token est déjà enregistré via register-token, on est OK
    if (await _isAlreadyRegistered(fcmToken)) {
      debugPrint(
          '✅ FCM: token déjà enregistré via register-token, notifications actives');
      return true;
    }

    // Fallback : register-token avec le numéro du compte
    debugPrint('⚠️ FCM: fallback vers register-token');
    final phone = await _getPhoneForRegistration();
    if (phone != null && phone.isNotEmpty) {
      return await _callRegisterToken(phone, fcmToken);
    }

    debugPrint('❌ FCM: aucun numéro disponible pour l\'enregistrement');
    return false;
  }

  /// Supprime le token FCM lors du logout (ciblant uniquement cet appareil)
  static Future<bool> clearToken({
    required String sessionToken,
    String? fcmToken,
  }) async {
    try {
      final body = <String, String>{'session_token': sessionToken};
      if (fcmToken != null && fcmToken.isNotEmpty) {
        body['fcm_token'] = fcmToken;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl$_clearEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM: token supprimé');
        // Le token n'est plus enregistré sur le serveur
        if (fcmToken != null) await _clearRegisteredToken();
        return true;
      }
      debugPrint('⚠️ FCM: clear-token ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('⚠️ FCM: clear-token erreur réseau — $e');
      return false;
    }
  }

  /// Écoute les renouvellements de token Firebase et synchronise avec le serveur
  static void listenToTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM: nouveau token — ${newToken.substring(0, 20)}...');
      // Nouveau token Firebase → jamais enregistré, on force la mise à jour
      await _clearRegisteredToken();

      final sessionToken = await UserSession.getSessionToken();
      if (sessionToken != null && sessionToken.isNotEmpty) {
        final ok = await _callUpdateToken(sessionToken, newToken);
        if (ok) return;
      }

      final phone = await _getPhoneForRegistration();
      if (phone != null && phone.isNotEmpty) {
        await _callRegisterToken(phone, newToken);
      }
    });
  }
}
