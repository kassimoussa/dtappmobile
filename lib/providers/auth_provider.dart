// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/user_session.dart';
import '../services/otp_service.dart';
import '../services/logout_service.dart';
import '../services/fcm_token_service.dart';
import '../services/pin_service.dart';

/// Provider pour gérer l'état d'authentification et la session utilisateur
/// Centralise toute la logique d'auth (login, logout, session management)
class AuthProvider extends ChangeNotifier {
  // ==================== État privé ====================

  /// Numéro de téléphone de l'utilisateur connecté
  String? _phoneNumber;

  /// Token de session reçu après authentification
  String? _sessionToken;

  /// Indique si l'utilisateur est authentifié
  bool _isAuthenticated = false;

  /// Timestamp de la dernière activité utilisateur
  DateTime? _lastActivityTime;

  /// Indique si une opération d'auth est en cours
  bool _isLoading = false;

  /// Message d'erreur lors des opérations d'auth
  String? _errorMessage;

  /// Code d'erreur spécifique (pour PIN)
  String? _errorCode;

  /// Tentatives restantes (pour PIN incorrect)
  int? _remainingAttempts;

  /// Timestamp de verrouillage (pour compte verrouillé)
  String? _lockedUntil;

  /// Secondes restantes avant déverrouillage
  int? _remainingSeconds;

  /// Erreurs de validation (pour formulaires PIN)
  Map<String, dynamic>? _validationErrors;

  /// Indique si l'utilisateur a un PIN configuré
  bool _hasPin = false;

  /// Service OTP
  final _otpService = OtpService();

  /// Timestamp de création de session
  DateTime? _sessionCreatedAt;

  /// Durée d'inactivité tolérée (10 minutes)
  static const Duration _inactivityTimeout = Duration(minutes: 10);

  // ==================== Getters publics ====================

  /// Numéro de téléphone de l'utilisateur
  String? get phoneNumber => _phoneNumber;

  /// Token de session
  String? get sessionToken => _sessionToken;

  /// Statut d'authentification
  bool get isAuthenticated => _isAuthenticated;

  /// Si l'utilisateur a un PIN configuré
  bool get hasPin => _hasPin;

  /// Dernière activité
  DateTime? get lastActivityTime => _lastActivityTime;
  // ... (skip lines)

  /// Charge la session existante depuis SharedPreferences
  Future<void> _loadExistingSession() async {
    try {
      final isAuth = await UserSession.isAuthenticated();

      if (isAuth) {
        _phoneNumber = await UserSession.getPhoneNumber();
        _sessionToken = await UserSession.getSessionToken();
        _hasPin = await UserSession.hasPin(); // Charger l'état du PIN
        _isAuthenticated = true;
        _lastActivityTime = DateTime.now();

        debugPrint(
          'AuthProvider: Session existante chargée pour $_phoneNumber (PIN: $_hasPin)',
        );
        notifyListeners();
      } else {
        debugPrint('AuthProvider: Aucune session active');
      }
    } catch (e) {
      debugPrint('AuthProvider: Erreur chargement session: $e');
    }
  }

  // ... (skip lines)

  /// Vérifie le code OTP et crée la session
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Vérification OTP pour $phoneNumber');

      final result = await _otpService.verifyOtp(phoneNumber, otp);

