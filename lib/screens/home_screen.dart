// lib/screens/home_screen.dart 
import 'package:dtapp3/screens/achat_forfait/forfait_recipient_screen.dart';
import 'package:dtapp3/screens/forfaits_actifs/forfaits_actifs_screen.dart';
import 'package:dtapp3/screens/login_screen.dart';
import 'package:dtapp3/screens/transfer_credit/transfer_input_screen.dart';
import 'package:dtapp3/screens/refill/refill_recipient_screen.dart';
import 'package:dtapp3/services/balance_service.dart';
import 'package:dtapp3/services/user_session.dart';
import 'package:dtapp3/services/logout_service.dart';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../extensions/color_extensions.dart';
import '../routes/custom_route_transitions.dart';

class HomeScreen extends StatefulWidget {
  // final String phoneNumber;

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final bool _isLoading = false;
  // Données statiques au lieu de l'USSD
  double _solde = 0.0;
  String _dateExpiration = 'N/A';
  double _bonus = 0.0;
  final bool _dataLoaded = true; // Toujours true maintenant
  bool _showMainBalance = false;
  bool _showBonusBalance = false;

  String _formattedPhoneNumber = '';
  String _normalPhoneNumber = '';
  bool _isLoadingPhone = true;
  bool _isLoadingBalance = true;
  Map<String, dynamic>? _balanceData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Charger le numéro de téléphone depuis la session
    await _loadPhoneNumber();

