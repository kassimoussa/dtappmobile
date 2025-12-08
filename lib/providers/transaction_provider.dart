// lib/providers/transaction_provider.dart
import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';

/// Provider pour gérer l'historique des transactions
class TransactionProvider extends ChangeNotifier {
  // Liste des transactions
  List<Activity> _activities = [];

  // Pagination
  ActivityPagination? _pagination;
  ActivityFilters? _filters;
  int _currentPage = 1;
  final int _perPage = 20;

  // Filtres
  int _selectedDays = 30;

  // État UI
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Cache
  DateTime? _lastLoadTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 2);

  // Getters
  List<Activity> get activities => _activities;
  ActivityPagination? get pagination => _pagination;
  ActivityFilters? get filters => _filters;
  int get selectedDays => _selectedDays;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _pagination != null && _currentPage < _pagination!.totalPages;

  /// Vérifie si le cache est encore valide
  bool get hasCachedData =>
      _lastLoadTime != null &&
      DateTime.now().difference(_lastLoadTime!).inMinutes < _cacheValidityDuration.inMinutes &&
      _activities.isNotEmpty;

  /// Charge l'historique des transactions
  Future<void> loadHistory({bool forceRefresh = false}) async {
    // Utiliser le cache si valide et pas de force refresh
    if (!forceRefresh && hasCachedData) {
      debugPrint('TransactionProvider: Utilisation du cache');
      return;
    }

    debugPrint('TransactionProvider: Chargement historique page=$_currentPage, days=$_selectedDays');

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final response = await ActivityService.getHistory(
        page: _currentPage,
        perPage: _perPage,
        days: _selectedDays,
      );

      if (response != null) {
        _activities = response.data;
        _pagination = response.pagination;
        _filters = response.filters;
        _lastLoadTime = DateTime.now();
        _isLoading = false;
        _errorMessage = null;

        debugPrint('TransactionProvider: ${_activities.length} transactions chargées');
        notifyListeners();
      } else {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement de l\'historique';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('TransactionProvider: Erreur - $e');
      _isLoading = false;
      _errorMessage = 'Erreur lors du chargement de l\'historique';
      notifyListeners();
    }
  }

  /// Charge plus de transactions (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMorePages) {
      return;
    }

    debugPrint('TransactionProvider: Chargement page ${_currentPage + 1}');

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;

      final response = await ActivityService.getHistory(
        page: _currentPage,
        perPage: _perPage,
        days: _selectedDays,
      );

      if (response != null) {
        _activities.addAll(response.data);
        _pagination = response.pagination;
        _filters = response.filters;
        _isLoadingMore = false;

        debugPrint('TransactionProvider: ${response.data.length} transactions ajoutées');
        notifyListeners();
      } else {
        _currentPage--; // Revenir en arrière si échec
        _isLoadingMore = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('TransactionProvider: Erreur loadMore - $e');
      _currentPage--; // Revenir en arrière si échec
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Change le filtre de période (7, 15, 30, 60, 90 jours)
  Future<void> changeDaysFilter(int days) async {
    if (_selectedDays == days) return;

    debugPrint('TransactionProvider: Changement filtre de $_selectedDays à $days jours');

    _selectedDays = days;
    _currentPage = 1;
    _activities.clear();
    await loadHistory(forceRefresh: true);
  }

  /// Rafraîchit l'historique (force refresh)
  Future<void> refresh() async {
    debugPrint('TransactionProvider: Rafraîchissement forcé');
    _currentPage = 1;
    await loadHistory(forceRefresh: true);
  }

  /// Réinitialise le provider
  void reset() {
    debugPrint('TransactionProvider: Reset complet');

    _activities.clear();
    _pagination = null;
    _filters = null;
    _currentPage = 1;
    _selectedDays = 30;
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _lastLoadTime = null;

    notifyListeners();
  }

  /// Efface le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Invalide le cache
  void invalidateCache() {
    _lastLoadTime = null;
    debugPrint('TransactionProvider: Cache invalidé');
  }

  /// Getters utilitaires

  /// Nombre total de transactions
  int get totalTransactions => _pagination?.total ?? 0;

  /// Nombre de transactions actuellement chargées
  int get loadedTransactions => _activities.length;

  /// Vérifie si des transactions sont chargées
  bool get hasTransactions => _activities.isNotEmpty;

  /// Vérifie si la liste est vide après chargement
  bool get isEmpty => !_isLoading && _activities.isEmpty;

  /// Filtre les transactions par type
  List<Activity> getByType(String type) {
    return _activities.where((a) => a.actionType == type).toList();
  }

  /// Filtre les transactions par statut
  List<Activity> getByStatus(String status) {
    return _activities.where((a) => a.status == status).toList();
  }

  /// Obtient les transactions réussies
  List<Activity> get successfulTransactions {
    return _activities.where((a) => a.status == 'success' || a.status == 'completed').toList();
  }

  /// Obtient les transactions échouées
  List<Activity> get failedTransactions {
    return _activities.where((a) => a.status == 'failed' || a.status == 'error').toList();
  }

  /// Calcule le total des montants pour une période
  double getTotalAmount() {
    return _activities
        .where((a) => a.amount != null && (a.status == 'success' || a.status == 'completed'))
        .fold(0.0, (sum, activity) => sum + (activity.amount ?? 0.0));
  }
}
