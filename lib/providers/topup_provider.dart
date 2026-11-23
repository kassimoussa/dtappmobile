// lib/providers/topup_provider.dart
import 'package:flutter/foundation.dart';
import '../models/topup_balance.dart';
import '../services/fixed_line_pin_service.dart';
import '../services/topup_api_service.dart';
import '../services/topup_session.dart';
import '../services/user_session.dart';
import '../exceptions/topup_exception.dart';

/// Provider pour gérer l'état de la session TopUp (recharge fixe)
class TopUpProvider extends ChangeNotifier {
  // État de la session
  String? _mobileNumber;
  String? _fixedNumber;

  /// Dernière ligne utilisée, pour préremplir le champ. Ce n'est PAS une
  /// session : seul le PIN, saisi dans cette exécution de l'app, en ouvre une.
  String? _savedFixedNumber;

  /// Vrai quand la ligne est ouverte : PIN vérifié dans cette session de l'app,
  /// ou vérifié récemment et restauré depuis le disque (voir [TopUpSession]).
  bool _hasActiveSession = false;

  /// Jeton de la session de l'app, tel que transmis par [bindSession], et jeton
  /// pour lequel la ligne a été ouverte. Dès qu'ils diffèrent (déconnexion,
  /// expiration, autre compte), la ligne se referme en mémoire ; elle se rouvre
  /// à l'écran suivant si sa vérification sur disque est encore valable.
  String? _boundToken;
  String? _verifiedToken;

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
  String? get savedFixedNumber => _savedFixedNumber;
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

  /// Rattache le provider à la session de l'app (jeton de [AuthProvider]).
  ///
  /// La ligne ouverte en mémoire ne vaut que pour la session de l'app où elle l'a
  /// été : à la déconnexion, à l'expiration ou au changement de compte, le jeton
  /// change, soldes et état sont oubliés, et [initialize] décide de la rouvrir.
  void bindSession(String? token) {
    if (token == _boundToken) return;
    _boundToken = token;
    if (_hasActiveSession && token != _verifiedToken) {
      debugPrint('TopUpProvider: session de l\'app terminée, PIN à ressaisir');
      _dropVerification();
      // Appelé pendant la construction des providers : on notifie après.
      Future.microtask(() {
        if (hasListeners) notifyListeners();
      });
    }
  }

  /// Oublie la vérification et tout ce qu'elle a chargé (soldes, statut).
  /// Garde [_savedFixedNumber] : c'est un simple préremplissage.
  void _dropVerification() {
    _fixedNumber = null;
    _hasActiveSession = false;
    _verifiedToken = null;
    _balanceResponse = null;
    _numberStatus = null;
    _isNumberSuspended = false;
    _isLoading = false;
    _errorMessage = null;
    _lastBalanceLoadTime = null;
  }

  /// Rouvre la ligne mémorisée si son PIN a été vérifié, pour ce compte mobile,
  /// il y a moins de [TopUpSession.verificationValidity]. Sinon le PIN est
  /// redemandé. Sans numéro mobile (session de l'app terminée), on ne touche à
  /// rien : ce n'est pas la vérification qui est en cause.
  Future<bool> _restoreVerifiedLine() async {
    final mobile = _mobileNumber;
    final fixed = await TopUpSession.getFixedNumber();
    if (mobile == null || fixed == null || fixed.isEmpty) return false;

    if (!await TopUpSession.isLineVerifiedFor(mobile)) {
      // Expirée, ou jamais vérifiée (session d'une ancienne version de l'app).
      await TopUpSession.clearVerification();
      return false;
    }

    _fixedNumber = fixed;
    _hasActiveSession = true;
    _verifiedToken = _boundToken;
    debugPrint('TopUpProvider: ligne vérifiée récemment, rouverte sans PIN');
    return true;
  }

  /// Initialise le provider : numéro mobile, dernière ligne utilisée, et
  /// réouverture de la ligne si son PIN a été vérifié récemment.
  Future<void> initialize() async {
    debugPrint('TopUpProvider: Initialisation...');

    _mobileNumber = await UserSession.getPhoneNumber();

    if (_hasActiveSession) {
      // Déjà vérifiée dans cette session de l'app (retour sur l'écran).
      if (_fixedNumber != null && _mobileNumber != null) {
        await loadBalances();
      }
    } else {
      _savedFixedNumber = await TopUpSession.getFixedNumber();
      if (await _restoreVerifiedLine()) {
        await loadBalances();
      } else {
        debugPrint('TopUpProvider: PIN requis pour ouvrir la ligne');
      }
    }

    notifyListeners();
  }

  /// Ouvre « Ma ligne » : vérifie le couple (numéro fixe, PIN) côté serveur,
  /// puis charge les soldes. Le PIN n'est ni conservé ni journalisé.
  Future<FixedLinePinResult> signIn({
    required String fixedNumber,
    required String pin,
  }) async {
    debugPrint('TopUpProvider: Vérification du PIN pour $fixedNumber');

    _mobileNumber ??= await UserSession.getPhoneNumber();

    if (_mobileNumber == null) {
      // Pas de numéro mobile : rien à vérifier, mais on le dit à l'écran.
      return const FixedLinePinResult(FixedLinePinStatus.unavailable);
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await FixedLinePinService.verify(cli: fixedNumber, pin: pin);

    if (!result.isVerified) {
      _isLoading = false;
      notifyListeners();
      return result;
    }

    try {
      await TopUpSession.saveSession(
        mobileNumber: _mobileNumber!,
        fixedNumber: fixedNumber,
      );
      await TopUpSession.markVerified();
    } catch (e) {
      // Sans mémoire sur l'appareil, l'accès reste ouvert pour cette session.
      debugPrint('TopUpProvider: vérification non mémorisée - $e');
    }

    _fixedNumber = fixedNumber;
    _savedFixedNumber = fixedNumber;
    _hasActiveSession = true;
    _verifiedToken = _boundToken;
    _errorMessage = null;

    // Charger les soldes (gère _isLoading et ses propres erreurs)
    await loadBalances(forceRefresh: true);

    notifyListeners();
    return result;
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

  /// Termine la session TopUp (déconnexion volontaire de la ligne) : le
  /// numéro n'est plus mémorisé non plus.
  Future<void> endSession() async {
    debugPrint('TopUpProvider: Fin de session');

    await TopUpSession.clearSession();

    _dropVerification();
    _savedFixedNumber = null;

    notifyListeners();
  }

  /// Réinitialise le provider
  void reset() {
    debugPrint('TopUpProvider: Reset complet');

    _mobileNumber = null;
    _savedFixedNumber = null;
    _dropVerification();

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

  /// Vérifie si l'abonné fixe a des données illimitées actives
  /// Dans ce cas, l'achat de packages données supplémentaires n'est pas proposé
  bool get hasUnlimitedData {
    if (_balanceResponse == null) return false;
    return _balanceResponse!.balances.any(
      (balance) => balance.isDataType && balance.isUnlimited,
    );
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
