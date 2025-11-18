// lib/providers/user_session_provider.dart
import 'package:flutter/material.dart';
import '../services/user_session.dart';
import '../services/otp_service.dart';

/// Provider centralisé pour gérer la session utilisateur
/// Remplace les appels directs à UserSession en offrant une gestion d'état réactive
class UserSessionProvider extends ChangeNotifier {
  // État de la session
  String? _phoneNumber;
  String? _sessionToken;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastActivityTime;

  // Getters pour accéder à l'état
  String? get phoneNumber => _phoneNumber;
  String? get sessionToken => _sessionToken;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastActivityTime => _lastActivityTime;

  /// Initialise le provider en chargeant la session depuis SharedPreferences
  /// À appeler au démarrage de l'application
  Future<void> initSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Vérifier si l'utilisateur est déjà authentifié
      _isAuthenticated = await UserSession.isAuthenticated();

      if (_isAuthenticated) {
        // Charger les données de session
        _phoneNumber = await UserSession.getPhoneNumber();
        _sessionToken = await UserSession.getSessionToken();
        _error = null;

        debugPrint('✅ Session restaurée pour: $_phoneNumber');
      } else {
        // Essayer de récupérer le dernier numéro utilisé pour pré-remplir
        _phoneNumber = await UserSession.getLastUsedPhoneNumber();
        debugPrint('ℹ️ Aucune session active, dernier numéro: $_phoneNumber');
      }
    } catch (e) {
      _error = 'Erreur lors de l\'initialisation de la session: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée une nouvelle session après vérification OTP réussie
  Future<bool> login(String phoneNumber, String otpCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔐 Tentative de connexion pour: $phoneNumber');

      // Vérifier l'OTP via le service
      final result = await OtpService.verifyOtp(phoneNumber, otpCode);

      if (result['success'] == true) {
        final sessionToken = result['data']?['session_token'];

        // Créer la session
        await UserSession.createSession(phoneNumber, sessionToken: sessionToken);

        // Mettre à jour l'état local
        _phoneNumber = phoneNumber;
        _sessionToken = sessionToken;
        _isAuthenticated = true;
        _lastActivityTime = DateTime.now();
        _error = null;

        debugPrint('✅ Connexion réussie avec session token');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Code OTP invalide';
        debugPrint('❌ Échec de la vérification OTP: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erreur lors de la connexion: $e';
      debugPrint('❌ $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Déconnexion de l'utilisateur
  Future<void> logout({bool clearAllData = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (clearAllData) {
        await UserSession.clearAllData();
        _phoneNumber = null;
      } else {
        await UserSession.clearSession();
        // Garder le numéro de téléphone pour faciliter la reconnexion
      }

      _sessionToken = null;
      _isAuthenticated = false;
      _lastActivityTime = null;
      _error = null;

      debugPrint('👋 Déconnexion réussie');
    } catch (e) {
      _error = 'Erreur lors de la déconnexion: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour l'activité utilisateur (à appeler périodiquement)
  Future<void> updateActivity() async {
    if (!_isAuthenticated) return;

    try {
      await UserSession.updateActivity();
      _lastActivityTime = DateTime.now();
      // Pas besoin de notifyListeners() pour cette mise à jour mineure
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la mise à jour de l\'activité: $e');
    }
  }

  /// Gère le retour au premier plan de l'application
  Future<void> handleAppResumed() async {
    try {
      await UserSession.appResumed();

      // Re-vérifier l'authentification (la session a peut-être expiré)
      final stillAuthenticated = await UserSession.isAuthenticated();

      if (_isAuthenticated && !stillAuthenticated) {
        // La session a expiré pendant que l'app était en arrière-plan
        debugPrint('⏰ Session expirée après inactivité');
        _isAuthenticated = false;
        _sessionToken = null;
        _error = 'Session expirée après 10 minutes d\'inactivité';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors du retour au premier plan: $e');
    }
  }

  /// Gère le passage en arrière-plan de l'application
  Future<void> handleAppPaused() async {
    try {
      await UserSession.appPaused();
      debugPrint('⏸️ Application en arrière-plan');
    } catch (e) {
      debugPrint('⚠️ Erreur lors du passage en arrière-plan: $e');
    }
  }

  /// Gère la fermeture de l'application
  Future<void> handleAppTerminated() async {
    try {
      await UserSession.appTerminated();
      debugPrint('🛑 Application terminée');
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la fermeture: $e');
    }
  }

  /// Efface l'erreur actuelle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Récupère le temps d'inactivité en secondes
  Future<int> getInactivityTime() async {
    return await UserSession.getInactivityTime();
  }
}
