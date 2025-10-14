// lib/screens/topup/topup_home_screen.dart
import 'package:flutter/material.dart';

import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../models/topup_balance.dart';
import '../../../services/topup_api_service.dart';
import '../../../services/user_session.dart';
import '../../../services/topup_session.dart';
import '../../../services/balance_service.dart';
import '../../../exceptions/topup_exception.dart';
import '../../../routes/custom_route_transitions.dart';
import '../packages/topup_package_screen.dart';
import '../subscription/topup_subscription_screen.dart';
import '../recharge/topup_recharge_screen.dart'; 

class TopUpHomeScreen extends StatefulWidget {
  const TopUpHomeScreen({super.key});

  @override
  State<TopUpHomeScreen> createState() => _TopUpHomeScreenState();
}

class _TopUpHomeScreenState extends State<TopUpHomeScreen> {
  final TextEditingController _fixedNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  TopUpBalanceResponse? _balanceResponse;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _numberStatus;
  bool _isNumberSuspended = false;
  String? _userMobile;
  String? _currentFixedNumber;
  bool _hasActiveSession = false;
  
  // Données du solde mobile depuis BalanceService (pour les achats seulement)
  double _mobileSolde = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fixedNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // Charger le numéro mobile de l'utilisateur
    final phoneNumber = await UserSession.getPhoneNumber();
    
    // Charger le solde mobile depuis BalanceService
    await _loadMobileBalance();
    
    // Vérifier s'il y a une session TopUp active
    final hasSession = await TopUpSession.hasActiveSession();
    