      if (result['status'] == 'success') {
        // Extraire le session token et l'état du PIN
        final data = result['data'] ?? {};
        final sessionToken = data['session_token'];
        // Vérifier plusieurs clés possibles pour la compatibilité API
        // Vérifier plusieurs clés possibles pour la compatibilité API et gérer les types (bool, string, int)
        dynamic rawHasPin = data['has_pin'] ?? data['is_pin_set'];
        bool hasPin = false;

        if (rawHasPin is bool) {
          hasPin = rawHasPin;
        } else if (rawHasPin is String) {
          hasPin = rawHasPin.toLowerCase() == 'true' || rawHasPin == '1';
        } else if (rawHasPin is int) {
          hasPin = rawHasPin == 1;
        }

        // Créer la session
        await _createSession(phoneNumber, sessionToken, hasPin: hasPin);

        // Envoyer le token FCM
        try {
          await FCMTokenService.updateTokenOnServer();
          debugPrint('AuthProvider: Token FCM envoyé au serveur');
        } catch (fcmError) {
          debugPrint('AuthProvider: Erreur FCM (non bloquant): $fcmError');
        }

        debugPrint('AuthProvider: ✅ Authentification réussie (PIN: $hasPin)');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Code OTP incorrect';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider: Erreur vérification OTP: $e');
      _errorMessage = 'Une erreur est survenue lors de la vérification';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Vérifie l'OTP pour la réinitialisation du PIN (sans créer de session)
  Future<bool> verifyOtpForReset(String phoneNumber, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Vérification OTP (Reset) pour $phoneNumber');

      final result = await _otpService.verifyOtp(phoneNumber, otp);

      if (result['status'] == 'success') {
        debugPrint('AuthProvider: ✅ OTP vérifié avec succès (Reset)');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Code OTP incorrect';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider: Erreur vérification OTP (Reset): $e');
      _errorMessage = 'Une erreur est survenue lors de la vérification';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Crée une session après vérification OTP réussie
  Future<void> _createSession(
    String phoneNumber,
    String? sessionToken, {
    bool hasPin = false,
  }) async {
    // Sauvegarder dans UserSession (pour persistence)
    await UserSession.createSession(
      phoneNumber,
      sessionToken: sessionToken,
      hasPin: hasPin,
    );

    // Mettre à jour l'état du provider
    _phoneNumber = phoneNumber;
    _sessionToken = sessionToken;
    _hasPin = hasPin;
    _isAuthenticated = true;
    _lastActivityTime = DateTime.now();
    _sessionCreatedAt = DateTime.now();

    debugPrint(
      'AuthProvider: Session créée - Phone: $phoneNumber, Token: ${sessionToken?.substring(0, 10)}..., PIN: $hasPin',
    );
  }

  /// Indicateur de chargement
  bool get isLoading => _isLoading;

  /// Message d'erreur
  String? get errorMessage => _errorMessage;

  /// Code d'erreur spécifique
  String? get errorCode => _errorCode;

  /// Tentatives restantes (pour erreurs PIN)
  int? get remainingAttempts => _remainingAttempts;

  /// Timestamp de verrouillage
  String? get lockedUntil => _lockedUntil;

  /// Secondes restantes avant déverrouillage
  int? get remainingSeconds => _remainingSeconds;

  /// Erreurs de validation
  Map<String, dynamic>? get validationErrors => _validationErrors;

  /// Date de création de session
  DateTime? get sessionCreatedAt => _sessionCreatedAt;

  /// Numéro formaté pour l'affichage (+253 XX XX XX XX)
  String? get formattedPhoneNumber {
    if (_phoneNumber == null) return null;

    String cleanNumber = _phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '');

    // Enlever l'indicatif 253 s'il est présent
    if (cleanNumber.startsWith('253')) {
      cleanNumber = cleanNumber.substring(3);
    }

    // S'assurer qu'on a bien 8 chiffres
    if (cleanNumber.length == 8) {
      final buffer = StringBuffer('+253');
      for (int i = 0; i < cleanNumber.length; i += 2) {
        buffer.write(' ${cleanNumber.substring(i, i + 2)}');
      }
      return buffer.toString();
    }

    return '+253 $cleanNumber';
  }

  /// Temps écoulé depuis la dernière activité
  Duration? get inactivityDuration {
    if (_lastActivityTime == null) return null;
    return DateTime.now().difference(_lastActivityTime!);
  }

  /// Vérifie si la session a expiré par inactivité
  bool get isSessionExpired {
    if (!_isAuthenticated || _lastActivityTime == null) return true;
    return inactivityDuration! > _inactivityTimeout;
  }

  // ==================== Initialisation ====================

  /// Constructeur - Charge la session existante si disponible
  AuthProvider() {
    _loadExistingSession();
  }

  // ==================== Opérations d'authentification ====================

