import 'package:dtservices/config/api_client.dart';
import 'package:dtservices/config/app_config.dart';
// lib/services/logout_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'notification_store.dart';
import 'user_session.dart';
import '../widgets/promo_popup_dialog.dart';

class LogoutService {
  static const String logoutUrl = '${AppConfig.baseUrl}/mobile/logout';

  /// Effectue la déconnexion complète (API + local)
  /// NOTE: Le token FCM n'est PAS supprimé pour permettre les notifications
  /// même après déconnexion
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

      // Le token FCM est conservé volontairement pour continuer à recevoir
      // les notifications même après déconnexion (transferts, cadeaux, etc.)
      // clear-token n'est appelé que si l'user désactive explicitement les notifs.

      // Appeler l'API logout
      final response = await http.post(
        Uri.parse(logoutUrl),
        headers: await ApiClient.authHeaders(),
        body: jsonEncode({
          'session_token': sessionToken,
        }),
      );

      debugPrint('Logout API: ${response.statusCode} - ${response.body}');

      // 3. Nettoyer la session locale dans tous les cas
      await UserSession.clearSession();
      await NotificationStore().switchUser('');
      PromoPopupDialog.resetSession();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('✅ Logout réussi: ${responseData['message']}');
        return true;
      } else {
        debugPrint('⚠️ Logout API failed: ${response.statusCode}');
        // Même en cas d'erreur API, on considère le logout local comme réussi
        return true;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du logout: $e');

      // En cas d'erreur, nettoyer quand même localement
      try {
        await UserSession.clearSession();
      } catch (clearError) {
        debugPrint('❌ Erreur nettoyage session: $clearError');
      }

      // Retourner true pour permettre la navigation même en cas d'erreur
      return true;
    }
  }
}