// lib/providers/topup_provider.dart
import 'package:flutter/foundation.dart';
import '../models/topup_balance.dart';
import '../services/topup_api_service.dart';
import '../services/topup_session.dart';
import '../services/user_session.dart';
import '../exceptions/topup_exception.dart';

/// Provider pour gérer l'état de la session TopUp (recharge fixe)
class TopUpProvider extends ChangeNotifier {
  // État de la session
  String? _mobileNumber;
  String? _fixedNumber;
  bool _hasActiveSession = false;

  // Données de balance
  TopUpBalanceResponse? _balanceResponse;

  // Statut du numéro
  Map<String, dynamic>? _numberStatus;
  bool _isNumberSuspended = false;

  // État UI
  bool _isLoading = false;
  String? _errorMessage;

  // Cache timestamp
  DateTime? _lastBalanceLoadTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 1);

  // Getters
  String? get mobileNumber => _mobileNumber;
  String? get fixedNumber => _fixedNumber;
  bool get hasActiveSession => _hasActiveSession;
  TopUpBalanceResponse? get balanceResponse => _balanceResponse;
  Map<String, dynamic>? get numberStatus => _numberStatus;
  bool get isNumberSuspended => _isNumberSuspended;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Vérifie si le cache est encore valide
  bool get hasCachedData =>
      _lastBalanceLoadTime != null &&
      DateTime.now().difference(_lastBalanceLoadTime!).inMinutes < _cacheValidityDuration.inMinutes;

  /// Initialise le provider en chargeant les données de session
  Future<void> initialize() async {
    debugPrint('TopUpProvider: Initialisation...');

    // Charger le numéro mobile de l'utilisateur
    _mobileNumber = await UserSession.getPhoneNumber();

    // Vérifier s'il y a une session TopUp active
    _hasActiveSession = await TopUpSession.hasActiveSession();

    if (_hasActiveSession) {
      // Récupérer les données de session
      final sessionData = await TopUpSession.getSessionData();
      _fixedNumber = sessionData['fixed'];

      debugPrint('TopUpProvider: Session active trouvée - $_mobileNumber -> $_fixedNumber');

      // Charger automatiquement les soldes
      if (_fixedNumber != null && _mobileNumber != null) {
        await loadBalances();
      }
    } else {
      debugPrint('TopUpProvider: Aucune session active');
    }

    notifyListeners();
  }

  /// Démarre une nouvelle session TopUp
  Future<bool> startSession(String fixedNumber) async {
    debugPrint('TopUpProvider: Démarrage session pour $fixedNumber');

    if (_mobileNumber == null) {
      _mobileNumber = await UserSession.getPhoneNumber();
    }

    if (_mobileNumber == null) {
      _errorMessage = 'Impossible de récupérer le numéro mobile';
      notifyListeners();
      return false;
    }

    try {
      // Sauvegarder la session
      await TopUpSession.saveSession(
        mobileNumber: _mobileNumber!,
        fixedNumber: fixedNumber,
      );

      _fixedNumber = fixedNumber;
      _hasActiveSession = true;
      _errorMessage = null;

      debugPrint('TopUpProvider: Session démarrée avec succès');

      // Charger les soldes
      await loadBalances();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('TopUpProvider: Erreur démarrage session - $e');
      _errorMessage = 'Erreur lors du démarrage de la session';
      notifyListeners();
      return false;
    }
  }

  /// Charge les soldes du numéro fixe
  Future<void> loadBalances({bool forceRefresh = false}) async {
    if (_mobileNumber == null || _fixedNumber == null) {
      debugPrint('TopUpProvider: Impossible de charger - mobile=$_mobileNumber, fixed=$_fixedNumber');
      return;
    }

    // Utiliser le cache si valide et pas de force refresh
    if (!forceRefresh && hasCachedData) {
      debugPrint('TopUpProvider: Utilisation du cache');
      return;
    }

    debugPrint('TopUpProvider: Chargement des soldes...');

    _isLoading = true;
    _errorMessage = null;
    _isNumberSuspended = false;
    notifyListeners();

    try {
      // Récupérer le statut et les soldes en parallèle
      final results = await Future.wait([
        TopUpApi.instance.getStatusForRecharge(isdn: _fixedNumber!),
        TopUpApi.instance.getBalances(
          msisdn: _mobileNumber!,
          isdn: _fixedNumber!,
          useCache: false,
        ),
      ]);

      final statusResponse = results[0] as Map<String, dynamic>;
      final balanceResponse = results[1] as TopUpBalanceResponse;

      // Traiter le statut
      _processNumberStatus(statusResponse);

      _balanceResponse = balanceResponse;
      _lastBalanceLoadTime = DateTime.now();
      _isLoading = false;
      _errorMessage = null;

      debugPrint('TopUpProvider: Soldes chargés avec succès');
      notifyListeners();
    } catch (e) {
      debugPrint('TopUpProvider: Erreur chargement - $e');

      _isLoading = false;
      if (e is TopUpException) {
        _errorMessage = e.userFriendlyMessage;
      } else {
        _errorMessage = 'Une erreur inattendue est survenue';
      }

      notifyListeners();
    }
  }

  /// Rafraîchit les soldes (force refresh)
  Future<void> refreshBalances() async {
    debugPrint('TopUpProvider: Rafraîchissement forcé des soldes');
    await loadBalances(forceRefresh: true);
  }

  /// Traite le statut du numéro (suspendu ou non)
  void _processNumberStatus(Map<String, dynamic> statusResponse) {
    final success = statusResponse['success'] ?? false;
    final returnCode = statusResponse['return_code'] ?? '';
    final description = statusResponse['description'] ?? '';
    final status = statusResponse['status'];

    debugPrint('TopUpProvider: Traitement statut - success=$success, return_code=$returnCode');

    if (status != null) {
      final eligible = status['eligible'] ?? false;
      final statusText = status['status_text'] ?? 'Statut inconnu';
      final rawDescription = status['raw_description'] ?? description;

      debugPrint('TopUpProvider: Statut détaillé - eligible=$eligible, status=$statusText');
      debugPrint('TopUpProvider: Description - $rawDescription');

      _numberStatus = statusResponse;
      _isNumberSuspended = !eligible;
    }
  }

  /// Termine la session TopUp
  Future<void> endSession() async {
    debugPrint('TopUpProvider: Fin de session');

    await TopUpSession.clearSession();

    _fixedNumber = null;
    _hasActiveSession = false;
    _balanceResponse = null;
    _numberStatus = null;
    _isNumberSuspended = false;
    _errorMessage = null;
    _lastBalanceLoadTime = null;

    notifyListeners();
  }

  /// Réinitialise le provider
  void reset() {
    debugPrint('TopUpProvider: Reset complet');

    _mobileNumber = null;
    _fixedNumber = null;
    _hasActiveSession = false;
    _balanceResponse = null;
    _numberStatus = null;
    _isNumberSuspended = false;
    _isLoading = false;
    _errorMessage = null;
    _lastBalanceLoadTime = null;

    notifyListeners();
  }

  /// Efface le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Invalide le cache
  void invalidateCache() {
    _lastBalanceLoadTime = null;
    debugPrint('TopUpProvider: Cache invalidé');
  }

  /// Getters utilitaires pour les balances
  double get fixedBalance => _balanceResponse?.summary.moneyTotal ?? 0.0;
  double get voiceBalance => (_balanceResponse?.summary.voiceTotalSeconds ?? 0) / 60.0; // Convertir secondes en minutes
  double get dataBalance => (_balanceResponse?.summary.dataTotalBytes ?? 0) / (1024 * 1024); // Convertir bytes en Mo
  int get smsBalance => 0; // Pas de propriété SMS dans le summary

  String get fixedBalanceFormatted => _balanceResponse?.summary.moneyTotalFormatted ?? '0 DJF';
  String get voiceBalanceFormatted => _balanceResponse?.summary.voiceTotalFormatted ?? '00:00:00';
  String get dataBalanceFormatted => _balanceResponse?.summary.dataTotalFormatted ?? '0 Mo';
  String get smsBalanceFormatted => '0 SMS'; // SMS non disponible

  /// Vérifie si le numéro a un solde suffisant
  bool hasSufficientBalance(double amount, String type) {
    switch (type.toLowerCase()) {
      case 'fixe':
        return fixedBalance >= amount;
      case 'voice':
        return voiceBalance >= amount;
      case 'data':
        return dataBalance >= amount;
      case 'sms':
        return smsBalance >= amount;
      default:
        return false;
    }
  }
}
