// lib/screens/core/home_screen.dart
import 'package:dtservices/screens/achat_forfait/forfait_recipient_screen.dart';
import 'package:dtservices/screens/agencies/agencies_screen.dart';
import 'package:dtservices/screens/forfaits_actifs/forfaits_actifs_screen.dart';
import 'package:dtservices/screens/auth/login_screen.dart';
import 'package:dtservices/screens/transfer_credit/transfer_input_screen.dart';
import 'package:dtservices/screens/refill/refill_recipient_screen.dart';
import 'package:dtservices/screens/speedtest/speedtest_native_screen.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:provider/provider.dart';
import '../../providers/balance_provider.dart';
import '../../providers/auth_provider.dart';
import '../user/profile_screen.dart';
import 'search_screen.dart';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../extensions/color_extensions.dart';
import '../../routes/custom_route_transitions.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/banner_slider.dart';

class HomeScreen extends StatefulWidget {
  // final String phoneNumber;

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showMainBalance = false;
  bool _showBonusBalance = false;

  String _normalPhoneNumber = '';

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
    /* setState(() {
      _isLoadingPhone = true;
    }); */

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
    } catch (e) {
      debugPrint('Erreur lors du chargement du numéro: $e');
    } finally {
      /* if (mounted) {
        setState(() {
          _isLoadingPhone = false;
        });
      } */
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialiser le responsive size
    ResponsiveSize.init(context);

    // Utiliser le BalanceProvider pour obtenir les données
    final balanceProvider = context.watch<BalanceProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(l10n),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section de bienvenue
              _buildWelcomeSection(l10n),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              // Cartes des comptes
              Row(
                children: [
                  Expanded(
                    child: _buildAccountCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: l10n.mainAccount,
                      balance:
                          "${balanceProvider.solde.toStringAsFixed(0)} DJF",
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
                      label: l10n.bonusBalance,
                      balance:
                          "${balanceProvider.bonus.toStringAsFixed(2)} DJF",
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
                    l10n.expiresOn(balanceProvider.dateExpiration),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: ResponsiveSize.getFontSize(12),
                    ),
                  ),
                ),

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

              // Boutons d'actions rapides
              _buildQuickActions(l10n),

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)), 

              // Bannières promotionnelles
              const BannerSlider(),

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),

              // Section historique récent (uniquement sur l'écran d'accueil)
              /* _buildRecentHistorySection(), */
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(AppLocalizations l10n) {
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
              l10n.appTitle,
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
          onPressed:
              () => Navigator.push(
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
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  ),
              tooltip: l10n.myProfile,
            ),
            // Bouton de déconnexion
            IconButton(
              icon: Icon(
                Icons.logout,
                color: Colors.white,
                size: ResponsiveSize.getFontSize(22),
              ),
              onPressed: () => _showLogoutDialog(l10n),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(AppLocalizations l10n) {
    return Text(
      l10n.welcomeMessage(_normalPhoneNumber),
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

  Widget _buildQuickActions(AppLocalizations l10n) {
    // Obtenir le provider pour accéder au solde
    // final balanceProvider = context.read<BalanceProvider>();

    final actions = [
      {
        'icon': Icons.local_mall_sharp,
        'label': l10n.buyPackage,
        'onTap':
            () => Navigator.push(
              context,
              CustomRouteTransitions.slideRightRoute(
                page: ForfaitRecipientScreen(phoneNumber: _normalPhoneNumber),
              ),
            ),
      },
      {
        'icon': Icons.add_circle,
        'label': l10n.creditRefill,
        'onTap':
            () => Navigator.push(
              context,
              CustomRouteTransitions.slideRightRoute(
                page: RefillRecipientScreen(phoneNumber: _normalPhoneNumber),
              ),
            ),
      },
      {
        'icon': Icons.timer,
        'label': l10n.myPackages,
        'onTap':
            () => Navigator.push(
              context,
              CustomRouteTransitions.slideRightRoute(
                page: ForfaitsActifsScreen(),
              ),
            ),
      },
      {
        'icon': Icons.send,
        'label': l10n.creditTransfer,
        'onTap':
            () => Navigator.push(
              context,
              CustomRouteTransitions.slideRightRoute(
                page: TransferInputScreen(phoneNumber: _normalPhoneNumber),
              ),
            ),
      },
      {
        'icon': Icons.location_on,
        'label': l10n.ourAgencies,
        'onTap':
            () => Navigator.push(
              context,
              CustomRouteTransitions.slideRightRoute(
                page: const AgenciesScreen(),
              ),
            ),
      },
      {
        'icon': Icons.speed,
        'label': l10n.speedTest,
        'onTap':
            () => Navigator.push(
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
        childAspectRatio: (ResponsiveSize.screenWidth / 4) / ResponsiveSize.getWidth(110),
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

  void _showLogoutDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.logout),
          content: Text(l10n.logoutConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                // Fermer la boîte de dialogue immédiatement
                Navigator.of(dialogContext).pop();
                // Appeler la méthode de déconnexion
                _performLogout(l10n);
              },
              child: Text(
                l10n.logoutAction,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(AppLocalizations l10n) async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext loadingContext) =>
              const Center(child: CircularProgressIndicator()),
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
        debugPrint(
          'HomeScreen: Cache de balance réinitialisé après déconnexion',
        );
      }

      // Fermer l'indicateur de chargement si le widget est encore monté
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Rediriger vers l'écran de connexion
      if (mounted && success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // En cas d'erreur, fermer le dialogue et afficher un message
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.logoutError}: $e')));
      }
    }
  }
}
