// lib/screens/home_screen.dart
import 'package:dtservices/screens/achat_forfait/forfait_recipient_screen.dart';
import 'package:dtservices/screens/agencies/agencies_screen.dart';
import 'package:dtservices/screens/forfaits_actifs/forfaits_actifs_screen.dart';
import 'package:dtservices/screens/login_screen.dart';
import 'package:dtservices/screens/transfer_credit/transfer_input_screen.dart';
import 'package:dtservices/screens/refill/refill_recipient_screen.dart';
import 'package:dtservices/screens/speedtest/speedtest_native_screen.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:provider/provider.dart';
import '../providers/balance_provider.dart';
import '../providers/auth_provider.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
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
  bool _showMainBalance = false;
  bool _showBonusBalance = false;

  String _formattedPhoneNumber = '';
  String _normalPhoneNumber = '';
  bool _isLoadingPhone = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Charger le numéro de téléphone depuis la session
    await _loadPhoneNumber();

    // Charger le solde via le provider
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BalanceProvider>().loadBalance();
      });
    }
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

  @override
  Widget build(BuildContext context) {
    // Initialiser le responsive size
    ResponsiveSize.init(context);

    // Utiliser le BalanceProvider pour obtenir les données
    final balanceProvider = context.watch<BalanceProvider>();

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
                      balance: "${balanceProvider.solde.toStringAsFixed(0)} DJF",
                      showBalance: _showMainBalance,
                      isLoading: balanceProvider.isLoading,
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
                      balance: "${balanceProvider.bonus.toStringAsFixed(2)} DJF",
                      showBalance: _showBonusBalance,
                      isLoading: balanceProvider.isLoading,
                      onToggleVisibility:
                          () => setState(
                            () => _showBonusBalance = !_showBonusBalance,
                          ),
                    ),
                  ),
                ],
              ),

              // Date d'expiration si disponible
              if (!balanceProvider.isLoading)
                Padding(
                  padding: EdgeInsets.only(
                    top: ResponsiveSize.getHeight(AppTheme.spacingS),
                  ),
                  child: Text(
                    "Expire le ${balanceProvider.dateExpiration}",
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
              'DTServices',
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchScreen()),
          ),
        ),
        Row(
          children: [
            // Bouton profil
            IconButton(
              icon: Icon(
                Icons.person,
                color: Colors.white,
                size: ResponsiveSize.getFontSize(22),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
              tooltip: 'Mon Profil',
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
    required bool isLoading,
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
                onTap: isLoading ? null : onToggleVisibility,
                child:
                    isLoading
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
    // Obtenir le provider pour accéder au solde
    final balanceProvider = context.read<BalanceProvider>();

    final actions = [
      {
        'icon': Icons.local_mall_sharp,
        'label': 'Achat de\nforfait',
        'onTap': () => Navigator.push(
              context,
              CustomRouteTransitions.slideRightRoute(
                page: ForfaitRecipientScreen(
                  phoneNumber: _normalPhoneNumber,
                ),
              ),
            ),
      },
      {
        'icon': Icons.add_circle,
        'label': "Recharge\nde crédit",
        'onTap': () => Navigator.push(
              context,
              CustomRouteTransitions.slideRightRoute(
                page: RefillRecipientScreen(
                  phoneNumber: _normalPhoneNumber,
                ),
              ),
            ),
      },
      {
        'icon': Icons.timer,
        'label': 'Mes\nforfaits',
        'onTap': () => Navigator.push(
              context,
              CustomRouteTransitions.slideRightRoute(
                page: ForfaitsActifsScreen(),
              ),
            ),
      },
      {
        'icon': Icons.send,
        'label': 'Transfert\nde crédit',
        'onTap': () => Navigator.push(
              context,
              CustomRouteTransitions.slideRightRoute(
                page: TransferInputScreen(
                  phoneNumber: _normalPhoneNumber,
                ),
              ),
            ),
      },
      {
        'icon': Icons.location_on,
        'label': 'Nos\nagences',
        'onTap': () => Navigator.push(
              context,
              CustomRouteTransitions.slideRightRoute(
                page: const AgenciesScreen(),
              ),
            ),
      },
      {
        'icon': Icons.speed,
        'label': 'Speed\nTest',
        'onTap': () => Navigator.push(
              context,
              CustomRouteTransitions.slideRightRoute(
                page: const SpeedtestNativeScreen(),
              ),
            ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: ResponsiveSize.getWidth(AppTheme.spacingS),
        mainAxisSpacing: ResponsiveSize.getHeight(AppTheme.spacingM),
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionButton(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          onTap: action['onTap'] as VoidCallback,
        );
      },
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                // Fermer la boîte de dialogue immédiatement
                Navigator.of(dialogContext).pop();
                // Appeler la méthode de déconnexion
                _performLogout();
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

  Future<void> _performLogout() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Récupérer les providers
      final authProvider = context.read<AuthProvider>();
      final balanceProvider = context.read<BalanceProvider>();

      // Effectuer la déconnexion complète (API + local)
      final success = await authProvider.logout();

      // Réinitialiser le cache de balance
      if (success) {
        balanceProvider.reset();
        debugPrint('HomeScreen: Cache de balance réinitialisé après déconnexion');
      }

      // Fermer l'indicateur de chargement si le widget est encore monté
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Rediriger vers l'écran de connexion
      if (mounted && success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // En cas d'erreur, fermer le dialogue et afficher un message
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
        );
      }
    }
  }
}
