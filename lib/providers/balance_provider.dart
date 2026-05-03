// lib/providers/balance_provider.dart
import 'package:flutter/material.dart';
import '../firebase/notification_service.dart';
import '../services/balance_service.dart';
import '../services/user_session.dart';

/// Provider pour gérer l'état du solde utilisateur
/// Centralise la logique de chargement et de gestion du solde principal et bonus
class BalanceProvider extends ChangeNotifier {
  // ==================== État privé ====================

  /// Solde principal en DJF
  double _solde = 0.0;

  /// Solde bonus en DJF
  double _bonus = 0.0;

  /// Date d'expiration du solde
  String _dateExpiration = 'N/A';

  /// Indicateur de chargement
  bool _isLoading = false;

  /// Message d'erreur si chargement échoué
  String? _errorMessage;

  /// Données complètes de la balance (pour accès avancé)
  Map<String, dynamic>? _balanceData;

  /// Timestamp du dernier chargement réussi
  DateTime? _lastLoadTime;

  /// Durée de validité du cache (1 minute par défaut)
  final Duration _cacheDuration = const Duration(minutes: 1);

  // ==================== Getters publics ====================

  /// Solde principal en DJF
  double get solde => _solde;

  /// Solde bonus en DJF
  double get bonus => _bonus;

  /// Date d'expiration formatée
  String get dateExpiration => _dateExpiration;

  /// Indicateur de chargement en cours
  bool get isLoading => _isLoading;

  /// Message d'erreur (null si pas d'erreur)
  String? get errorMessage => _errorMessage;

  /// Données complètes de balance (optionnel)
  Map<String, dynamic>? get balanceData => _balanceData;

  /// Vérifie si les données sont en cache et encore valides
  bool get hasCachedData => _lastLoadTime != null &&
      DateTime.now().difference(_lastLoadTime!).inMinutes < _cacheDuration.inMinutes;

  /// Solde total (principal + bonus)
  double get totalBalance => _solde + _bonus;

  // ==================== Actions publiques ====================

  /// Charge le solde depuis l'API
  ///
  /// [forceRefresh] : Force le rechargement même si cache valide
  /// Retourne true si succès, false sinon
  Future<bool> loadBalance({bool forceRefresh = false}) async {
    // Si cache valide et pas de force refresh, utiliser les données en cache
    if (!forceRefresh && hasCachedData) {
      debugPrint('BalanceProvider: Utilisation des données en cache');
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('BalanceProvider: Chargement du solde...');

      // Appel au service pour récupérer le solde
      final data = await BalanceService.getCurrentBalance();

      // Extraction et conversion du solde principal
      if (data['solde'] != null) {
        // La valeur est en centimes, convertir en DJF
        _solde = double.tryParse(data['solde']) != null
            ? double.parse(data['solde']) / 100
            : 0.0;
      } else {
        _solde = 0.0;
      }

      // Extraction de la date d'expiration
      _dateExpiration = data['date_supervision'] ?? 'N/A';

      // Extraction du solde bonus depuis le compte dédié ID 5
      _bonus = 0.0;
      if (data['comptes_dedies'] != null) {
        final comptesDedies = data['comptes_dedies'] as List;
        try {
          final compteBonus = comptesDedies.firstWhere(
            (compte) => compte['id'] == 5,
            orElse: () => null,
          );

          if (compteBonus != null && compteBonus['valeur'] != null) {
            // Convertir depuis centimes vers DJF
            _bonus = double.tryParse(compteBonus['valeur']?.toString() ?? '0') != null
                ? double.parse(compteBonus['valeur'].toString()) / 100
                : 0.0;
          }
        } catch (e) {
          debugPrint('BalanceProvider: Erreur extraction bonus: $e');
          _bonus = 0.0;
        }
      }

      // Stocker les données complètes pour usage avancé
      _balanceData = data;

      // Mettre à jour le timestamp du cache
      _lastLoadTime = DateTime.now();

      debugPrint('BalanceProvider: Solde chargé avec succès - Principal: $_solde DJF, Bonus: $_bonus DJF');

      // Notifier si le solde est faible (fire-and-forget)
      NotificationService().checkAndNotifyLowBalance(_solde);

      _isLoading = false;
      notifyListeners();

      return true;

    } catch (e) {
      debugPrint('BalanceProvider: Erreur lors du chargement du solde: $e');

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  /// Rafraîchit le solde (force le rechargement)
  Future<bool> refreshBalance() async {
    return await loadBalance(forceRefresh: true);
  }

  /// Efface le message d'erreur
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Réinitialise complètement l'état du provider
  /// Utilisé lors de la déconnexion
  void reset() {
    _solde = 0.0;
    _bonus = 0.0;
    _dateExpiration = 'N/A';
    _isLoading = false;
    _errorMessage = null;
    _balanceData = null;
    _lastLoadTime = null;

    debugPrint('BalanceProvider: État réinitialisé');
    notifyListeners();
  }

  /// Met à jour l'activité utilisateur
  /// (Utilisé pour maintenir la session active)
  void updateActivity() {
    UserSession.updateActivity();
  }

  /// Soustrait un montant du solde (pour UI optimiste)
  /// Attention : Ne fait que mettre à jour l'UI, pas le serveur
  void deductBalance(double amount) {
    if (amount <= _solde) {
      _solde -= amount;
      debugPrint('BalanceProvider: Déduction optimiste de $amount DJF - Nouveau solde: $_solde DJF');
      notifyListeners();
    } else {
      debugPrint('BalanceProvider: Impossible de déduire $amount DJF - Solde insuffisant');
    }
  }

  /// Ajoute un montant au solde (pour UI optimiste)
  /// Attention : Ne fait que mettre à jour l'UI, pas le serveur
  void addBalance(double amount) {
    _solde += amount;
    debugPrint('BalanceProvider: Ajout optimiste de $amount DJF - Nouveau solde: $_solde DJF');
    notifyListeners();
  }

  /// Vérifie si le solde est suffisant pour un montant donné
  bool hasSufficientBalance(double amount) {
    return _solde >= amount;
  }

  /// Retourne le solde formaté avec l'unité
  String getFormattedBalance() {
    return '${_solde.toStringAsFixed(0)} DJF';
  }

  /// Retourne le bonus formaté avec l'unité
  String getFormattedBonus() {
    return '${_bonus.toStringAsFixed(0)} DJF';
  }

  /// Retourne le solde total formaté avec l'unité
  String getFormattedTotalBalance() {
    return '${totalBalance.toStringAsFixed(0)} DJF';
  }

  /// Invalide le cache (force le prochain loadBalance à recharger)
  void invalidateCache() {
    _lastLoadTime = null;
    debugPrint('BalanceProvider: Cache invalidé');
  }
}
