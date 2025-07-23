// lib/screens/topup/topup_home_screen.dart
import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../models/topup_balance.dart';
import '../../services/topup_api_service.dart';
import '../../services/user_session.dart';
import '../../services/topup_session.dart';
import '../../services/balance_service.dart';
import '../../exceptions/topup_exception.dart';
import '../../routes/custom_route_transitions.dart';
import 'topup_package_screen.dart';
import 'topup_subscription_screen.dart'; 

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
      
      setState(() {
        _userMobile = phoneNumber;
        _hasActiveSession = true;
        _currentFixedNumber = sessionData['fixed'];
      });
      
      // Charger automatiquement les soldes
      if (_currentFixedNumber != null && _userMobile != null) {
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
    if (_userMobile == null || _currentFixedNumber == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await TopUpApi.instance.getBalances(
        msisdn: _userMobile!,
        isdn: _currentFixedNumber!,
        useCache: true,
      );

      setState(() {
        _balanceResponse = response;
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
        title: const Text('Déconnexion TopUp'),
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
                  'Veuillez entrer votre numéro de ligne fixe pour consulter ses soldes TopUp',
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
                        'Soldes Fix',
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

    return Padding(
      padding: EdgeInsets.only(
        top: ResponsiveSize.getHeight(AppTheme.spacingS),
        left: ResponsiveSize.getWidth(AppTheme.spacingM),
        right: ResponsiveSize.getWidth(AppTheme.spacingM),
      ),
      child: Text(
        "Expire le ${dataBalance.expireDateFormatted}",
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: ResponsiveSize.getFontSize(12),
        ),
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
            'Actions TopUp',
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
                },
              ),
              _buildActionButton(
                icon: Icons.shopping_cart,
                label: 'Acheter\npackages',
                onTap: () {
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
                },
              ),
              _buildActionButton(
                icon: Icons.swap_horiz,
                label: 'Transfert\nvers Fixe',
                onTap: () {
                  // TODO: Implémenter transfert vers fixe
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transfert vers fixe - À implémenter')),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.history,
                label: 'Historique\nTopUp',
                onTap: () {
                  // TODO: Implémenter historique TopUp
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Historique TopUp - À implémenter')),
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