  /// Envoie un code OTP au numéro de téléphone
  Future<bool> sendOtp(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Envoi OTP à $phoneNumber');

      final result = await _otpService.sendOtp(phoneNumber);

      if (result['status'] == 'success') {
        debugPrint('AuthProvider: OTP envoyé avec succès');

        // Enregistrer le token FCM pour ce numéro (permet les notifications hors connexion)
        FCMTokenService.registerTokenWithPhone(phoneNumber).then((success) {
          if (success) {
            debugPrint('✅ Token FCM enregistré pour $phoneNumber');
          }
        });

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de l\'envoi du code';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider: Erreur envoi OTP: $e');
      _errorMessage = 'Une erreur est survenue. Veuillez réessayer.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== Authentification PIN ====================

  /// Connexion avec code PIN (alternative à l'OTP)
  ///
  /// Retourne true si la connexion réussit, false sinon
  /// Les erreurs spécifiques sont accessibles via errorMessage et errorCode
  Future<bool> loginWithPin(String phoneNumber, String pin) async {
    _isLoading = true;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Connexion PIN pour $phoneNumber');

      final result = await PinService.loginWithPin(
        phoneNumber: phoneNumber,
        pin: pin,
      );

      if (result['status'] == 'success') {
        // Extraire les données de la réponse
        final data = result['data'];
        final sessionToken = data?['session_token'];

        // Créer la session avec hasPin = true (puisque connexion via PIN)
        await _createSession(phoneNumber, sessionToken, hasPin: true);

        // Envoyer le token FCM
        try {
          await FCMTokenService.updateTokenOnServer();
          debugPrint('AuthProvider: Token FCM envoyé au serveur');
        } catch (fcmError) {
          debugPrint('AuthProvider: Erreur FCM (non bloquant): $fcmError');
        }

        debugPrint('AuthProvider: ✅ Connexion PIN réussie');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Gérer les différentes erreurs
        _errorMessage = result['message'];
        _errorCode = result['error_code'];

        // Données additionnelles selon le type d'erreur
        if (result['error_code'] == 'invalid_pin') {
          _remainingAttempts = result['data']?['remaining_attempts'];
        } else if (result['error_code'] == 'account_locked') {
          _lockedUntil = result['data']?['locked_until'];
          _remainingSeconds = result['data']?['remaining_seconds'];
        }

        debugPrint(
          'AuthProvider: ❌ Erreur connexion PIN: ${result['error_code']}',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider: Erreur connexion PIN: $e');
      _errorMessage = 'Une erreur est survenue lors de la connexion';
      _errorCode = 'exception';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Configure le PIN pour la première fois
  ///
  /// Nécessite une session active (après connexion OTP)
  /// Retourne true si la configuration réussit
  Future<bool> setPin(String pin, String pinConfirmation) async {
    if (_sessionToken == null) {
      _errorMessage = 'Aucune session active';
      _errorCode = 'no_session';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Configuration du PIN');

      final result = await PinService.setPin(
        sessionToken: _sessionToken!,
        pin: pin,
        pinConfirmation: pinConfirmation,
      );

      if (result['status'] == 'success') {
        // Mettre à jour le flag hasPin après configuration réussie
        _hasPin = true;
        await UserSession.setPinConfigured(true);

        debugPrint('AuthProvider: ✅ PIN configuré avec succès');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _errorCode = result['error_code'];
        _validationErrors = result['errors'];

        debugPrint(
          'AuthProvider: ❌ Erreur configuration PIN: ${result['error_code']}',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider: Erreur configuration PIN: $e');
      _errorMessage = 'Une erreur est survenue';
      _errorCode = 'exception';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Modifie le PIN existant
  ///
  /// Nécessite une session active et l'ancien PIN
  /// Retourne true si la modification réussit
  Future<bool> changePin(
    String oldPin,
    String newPin,
    String newPinConfirmation,
  ) async {
    if (_sessionToken == null) {
      _errorMessage = 'Aucune session active';
      _errorCode = 'no_session';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Modification du PIN');

      final result = await PinService.changePin(
        sessionToken: _sessionToken!,
        oldPin: oldPin,
        newPin: newPin,
        newPinConfirmation: newPinConfirmation,
      );

      if (result['status'] == 'success') {
        debugPrint('AuthProvider: ✅ PIN modifié avec succès');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _errorCode = result['error_code'];
        _validationErrors = result['errors'];

        debugPrint(
          'AuthProvider: ❌ Erreur modification PIN: ${result['error_code']}',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider: Erreur modification PIN: $e');
      _errorMessage = 'Une erreur est survenue';
      _errorCode = 'exception';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Réinitialise le PIN via OTP
  ///
  /// Efface automatiquement le verrouillage du compte
  /// Nécessite un code OTP valide
  Future<bool> resetPin(
    String phoneNumber,
    String newPin,
    String newPinConfirmation,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Réinitialisation du PIN');

      final result = await PinService.resetPin(
        phoneNumber: phoneNumber,
        newPin: newPin,
        newPinConfirmation: newPinConfirmation,
      );

      if (result['status'] == 'success') {
        debugPrint('AuthProvider: ✅ PIN réinitialisé avec succès');
        _isLoading = false;

        // Reset les compteurs d'erreur
        _remainingAttempts = null;
        _lockedUntil = null;
        _remainingSeconds = null;

        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _errorCode = result['error_code'];
        _validationErrors = result['errors'];

        debugPrint(
          'AuthProvider: ❌ Erreur réinitialisation PIN: ${result['error_code']}',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider: Erreur réinitialisation PIN: $e');
      _errorMessage = 'Une erreur est survenue';
      _errorCode = 'exception';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Déconnexion complète
  Future<bool> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Déconnexion en cours...');

      // Appeler le service de logout (API + FCM)
      final success = await LogoutService.logout();

      if (success) {
        // Nettoyer l'état local
        _phoneNumber = null;
        _sessionToken = null;
        _isAuthenticated = false;
        _lastActivityTime = null;
        _sessionCreatedAt = null;
        _errorMessage = null;

        debugPrint('AuthProvider: ✅ Déconnexion réussie');
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('AuthProvider: Erreur déconnexion: $e');

      // Nettoyer quand même localement en cas d'erreur
      _phoneNumber = null;
      _sessionToken = null;
      _isAuthenticated = false;
      _lastActivityTime = null;
      _sessionCreatedAt = null;

      _isLoading = false;
      notifyListeners();
      return true; // Retourner true pour permettre la navigation
    }
  }

  // ==================== Gestion de session ====================

  /// Met à jour le timestamp d'activité
  void updateActivity() {
    if (!_isAuthenticated) return;

    _lastActivityTime = DateTime.now();
    UserSession.updateActivity();

    // Pas de notifyListeners() car pas d'impact UI direct
  }

  /// Vérifie la validité de la session
  Future<bool> checkSession() async {
    try {
      final isAuth = await UserSession.isAuthenticated();

      if (!isAuth && _isAuthenticated) {
        // Session expirée côté UserSession mais pas côté provider
        debugPrint('AuthProvider: Session expirée détectée');
        await _clearSession();
        return false;
      }

      return isAuth;
    } catch (e) {
      debugPrint('AuthProvider: Erreur vérification session: $e');
      return false;
    }
  }

  /// Nettoie la session locale (sans appel API)
  Future<void> _clearSession() async {
    _phoneNumber = null;
    _sessionToken = null;
    _isAuthenticated = false;
    _lastActivityTime = null;
    _sessionCreatedAt = null;

    await UserSession.clearSession();
    notifyListeners();
  }

  /// Appelé quand l'app revient au premier plan
  Future<void> appResumed() async {
    await UserSession.appResumed();

    // Vérifier si la session est toujours valide
    final isValid = await checkSession();

    if (!isValid && _isAuthenticated) {
      debugPrint('AuthProvider: Session expirée après retour au premier plan');
      await _clearSession();
    } else if (isValid) {
      _lastActivityTime = DateTime.now();
      notifyListeners();
    }
  }

  /// Appelé quand l'app passe en arrière-plan
  Future<void> appPaused() async {
    await UserSession.appPaused();
  }

  /// Appelé quand l'app est terminée
  Future<void> appTerminated() async {
    await UserSession.appTerminated();
  }

  // ==================== Utilitaires ====================

  /// Efface le message d'erreur
  void clearError() {
    if (_errorMessage != null || _errorCode != null) {
      _errorMessage = null;
      _errorCode = null;
      _remainingAttempts = null;
      _lockedUntil = null;
      _remainingSeconds = null;
      _validationErrors = null;
      notifyListeners();
    }
  }

  /// Réinitialise complètement le provider
  void reset() {
    _phoneNumber = null;
    _sessionToken = null;
    _isAuthenticated = false;
    _lastActivityTime = null;
    _sessionCreatedAt = null;
    _isLoading = false;
    _errorMessage = null;
    _errorCode = null;
    _remainingAttempts = null;
    _lockedUntil = null;
    _remainingSeconds = null;
    _validationErrors = null;

    debugPrint('AuthProvider: État réinitialisé');
    notifyListeners();
  }

  /// Durée de la session active
  Duration? get sessionDuration {
    if (_sessionCreatedAt == null) return null;
    return DateTime.now().difference(_sessionCreatedAt!);
  }

  /// Temps restant avant expiration (si inactif)
  Duration? get timeUntilExpiration {
    if (_lastActivityTime == null) return null;

    final elapsed = DateTime.now().difference(_lastActivityTime!);
    final remaining = _inactivityTimeout - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Vérifie si le numéro est valide (format Djibouti)
  static bool isValidPhoneNumber(String phoneNumber) {
    // Nettoyer le numéro
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Enlever l'indicatif 253 s'il est présent
    if (cleanNumber.startsWith('253')) {
      cleanNumber = cleanNumber.substring(3);
    }

    // Vérifier le format : 8 chiffres commençant par 77, 78, 70, 75, 76, ou 33
    if (cleanNumber.length != 8) return false;

    final validPrefixes = ['77', '78', '70', '75', '76', '33'];
    final prefix = cleanNumber.substring(0, 2);

    return validPrefixes.contains(prefix);
  }
}
