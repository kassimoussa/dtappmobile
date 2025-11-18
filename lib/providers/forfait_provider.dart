// lib/providers/forfait_provider.dart
import 'package:flutter/material.dart';
import '../models/forfait_actif2.dart';
import '../services/forfait_actif_service.dart';

/// Provider centralisé pour gérer les forfaits actifs
/// Offre un cache et une synchronisation automatique
class ForfaitProvider extends ChangeNotifier {
  // État des forfaits
  List<ForfaitActif2> _forfaitsActifs = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetch;

  // Durée de validité du cache (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Getters
  List<ForfaitActif2> get forfaitsActifs => _forfaitsActifs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetch => _lastFetch;
  bool get hasData => _forfaitsActifs.isNotEmpty;
  int get count => _forfaitsActifs.length;

  /// Vérifie si le cache est encore valide
  bool get isCacheValid {
    if (_lastFetch == null) return false;
    final now = DateTime.now();
    return now.difference(_lastFetch!) < _cacheDuration;
  }

  /// Récupère les forfaits actifs depuis l'API
  /// Si useCache = true et que le cache est valide, ne fait pas d'appel API
  Future<void> fetchForfaits({bool forceRefresh = false}) async {
    // Si le cache est valide et qu'on ne force pas le refresh, ne rien faire
    if (!forceRefresh && isCacheValid) {
      debugPrint('📦 Utilisation du cache pour les forfaits (valide pendant ${_cacheDuration.inMinutes - DateTime.now().difference(_lastFetch!).inMinutes} min)');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('📦 Récupération des forfaits depuis l\'API...');

      final forfaits = await ForfaitActifService.getForfaitsActifs(useCache: false);

      _forfaitsActifs = forfaits;
      _lastFetch = DateTime.now();
      _error = null;

      debugPrint('✅ ${forfaits.length} forfait(s) récupéré(s)');
    } catch (e) {
      _error = 'Erreur lors de la récupération des forfaits: $e';
      debugPrint('❌ $_error');
      _forfaitsActifs = []; // Liste vide en cas d'erreur
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rafraîchit les forfaits (force un nouvel appel API)
  Future<void> refresh() async {
    return fetchForfaits(forceRefresh: true);
  }

  /// Récupère un forfait spécifique par son ID
  ForfaitActif2? getForfaitById(int id) {
    try {
      return _forfaitsActifs.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Récupère les forfaits par type
  List<ForfaitActif2> getForfaitsByType(String type) {
    return _forfaitsActifs.where((f) => f.typeForfait == type).toList();
  }

  /// Récupère les forfaits par statut
  List<ForfaitActif2> getForfaitsByStatus(String status) {
    return _forfaitsActifs.where((f) => f.statut == status).toList();
  }

  /// Récupère les forfaits actifs uniquement
  List<ForfaitActif2> getActiveForfaits() {
    return _forfaitsActifs.where((f) => f.statut?.toLowerCase() == 'actif').toList();
  }

  /// Récupère les forfaits avec données
  List<ForfaitActif2> getDataForfaits() {
    return _forfaitsActifs.where((f) =>
      f.compteurs?.any((c) => c.type?.toLowerCase().contains('data') ?? false) ?? false
    ).toList();
  }

  /// Récupère les forfaits avec minutes
  List<ForfaitActif2> getVoiceForfaits() {
    return _forfaitsActifs.where((f) =>
      f.compteurs?.any((c) => c.type?.toLowerCase().contains('voice') ?? false) ?? false
    ).toList();
  }

  /// Récupère les forfaits avec SMS
  List<ForfaitActif2> getSmsForfaits() {
    return _forfaitsActifs.where((f) =>
      f.compteurs?.any((c) => c.type?.toLowerCase().contains('sms') ?? false) ?? false
    ).toList();
  }

  /// Invalide le cache
  /// Utile après un achat de forfait
  void invalidateCache() {
    _lastFetch = null;
    debugPrint('🔄 Cache des forfaits invalidé');
    notifyListeners();
  }

  /// Efface toutes les données
  void clear() {
    _forfaitsActifs = [];
    _lastFetch = null;
    _error = null;
    _isLoading = false;
    debugPrint('🗑️ Données de forfaits effacées');
    notifyListeners();
  }

  /// Efface l'erreur actuelle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Charge un forfait spécifique par ID depuis l'API
  Future<ForfaitActif2?> fetchForfaitById(int id) async {
    try {
      debugPrint('📦 Récupération du forfait $id depuis l\'API...');
      final forfait = await ForfaitActifService.getForfaitById(id);

      if (forfait != null) {
        // Mettre à jour dans la liste si déjà présent
        final index = _forfaitsActifs.indexWhere((f) => f.id == id);
        if (index != -1) {
          _forfaitsActifs[index] = forfait;
          notifyListeners();
        }
      }

      return forfait;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du forfait $id: $e');
      return null;
    }
  }
}