    if (hasSession) {
      // Récupérer les données de session
      final sessionData = await TopUpSession.getSessionData();
      
      debugPrint('TopUp Home - Données session: ${sessionData['fixed']}');
      
      setState(() {
        _userMobile = phoneNumber;
        _hasActiveSession = true;
        _currentFixedNumber = sessionData['fixed'];
      });
      
      // Charger automatiquement les soldes
      if (_currentFixedNumber != null && _userMobile != null) {
        debugPrint('TopUp Home - Chargement soldes automatique pour: $_userMobile -> $_currentFixedNumber');
        await _loadBalancesFromSession();
      }
    } else {
      setState(() {
        _userMobile = phoneNumber;
        _hasActiveSession = false;
      });
    }
  }

  Future<void> _loadBalancesFromSession() async {
    if (_userMobile == null || _currentFixedNumber == null) {
      debugPrint('TopUp Home - Impossible de charger les soldes: mobile=$_userMobile, fixed=$_currentFixedNumber');
      return;
    }

    debugPrint('TopUp Home - Début chargement parallèle statut/soldes: $_userMobile -> $_currentFixedNumber');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isNumberSuspended = false;
    });

    try {
      // Récupérer le statut et les soldes en parallèle
      final results = await Future.wait([
        TopUpApi.instance.getStatusForRecharge(isdn: _currentFixedNumber!),
        TopUpApi.instance.getBalances(
          msisdn: _userMobile!,
          isdn: _currentFixedNumber!,
          useCache: false,
        ),
      ]);

      final statusResponse = results[0] as Map<String, dynamic>;
      final balanceResponse = results[1] as TopUpBalanceResponse;

      // Traiter le statut
      _processNumberStatus(statusResponse);

      setState(() {
        _balanceResponse = balanceResponse;
        _isLoading = false;
      });

      // Ne plus afficher automatiquement le dialogue - il apparaîtra au clic sur les boutons

    } catch (e) {
      debugPrint('TopUp Home - Erreur chargement: $e');
      
      setState(() {
        _isLoading = false;
        if (e is TopUpException) {
          _errorMessage = e.userFriendlyMessage;
          debugPrint('TopUp Home - Erreur type: ${e.returnCode} - ${e.userFriendlyMessage}');
        } else {
          _errorMessage = 'Une erreur inattendue est survenue';
        }
      });
    }
  }

  void _processNumberStatus(Map<String, dynamic> statusResponse) {
    final success = statusResponse['success'] ?? false;
    final returnCode = statusResponse['return_code'] ?? '';
    final description = statusResponse['description'] ?? '';
    final status = statusResponse['status'];
    
    debugPrint('TopUp Home - Traitement statut: success=$success, return_code=$returnCode');
    
    if (status != null) {
      final eligible = status['eligible'] ?? false;
      final statusText = status['status_text'] ?? 'Statut inconnu';
      final reason = status['reason'] ?? '';
      final rawDescription = status['raw_description'] ?? description;
      
      debugPrint('TopUp Home - Statut détaillé: eligible=$eligible, status=$statusText');
      debugPrint('TopUp Home - Description: $rawDescription');
      
      _numberStatus = statusResponse;
      _isNumberSuspended = !eligible;
    }
  }

  void _showSuspendedDialog() {
    if (_numberStatus == null) return;
    
    final status = _numberStatus!['status'];
    final description = _numberStatus!['description'] ?? '';
    final rawDescription = status?['raw_description'] ?? description;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              SizedBox(width: ResponsiveSize.getWidth(8)),
              Text(
                'Numéro suspendu',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rawDescription.isNotEmpty 
                    ? rawDescription 
                    : 'Ce numéro est temporairement suspendu.',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(16)),
              Container(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(12)),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(8)),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: ResponsiveSize.getWidth(8)),
                    Expanded(
                      child: Text(
                        'Vous pouvez consulter les soldes mais les achats sont temporairement indisponibles.',
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(14),
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Compris',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkNumberStatusFirst() async {
    if (_currentFixedNumber == null) return false;

    try {
      debugPrint('TopUp Home - Vérification statut du numéro: $_currentFixedNumber');
      
      final statusResponse = await TopUpApi.instance.getStatusForRecharge(
        isdn: _currentFixedNumber!,
      );
      
      final success = statusResponse['success'] ?? false;
      final returnCode = statusResponse['return_code'] ?? '';
      final description = statusResponse['description'] ?? '';
      final status = statusResponse['status'];
      
      if (status != null) {
        final eligible = status['eligible'] ?? false;
        final statusText = status['status_text'] ?? 'Statut inconnu';
        final reason = status['reason'] ?? '';
        final rawDescription = status['raw_description'] ?? description;
        
        debugPrint('TopUp Home - Statut API: success=$success, return_code=$returnCode');
        debugPrint('TopUp Home - Statut numéro: eligible=$eligible, status=$statusText, reason=$reason');
        debugPrint('TopUp Home - Description: $rawDescription');
        
        if (!eligible) {
          // Numéro non éligible - afficher l'erreur et arrêter le chargement
          setState(() {
            _isLoading = false;
            _errorMessage = rawDescription.isNotEmpty 
                ? rawDescription 
                : '$statusText${reason.isNotEmpty ? ' - $reason' : ''}';
          });
          return false;
        }
        
        // Numéro éligible, continuer avec le chargement des soldes
        return true;
      }
      
      // Pas de statut dans la réponse, essayer quand même
      return true;
    } catch (e) {
      debugPrint('TopUp Home - Erreur vérification statut: $e');
      // En cas d'erreur de vérification, essayer quand même de charger les soldes
      return true;
    }
  }

  Future<void> _checkNumberStatus() async {
    if (_currentFixedNumber == null) return;

    try {
      debugPrint('TopUp Home - Vérification statut du numéro: $_currentFixedNumber');
      
      final statusResponse = await TopUpApi.instance.getStatusForRecharge(
        isdn: _currentFixedNumber!,
      );
      
      final success = statusResponse['success'] ?? false;
      final returnCode = statusResponse['return_code'] ?? '';
      final description = statusResponse['description'] ?? '';
      final status = statusResponse['status'];
      
      if (status != null) {
        final eligible = status['eligible'] ?? false;
        final statusText = status['status_text'] ?? 'Statut inconnu';
        final reason = status['reason'] ?? '';
        final rawDescription = status['raw_description'] ?? description;
        
        debugPrint('TopUp Home - Statut API: success=$success, return_code=$returnCode');
        debugPrint('TopUp Home - Statut numéro: eligible=$eligible, status=$statusText, reason=$reason');
        debugPrint('TopUp Home - Description: $rawDescription');
        
        // Mettre à jour le message d'erreur avec plus de détails
        setState(() {
          if (eligible) {
            _errorMessage = 'Le numéro est éligible mais les soldes sont indisponibles. Réessayez plus tard.';
          } else {
            // Utiliser la description brute pour plus de précision
            _errorMessage = rawDescription.isNotEmpty 
                ? rawDescription 
                : '$statusText${reason.isNotEmpty ? ' - $reason' : ''}';
          }
        });
      }
    } catch (e) {
      debugPrint('TopUp Home - Erreur vérification statut: $e');
      // Ne pas changer le message d'erreur existant si la vérification de statut échoue
    }
  }

  Future<void> _loadMobileBalance() async {
    try {
      // Utiliser le service pour charger le solde mobile (comme dans HomeScreen)
      final data = await BalanceService.getCurrentBalance();

      if (mounted && data['solde'] != null) {
        // La valeur est stockée en centimes, donc diviser par 100 pour obtenir en DJF
        _mobileSolde = double.tryParse(data['solde']) != null
            ? double.parse(data['solde']) / 100
            : 0.0;
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du solde mobile pour TopUp: $e');
      _mobileSolde = 0.0;
    }
  }

  Future<void> _consultBalances() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userMobile == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _balanceResponse = null;
    });

    try {
      final response = await TopUpApi.instance.getBalances(
        msisdn: _userMobile!,
        isdn: _fixedNumberController.text.trim(),
        useCache: true,
      );

      // Sauvegarder la session TopUp
      await TopUpSession.saveSession(
        mobileNumber: _userMobile!,
        fixedNumber: _fixedNumberController.text.trim(),
      );

      setState(() {
        _balanceResponse = response;
        _currentFixedNumber = _fixedNumberController.text.trim();
        _hasActiveSession = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e is TopUpException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = 'Une erreur inattendue est survenue';
        }
      });
    }
  }

  String? _validateFixedNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer un numéro de téléphone fixe';
    }
    
    if (!TopUpValidator.isValidFixed(value.trim())) {
      return 'Le numéro doit commencer par 21 ou 25321 et contenir 8 ou 11 chiffres';
    }
    
    return null;
  }

  Future<void> _disconnectTopUp() async {
    // Afficher confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: Text('Voulez-vous vous déconnecter de la ligne $_currentFixedNumber ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Supprimer la session
      await TopUpSession.clearSession();
      
      // Réinitialiser l'état
      setState(() {
        _hasActiveSession = false;
        _currentFixedNumber = null;
        _balanceResponse = null;
        _errorMessage = null;
        _fixedNumberController.clear();
      });

      // Afficher confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Déconnexion TopUp réussie'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          'Ma ligne',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.dtBlue,
        elevation: 0,
        actions: [
          if (_hasActiveSession) ...[
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _disconnectTopUp,
              tooltip: 'Déconnecter',
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Afficher les inputs seulement s'il n'y a pas de session active
              if (!_hasActiveSession) ...[ 
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                _buildInputForm(),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              ],
              
              // États de chargement et d'erreur
              if (_isLoading) _buildLoadingState(),
              if (_errorMessage != null) _buildErrorState(),
              
              // Résultats (toujours affichés s'ils existent)
              if (_balanceResponse != null) ...[
                _buildBalanceSummary(),
                _buildExpirationInfo(),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Padding(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        ),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consulter votre ligne fixe',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dtBlue,
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
                Text(
                  'Veuillez entrer votre numéro de ligne fixe pour consulter ses soldes',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(14),
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                TextFormField(
                  controller: _fixedNumberController,
                  keyboardType: TextInputType.phone,
                  validator: _validateFixedNumber,
                  decoration: InputDecoration(
                    labelText: 'Numéro de ligne fixe',
                    hintText: 'Ex: 21XXXXXX',
                    prefixIcon: Icon(Icons.phone, color: AppTheme.dtBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                      borderSide: BorderSide(color: AppTheme.dtBlue, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _consultBalances,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dtBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                      ),
                    ),
                    child: Text(
                      _isLoading ? 'Consultation...' : 'Consulter',
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlue),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
          Text(
            'Consultation des soldes en cours...',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveSize.getFontSize(48),
              color: Colors.red,
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            ElevatedButton.icon(
              onPressed: _consultBalances,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: AppTheme.dtYellow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSummary() {
    final response = _balanceResponse!;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.dtBlue,
                  size: ResponsiveSize.getFontSize(24),
                ),
                SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Soldes Fixes',
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(18),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dtBlue,
                        ),
                      ),
                      Text(
                        'Ligne: $_currentFixedNumber',
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(12),
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ), 
              ],
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Argent',
                  response.summary.moneyTotalFormatted,
                  Icons.monetization_on,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Données',
                  response.summary.dataTotalFormatted,
                  Icons.data_usage,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Voix',
                  response.summary.voiceTotalFormatted,
                  Icons.phone,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: ResponsiveSize.getFontSize(24),
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(14),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(12),
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildExpirationInfo() {
    final response = _balanceResponse!;
    
    // Chercher les données prépayées (type data)
    TopUpBalance? dataBalance;
    try {
      dataBalance = response.balances.firstWhere(
        (balance) => balance.isDataType,
      );
    } catch (e) {
      // Si aucune donnée trouvée, prendre le premier balance disponible
      dataBalance = response.balances.isNotEmpty ? response.balances.first : null;
    }

    if (dataBalance == null || dataBalance.expireDateFormatted.isEmpty) {
      return const SizedBox.shrink();
    }

    // Vérifier si la date est expirée
    final now = DateTime.now();
    final isExpired = dataBalance.isExpired;
    final isExpiringSoon = dataBalance.isExpiringSoon;
    
    Color textColor = Colors.grey[600]!;
    Color? backgroundColor;
    
    if (isExpired) {
      textColor = Colors.red[700]!;
      backgroundColor = Colors.red[50];
    } else if (isExpiringSoon) {
      textColor = Colors.orange[700]!;
      backgroundColor = Colors.orange[50];
    }

    return Container(
      margin: EdgeInsets.only(
        top: ResponsiveSize.getHeight(AppTheme.spacingS),
        left: ResponsiveSize.getWidth(AppTheme.spacingM),
        right: ResponsiveSize.getWidth(AppTheme.spacingM),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(8),
        vertical: ResponsiveSize.getHeight(4),
      ),
      decoration: backgroundColor != null ? BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(4)),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isExpired) ...[
            Icon(Icons.warning_amber, color: textColor, size: 14),
            SizedBox(width: ResponsiveSize.getWidth(4)),
          ] else if (isExpiringSoon) ...[
            Icon(Icons.schedule, color: textColor, size: 14),
            SizedBox(width: ResponsiveSize.getWidth(4)),
          ],
          Text(
            isExpired 
                ? "Expiré le ${dataBalance.expireDateFormatted}"
                : "Expire le ${dataBalance.expireDateFormatted}",
            style: TextStyle(
              color: textColor,
              fontSize: ResponsiveSize.getFontSize(12),
              fontWeight: isExpired || isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.getWidth(AppTheme.spacingM)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(18),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlue,
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                icon: Icons.subscriptions,
                label: 'Acheter une\nsouscription',
                onTap: () {
                  if (_isNumberSuspended) {
                    _showSuspendedDialog();
                  } else {
                    Navigator.push(
                      context,
                      CustomRouteTransitions.slideRightRoute(
                        page: TopUpSubscriptionScreen(
                          fixedNumber: _currentFixedNumber!,
                          mobileNumber: _userMobile!,
                          soldeActuel: _mobileSolde, // Utilise le solde mobile depuis BalanceService
                        ),
                      ),
                    );
                  }
                },
              ),
              _buildActionButton(
                icon: Icons.shopping_cart,
                label: 'Acheter\npackages',
                onTap: () {
                  if (_isNumberSuspended) {
                    _showSuspendedDialog();
                  } else {
                    Navigator.push(
                      context,
                      CustomRouteTransitions.slideRightRoute(
                        page: TopUpPackageScreen(
                          fixedNumber: _currentFixedNumber!,
                          mobileNumber: _userMobile!,
                          soldeActuel: _mobileSolde, // Utilise le solde mobile depuis BalanceService
                        ),
                      ),
                    );
                  }
                },
              ),
              _buildActionButton(
                icon: Icons.account_balance_wallet,
                label: 'Recharger\ncompte',
                onTap: () {
                  if (_isNumberSuspended) {
                    _showSuspendedDialog();
                  } else {
                    Navigator.push(
                      context,
                      CustomRouteTransitions.slideRightRoute(
                        page: TopUpRechargeScreen(
                          fixedNumber: _currentFixedNumber!,
                          mobileNumber: _userMobile!,
                          soldeActuel: _mobileSolde,
                        ),
                      ),
                    );
                  }
                },
              ),
              _buildActionButton(
                icon: Icons.history,
                label: 'Historique\nFixe',
                onTap: () {
                  // TODO: Implémenter historique TopUp
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Historique Fixe - À implémenter')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.dtBlue,
            radius: ResponsiveSize.getWidth(22),
            child: Icon(
              icon,
              color: AppTheme.dtYellow,
              size: ResponsiveSize.getFontSize(20),
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(12),
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}