    // Charger le solde
    await _loadBalance();
  }

  Future<void> _loadPhoneNumber() async {
    setState(() {
      _isLoadingPhone = true;
    });

    try {
      final phoneNumber = await UserSession.getPhoneNumber();

      if (phoneNumber == null || phoneNumber.isEmpty) {
        // Rediriger vers l'écran de connexion si aucun numéro n'est trouvé
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          CustomRouteTransitions.fadeScaleRoute(page: const LoginScreen()),
          (route) => false,
        );
        return;
      }
      _normalPhoneNumber = phoneNumber;
      // Formatter le numéro pour l'affichage
      _formatPhoneNumber(phoneNumber);
    } catch (e) {
      debugPrint('Erreur lors du chargement du numéro: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPhone = false;
        });
      }
    }
  }

  void _formatPhoneNumber(String phoneNumber) {
    // Nettoyer le numéro : enlever tout sauf les chiffres
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Enlever l'indicatif 253 s'il est présent
    if (cleanNumber.startsWith('253')) {
      cleanNumber = cleanNumber.substring(3);
    }

    // S'assurer qu'on a bien 8 chiffres pour le numéro local
    if (cleanNumber.length == 8) {
      // Diviser en groupes de 2 chiffres : XX XX XX XX
      final buffer = StringBuffer('+253');
      for (int i = 0; i < cleanNumber.length; i += 2) {
        buffer.write(' ${cleanNumber.substring(i, i + 2)}');
      }
      _formattedPhoneNumber = buffer.toString();
    } else {
      // Fallback : afficher brut si format inattendu
      _formattedPhoneNumber = '+253 $cleanNumber';
    }
  }

  Future<void> _loadBalance() async {
    setState(() {
      _isLoadingBalance = true;
      _errorMessage = null;
    });

    try {
      // Utiliser le service pour charger le solde
      final data = await BalanceService.getCurrentBalance();

      if (mounted) {
        setState(() {
          _balanceData =
              data; // Extraire le solde (convertir depuis la chaîne en double)
          if (data['solde'] != null) {
            // La valeur est stockée en centimes, donc diviser par 100 pour obtenir en DJF
            _solde =
                double.tryParse(data['solde']) != null
                    ? double.parse(data['solde']) / 100
                    : 0.0;
          }

          // Extraire la date d'expiration (date de supervision)
          _dateExpiration = data['date_supervision'] ?? 'N/A';
          
          // Extraire le solde bonus depuis le compte dédié ID 5
          if (data['comptes_dedies'] != null) {
            final comptesDedies = data['comptes_dedies'] as List;
            final compteBonus = comptesDedies.firstWhere(
              (compte) => compte['id'] == 5,
              orElse: () => null,
            );
            if (compteBonus != null) {
              // Convertir la valeur depuis centimes vers DJF (diviser par 100)
              _bonus = double.tryParse(compteBonus['valeur']?.toString() ?? '0') != null
                  ? double.parse(compteBonus['valeur'].toString()) / 100
                  : 0.0;
            }
          }
          
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du solde: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingBalance = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialiser le responsive size
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section de bienvenue
              _buildWelcomeSection(),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              // Cartes des comptes
              Row(
                children: [
                  Expanded(
                    child: _buildAccountCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Main Account',
                      balance: "${_solde.toStringAsFixed(0)} DJF",
                      showBalance: _showMainBalance,
                      onToggleVisibility:
                          () => setState(
                            () => _showMainBalance = !_showMainBalance,
                          ),
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
                  Expanded(
                    child: _buildAccountCard(
                      icon: Icons.add_card,
                      label: 'Solde Bonus',
                      balance: "${_bonus.toStringAsFixed(2)} DJF",
                      showBalance: _showBonusBalance,
                      onToggleVisibility:
                          () => setState(
                            () => _showBonusBalance = !_showBonusBalance,
                          ),
                    ),
                  ),
                ],
              ),

              // Date d'expiration si disponible
              if (!_isLoadingBalance)
                Padding(
                  padding: EdgeInsets.only(
                    top: ResponsiveSize.getHeight(AppTheme.spacingS),
                  ),
                  child: Text(
                    "Expire le $_dateExpiration",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: ResponsiveSize.getFontSize(12),
                    ),
                  ),
                ),

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

              // Boutons d'actions rapides
              _buildQuickActions(),

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

              // Section historique récent (uniquement sur l'écran d'accueil)
              /* _buildRecentHistorySection(), */
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.dtBlue,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSize.getWidth(AppTheme.spacingS),
              vertical: ResponsiveSize.getHeight(AppTheme.spacingXS),
            ),
            decoration: BoxDecoration(
              color: AppTheme.dtYellow,
              borderRadius: BorderRadius.circular(
                ResponsiveSize.getWidth(AppTheme.radiusS),
              ),
            ),
            child: Text(
              'DTAPP',
              style: TextStyle(
                color: AppTheme.dtBlue,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveSize.getFontSize(14),
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.search,
            color: Colors.white,
            size: ResponsiveSize.getFontSize(22),
          ),
          onPressed: () => _showComingSoonDialog('Recherche'),
        ),
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: ResponsiveSize.getFontSize(22),
              ),
              onPressed: () => _showComingSoonDialog('Notifications'),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: EdgeInsets.all(
                  ResponsiveSize.getWidth(AppTheme.spacingXS),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.dtYellow,
                  borderRadius: BorderRadius.circular(
                    ResponsiveSize.getWidth(10),
                  ),
                ),
                child: Text(
                  '3',
                  style: TextStyle(
                    color: AppTheme.dtBlue,
                    fontSize: ResponsiveSize.getFontSize(10),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Bouton des paramètres original
            IconButton(
              icon: Icon(
                Icons.settings,
                color: Colors.white,
                size: ResponsiveSize.getFontSize(22),
              ),
              onPressed: () => _showComingSoonDialog('Paramètres'),
            ),
            // Bouton de déconnexion
            IconButton(
              icon: Icon(
                Icons.logout,
                color: Colors.white,
                size: ResponsiveSize.getFontSize(22),
              ),
              onPressed: () => _showLogoutDialog(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    final phoneNumber = _formattedPhoneNumber ?? '77 XX XX XX';

    return Text(
      'Bienvenue, $_normalPhoneNumber',
      style: TextStyle(
        fontSize: ResponsiveSize.getFontSize(22),
        fontWeight: FontWeight.bold,
        color: AppTheme.dtBlue,
      ),
    );
  }

  Widget _buildAccountCard({
    required IconData icon,
    required String label,
    required String balance,
    required bool showBalance,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      decoration: BoxDecoration(
        color: AppTheme.dtBlue,
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: ResponsiveSize.getFontSize(20)),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacityValue(0.7),
              fontSize: ResponsiveSize.getFontSize(14),
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
          Row(
            children: [
              Text(
                showBalance ? balance : '******',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveSize.getFontSize(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _isLoading ? null : onToggleVisibility,
                child:
                    _isLoading
                        ? SizedBox(
                          width: ResponsiveSize.getWidth(20),
                          height: ResponsiveSize.getHeight(20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.dtYellow,
                            ),
                          ),
                        )
                        : Icon(
                          showBalance ? Icons.visibility : Icons.visibility_off,
                          color: AppTheme.dtYellow,
                          size: ResponsiveSize.getFontSize(22),
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionButton(
              icon: Icons.local_mall_sharp,
              label: 'Achat de\nforfait',
              onTap:
                  () => Navigator.push(
                    context,
                    CustomRouteTransitions.slideRightRoute(
                      page: ForfaitRecipientScreen(
                        phoneNumber: _normalPhoneNumber,
                        soldeActuel: _solde,
                        onRefreshSolde: _loadBalance,
                      ),
                    ),
                  ),
            ),
            _buildActionButton(
              icon: Icons.add_circle,
              label: "Recharge \nde crédit",
              onTap: () =>  Navigator.push(
                    context,
                    CustomRouteTransitions.slideRightRoute(
                      page: RefillRecipientScreen(
                        phoneNumber: _normalPhoneNumber, 
                      ),
                    ),
                  ),
            ),
            _buildActionButton(
              icon: Icons.timer,
              label: 'Mes\n forfaits',
              onTap:
                  () => Navigator.push(
                    context,
                    CustomRouteTransitions.slideRightRoute(
                      page: ForfaitsActifsScreen(),
                    ),
                  ),
            ),
            _buildActionButton(
              icon: Icons.send,
              label: 'Transfert\nde crédit',
              onTap:
                  () => Navigator.push(
                    context,
                    CustomRouteTransitions.slideRightRoute(
                      page: TransferInputScreen(
                        phoneNumber: _normalPhoneNumber,
                        soldeActuel: _solde,
                        onRefreshSolde: _loadBalance,
                      ),
                    ),
                  ),
            ),
          ],
        ),
        SizedBox(height: 10),
        /* Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionButton(
              icon: Icons.add,
              label: 'Test recharge',
              onTap: () => Navigator.push(
                    context,
                    CustomRouteTransitions.slideRightRoute(
                      page: RefillApiTest()
                    ),
                  ),
            ),

        ],
        ) */
      ],
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

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              feature,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtBlue,
              ),
            ),
            content: Text(
              'Cette fonctionnalité sera bientôt disponible.',
              style: TextStyle(fontSize: ResponsiveSize.getFontSize(16)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: AppTheme.dtBlue,
                    fontSize: ResponsiveSize.getFontSize(16),
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveSize.getWidth(AppTheme.radiusM),
              ),
            ),
          ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                // Fermer d'abord la boîte de dialogue
                Navigator.of(context).pop();
                
                // Afficher un indicateur de chargement
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                // Effectuer la déconnexion complète (API + local)
                final success = await LogoutService.logout();
                
                // Fermer l'indicateur de chargement
                if (mounted) Navigator.of(context).pop();
                
                // Rediriger vers l'écran de connexion
                if (mounted && success) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Déconnecter',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
