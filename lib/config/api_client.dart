import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/notification_store.dart';
import '../services/user_session.dart';
import '../widgets/promo_popup_dialog.dart';
import 'app_config.dart';

/// Client HTTP centralisé.
/// - Ajoute automatiquement Authorization: Bearer sur les routes protégées.
/// - Intercepte les 401 : efface la session et redirige vers le login.
class ApiClient {
  static const Duration _timeout = Duration(seconds: 30);

  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// NavigatorKey fourni par l'app (branché dans main.dart via NotificationService).
  /// Permet la navigation sans BuildContext.
  static GlobalKey<NavigatorState>? navigatorKey;

  // ─── Headers ──────────────────────────────────────────────────────────────

  static Map<String, String> get publicHeaders => Map.from(_baseHeaders);

  static Future<Map<String, String>> authHeaders() async {
    final token = await UserSession.getSessionToken();
    final headers = Map<String, String>.from(_baseHeaders);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      debugPrint('⚠️ ApiClient: aucun session token disponible');
    }
    return headers;
  }

  // ─── Intercepteur 401 ─────────────────────────────────────────────────────

  /// Vérifie la réponse. Si 401, efface la session et redirige vers le login.
  static Future<http.Response> _check(http.Response response) async {
    if (response.statusCode == 401) {
      debugPrint('🔒 ApiClient: session expirée (401) → redirection login');
      await _handleSessionExpired();
    }
    return response;
  }

  static Future<void> _handleSessionExpired() async {
    await UserSession.clearSession();
    await NotificationStore().switchUser('');
    PromoPopupDialog.resetSession();

    final nav = navigatorKey?.currentState;
    if (nav == null) return;

    // Import inline pour éviter la dépendance circulaire
    nav.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // ─── Méthodes publiques (pas d'auth) ─────────────────────────────────────

  static Future<http.Response> getPublic(String path) {
    return http
        .get(Uri.parse('${AppConfig.baseUrl}$path'), headers: publicHeaders)
        .timeout(_timeout);
  }

  static Future<http.Response> postPublic(
      String path, Map<String, dynamic> body) {
    return http
        .post(
          Uri.parse('${AppConfig.baseUrl}$path'),
          headers: publicHeaders,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  // ─── Méthodes protégées (avec Bearer token + intercepteur 401) ───────────

  static Future<http.Response> get(String path) async {
    final response = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}$path'),
          headers: await authHeaders(),
        )
        .timeout(_timeout);
    return _check(response);
  }

  static Future<http.Response> post(String path,
      [Map<String, dynamic>? body]) async {
    final response = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}$path'),
          headers: await authHeaders(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _check(response);
  }

  static Future<http.Response> put(String path,
      [Map<String, dynamic>? body]) async {
    final response = await http
        .put(
          Uri.parse('${AppConfig.baseUrl}$path'),
          headers: await authHeaders(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _check(response);
  }
}
