// lib/providers/balance_provider.dart
import 'package:flutter/material.dart';
import '../services/balance_service.dart';

/// Provider centralisé pour gérer le solde utilisateur
/// Offre un cache intelligent et une synchronisation automatique
class BalanceProvider extends ChangeNotifier {
  // État du solde
  Map<String, dynamic>? _balanceData;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetch;

  // Durée de validité du cache (10 minutes)
  static const Duration _cacheDuration = Duration(minutes: 10);

  // Getters
  Map<String, dynamic>? get balanceData => _balanceData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetch => _lastFetch;
  bool get hasData => _balanceData != null;

  /// Récupère le solde principal formaté
  String get mainBalance {
    if (_balanceData == null) return '--';

    try {
      final balance = _balanceData!['solde_principal'];
      return balance?.toString() ?? '--';
    } catch (e) {
      return '--';
    }
  }

  /// Récupère la devise
  String get currency {
    if (_balanceData == null) return 'DJF';
    return _balanceData!['devise'] ?? 'DJF';
  }

  /// Récupère le solde formaté avec devise
  String get formattedBalance {
    if (_balanceData == null) return '-- DJF';
    return '$mainBalance $currency';
  }

  /// Vérifie si le cache est encore valide
  bool get isCacheValid {
    if (_lastFetch == null) return false;
    final now = DateTime.now();
    return now.difference(_lastFetch!) < _cacheDuration;
  }

  /// Charge le solde depuis l'API
  /// Si useCache = true et que le cache est valide, ne fait pas d'appel API
  Future<void> fetchBalance({bool forceRefresh = false}) async {
    // Si le cache est valide et qu'on ne force pas le refresh, ne rien faire
    if (!forceRefresh && isCacheValid) {
      debugPrint('💰 Utilisation du cache pour le solde (valide pendant ${_cacheDuration.inMinutes - DateTime.now().difference(_lastFetch!).inMinutes} min)');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('💰 Récupération du solde depuis l\'API...');

      final data = await BalanceService.getCurrentBalance();

      _balanceData = data;
      _lastFetch = DateTime.now();
      _error = null;

      debugPrint('✅ Solde récupéré: ${formattedBalance}');
    } catch (e) {
      _error = 'Erreur lors de la récupération du solde: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rafraîchit le solde (force un nouvel appel API)
  Future<void> refresh() async {
    return fetchBalance(forceRefresh: true);
  }

  /// Invalide le cache et efface le solde
  /// Utile après un achat de forfait ou un transfert de crédit
  void invalidateCache() {
    _balanceData = null;
    _lastFetch = null;
    _error = null;
    debugPrint('🔄 Cache du solde invalidé');
    notifyListeners();
  }

  /// Efface toutes les données du solde
  void clear() {
    _balanceData = null;
    _lastFetch = null;
    _error = null;
    _isLoading = false;
    debugPrint('🗑️ Données de solde effacées');
    notifyListeners();
  }

  /// Efface l'erreur actuelle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Récupère des informations supplémentaires du solde
  String? getBalanceInfo(String key) {
    if (_balanceData == null) return null;
    return _balanceData![key]?.toString();
  }
}
