// lib/services/user_session.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service pour gérer la session utilisateur
/// La session expire après 5 minutes d'inactivité (persiste entre les fermetures d'app)
class UserSession {
  /// Durée d'inactivité avant expiration de session
  static const Duration _inactivityTimeout = Duration(minutes: 5);
  // Clés pour SharedPreferences
  static const String _phoneNumberKey = 'user_phone_number';
  static const String _lastActivityTimeKey = 'last_activity_time';
  static const String _lastUsedPhoneKey = 'last_used_phone';
  static const String _isAppRunningKey = 'is_app_running';
  static const String _sessionTokenKey = 'session_token';
  static const String _hasPinKey = 'has_pin';

  // Cache pour optimiser les performances
  // Note: _cachedIsAuthenticated sert de cache rapide, la source de vérité est le timestamp persisté
  static String? _cachedPhoneNumber;
  static bool _cachedIsAuthenticated = false;
  static String? _cachedLastUsedPhone;
  static String? _cachedSessionToken;
  static bool? _cachedHasPin;

  /// Enregistre les informations de session après la vérification OTP réussie
  static Future<void> createSession(
    String phoneNumber, {
    String? sessionToken,
    bool hasPin = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Enregistrer l'heure actuelle comme dernière activité
    final now = DateTime.now();
    final activityTimestamp = now.millisecondsSinceEpoch;

    // Enregistrer les données de session
    await prefs.setString(_phoneNumberKey, phoneNumber);
    await prefs.setInt(_lastActivityTimeKey, activityTimestamp);
    await prefs.setBool(_isAppRunningKey, true);
    await prefs.setBool(_hasPinKey, hasPin);

    // Enregistrer le session token si fourni
    if (sessionToken != null) {
      await prefs.setString(_sessionTokenKey, sessionToken);
      _cachedSessionToken = sessionToken;
    }

    // Stocker également comme dernier numéro utilisé
    await prefs.setString(_lastUsedPhoneKey, phoneNumber);

    // Mettre à jour le cache mémoire
    _cachedPhoneNumber = phoneNumber;
    _cachedIsAuthenticated = true;
    _cachedLastUsedPhone = phoneNumber;
    _cachedHasPin = hasPin;

    debugPrint(
      'Session créée - Phone: $phoneNumber, Token: ${sessionToken != null}, Pin configuré: $hasPin',
    );
  }

  /// Vérifie si l'utilisateur a déjà configuré un PIN
  static Future<bool> hasPin() async {
    if (_cachedHasPin != null) return _cachedHasPin!;

    final prefs = await SharedPreferences.getInstance();
    _cachedHasPin = prefs.getBool(_hasPinKey) ?? false;
    return _cachedHasPin!;
  }

  /// Met à jour le flag hasPin (à appeler après configuration du PIN)
  static Future<void> setPinConfigured(bool configured) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasPinKey, configured);
    _cachedHasPin = configured;
    debugPrint('UserSession: PIN configuré mis à jour: $configured');
  }

  /// Met à jour le timestamp de dernière activité
  /// À appeler périodiquement lorsque l'utilisateur interagit avec l'app
  static Future<void> updateActivity() async {
    final isAuth = await isAuthenticated();
    if (!isAuth) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final activityTimestamp = now.millisecondsSinceEpoch;

    await prefs.setInt(_lastActivityTimeKey, activityTimestamp);

    //debugPrint('Activité mise à jour: $now');
  }

  /// Doit être appelé quand l'application passe au premier plan
  static Future<void> appResumed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAppRunningKey, true);

    // Si l'app était en arrière-plan trop longtemps, la session a pu expirer
    // On vérifie si la session est toujours valide
    final isValid = await isAuthenticated();
    if (isValid) {
      // Si la session est valide, mettre à jour l'activité
      updateActivity();
    }

    debugPrint('Application revenue au premier plan');
  }

  /// Doit être appelé quand l'application passe en arrière-plan
  static Future<void> appPaused() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAppRunningKey, false);
    // Enregistrer le moment où l'application est passée en arrière-plan
    final now = DateTime.now();
    await prefs.setInt(_lastActivityTimeKey, now.millisecondsSinceEpoch);

    debugPrint('Application passée en arrière-plan à: $now');
  }

  /// Doit être appelé quand l'application est complètement fermée
  /// Le timestamp de dernière activité est déjà persisté — la session
  /// expirera naturellement si l'inactivité dépasse 5 minutes
  static Future<void> appTerminated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAppRunningKey, false);

    debugPrint('Application terminée');
  }

  /// Vérifie si l'utilisateur est authentifié
  /// La session expire après 5 minutes d'inactivité
  /// Persiste entre les fermetures d'app grâce au timestamp dans SharedPreferences
  static Future<bool> isAuthenticated() async {
    // Cache rapide : si déjà validé en mémoire, pas besoin de lire SharedPreferences
    if (_cachedIsAuthenticated) return true;

    // Cold start : vérifier le timestamp persisté
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt(_lastActivityTimeKey);
    final phoneNumber = prefs.getString(_phoneNumberKey);

    if (lastActivity == null || phoneNumber == null) return false;

    final elapsed = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastActivity),
    );

    if (elapsed <= _inactivityTimeout) {
      // Session encore valide — restaurer le cache mémoire
      _cachedIsAuthenticated = true;
      _cachedPhoneNumber = phoneNumber;
      _cachedSessionToken = prefs.getString(_sessionTokenKey);
      _cachedHasPin = prefs.getBool(_hasPinKey) ?? false;
      return true;
    }

    // Session expirée par inactivité
    debugPrint('Session expirée: inactivité de ${elapsed.inMinutes} min');
    return false;
  }

  /// Récupère le numéro de téléphone de l'utilisateur connecté
  /// Retourne null si l'utilisateur n'est pas authentifié
  static Future<String?> getPhoneNumber() async {
    // Si la session a expiré, on renvoie null (car pas authentifié)
    if (!await isAuthenticated()) {
      return null;
    }

    // Utiliser la valeur en cache si disponible
    if (_cachedPhoneNumber != null) {
      return _cachedPhoneNumber;
    }

    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString(_phoneNumberKey);

    // Mettre à jour le cache
    _cachedPhoneNumber = phoneNumber;

    return phoneNumber;
  }

  /// Récupère le session token de l'utilisateur connecté
  /// Retourne null si l'utilisateur n'est pas authentifié ou si aucun token n'existe
  static Future<String?> getSessionToken() async {
    // Si la session a expiré, on renvoie null
    if (!await isAuthenticated()) {
      return null;
    }

    // Utiliser la valeur en cache si disponible
    if (_cachedSessionToken != null) {
      return _cachedSessionToken;
    }

    final prefs = await SharedPreferences.getInstance();
    final sessionToken = prefs.getString(_sessionTokenKey);

    // Mettre à jour le cache
    _cachedSessionToken = sessionToken;

    return sessionToken;
  }

  /// Récupère le dernier numéro de téléphone utilisé, même si la session a expiré
  /// Utile pour pré-remplir le champ de téléphone lors de la reconnexion
  static Future<String?> getLastUsedPhoneNumber() async {
    // Utiliser la valeur en cache si disponible
    if (_cachedLastUsedPhone != null) {
      return _cachedLastUsedPhone;
    }

    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString(_lastUsedPhoneKey);

    // Mettre à jour le cache
    _cachedLastUsedPhone = phoneNumber;

    return phoneNumber;
  }

  /// Récupère le temps d'inactivité en secondes
  static Future<int> getInactivityTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivityTimestamp = prefs.getInt(_lastActivityTimeKey);

    if (lastActivityTimestamp == null) {
      return 0;
    }

    final lastActivity = DateTime.fromMillisecondsSinceEpoch(
      lastActivityTimestamp,
    );
    final now = DateTime.now();

    return now.difference(lastActivity).inSeconds;
  }

  /// Termine complètement la session utilisateur mais conserve le dernier numéro
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Sauvegarder le numéro actuel dans last_used_phone avant de le supprimer
    final currentPhone = prefs.getString(_phoneNumberKey);
    if (currentPhone != null && currentPhone.isNotEmpty) {
      await prefs.setString(_lastUsedPhoneKey, currentPhone);
    }

    await prefs.remove(_lastActivityTimeKey);
    await prefs.remove(_sessionTokenKey);
    await prefs.remove(_hasPinKey); // IMPORTANT: Supprimer le flag PIN
    await prefs.remove(_isAppRunningKey);
    await prefs.remove(_phoneNumberKey); // Supprimer le numéro actuel
    // Conserver _lastUsedPhoneKey pour pré-remplir le champ de connexion
    // Conserver les préférences utilisateur (_isBiometricEnabledKey, _isPinEnabledKey, _isOtpEnabledKey)
    // Conserver _skipPinSetupKey car c'est une préférence globale du device

    // Réinitialiser le cache
    _cachedPhoneNumber = null;
    _cachedIsAuthenticated = false;
    _cachedSessionToken = null;
    _cachedHasPin = null;

    debugPrint('Session utilisateur terminée - Numéro conservé pour réutilisation');
  }

  /// Supprime toutes les données, y compris le dernier numéro utilisé
  /// À utiliser lors d'une déconnexion explicite par l'utilisateur
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_lastActivityTimeKey);
    await prefs.remove(_lastUsedPhoneKey);
    await prefs.remove(_isAppRunningKey);
    await prefs.remove(_sessionTokenKey);
    await prefs.remove(_hasPinKey);
    await prefs.remove(_skipPinSetupKey);
    // Optionnel: supprimer aussi les préférences
    // await prefs.remove(_isBiometricEnabledKey);
    // await prefs.remove(_isPinEnabledKey);
    // await prefs.remove(_isOtpEnabledKey);

    // Réinitialiser tout le cache
    _cachedPhoneNumber = null;
    _cachedIsAuthenticated = false;
    _cachedLastUsedPhone = null;
    _cachedSessionToken = null;
    _cachedHasPin = null;

    debugPrint('Toutes les données utilisateur supprimées');
  }

  // ==================== Préférences de connexion ====================

  static const String _isBiometricEnabledKey = 'is_biometric_enabled';
  static const String _isOtpEnabledKey = 'is_otp_enabled';

  /// Vérifie si l'authentification biométrique est activée
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isBiometricEnabledKey) ?? false;
  }

  /// Active ou désactive l'authentification biométrique
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isBiometricEnabledKey, enabled);
    debugPrint('Biométrie ${enabled ? "activée" : "désactivée"}');
  }

  /// Vérifie si l'OTP est activé (par défaut true)
  static Future<bool> isOtpEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isOtpEnabledKey) ?? true;
  }

  /// Active ou désactive l'OTP
  static Future<void> setOtpEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isOtpEnabledKey, enabled);
    debugPrint('OTP ${enabled ? "activé" : "désactivé"}');
  }

  static const String _isPinEnabledKey = 'is_pin_enabled';

  /// Vérifie si la connexion par PIN est activée (par défaut true)
  static Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isPinEnabledKey) ?? true;
  }

  /// Active ou désactive la connexion par PIN
  static Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPinEnabledKey, enabled);
    debugPrint('Connexion PIN ${enabled ? "activée" : "désactivée"}');
  }

  // ==================== Gestion du Skip PIN Setup ====================

  static const String _skipPinSetupKey = 'skip_pin_setup';

  /// Vérifie si l'utilisateur a demandé de ne plus afficher la config PIN
  static Future<bool> shouldSkipPinSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_skipPinSetupKey) ?? false;
  }

  /// Enregistre la préférence "Plus tard" pour la config PIN
  static Future<void> setSkipPinSetup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipPinSetupKey, value);
    debugPrint('Skip PIN setup set to: $value');
  }

  // ==================== Stockage sécurisé du PIN pour biométrie ====================

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _securePinPrefix = 'secure_pin_';

  /// Sauvegarde le PIN de manière sécurisée (pour authentification biométrique)
  static Future<void> saveSecurePin(String phoneNumber, String pin) async {
    try {
      final key = '$_securePinPrefix$phoneNumber';
      await _secureStorage.write(key: key, value: pin);
      debugPrint('PIN sauvegardé de manière sécurisée pour $phoneNumber');
    } catch (e) {
      debugPrint('Erreur sauvegarde PIN sécurisé: $e');
    }
  }

  /// Récupère le PIN stocké de manière sécurisée
  static Future<String?> getSecurePin(String phoneNumber) async {
    try {
      final key = '$_securePinPrefix$phoneNumber';
      final pin = await _secureStorage.read(key: key);
      return pin;
    } catch (e) {
      debugPrint('Erreur récupération PIN sécurisé: $e');
      return null;
    }
  }

  /// Supprime le PIN stocké de manière sécurisée
  static Future<void> deleteSecurePin(String phoneNumber) async {
    try {
      final key = '$_securePinPrefix$phoneNumber';
      await _secureStorage.delete(key: key);
      debugPrint('PIN sécurisé supprimé pour $phoneNumber');
    } catch (e) {
      debugPrint('Erreur suppression PIN sécurisé: $e');
    }
  }

  /// Vérifie si un PIN est stocké pour ce numéro
  static Future<bool> hasSecurePin(String phoneNumber) async {
    final pin = await getSecurePin(phoneNumber);
    return pin != null && pin.isNotEmpty;
  }

  // ==================== FCM Token Management ====================

  static const String _fcmPhoneKey = 'fcm_registered_phone';

  /// Enregistre le numéro de téléphone pour les notifications FCM
  /// Ce numéro est conservé même après déconnexion
  static Future<void> setLastUsedPhoneForFCM(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmPhoneKey, phoneNumber);
    debugPrint('FCM: Numéro enregistré pour notifications: $phoneNumber');
  }

  /// Récupère le dernier numéro utilisé pour FCM
  /// Permet de recevoir des notifications même déconnecté
  static Future<String?> getLastUsedPhoneForFCM() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmPhoneKey);
  }
}
